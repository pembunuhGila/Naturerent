import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class EditProfilPage extends StatefulWidget {
  /// Nama & avatarUrl yang sudah ada (dari ProfilPage)
  final String namaAwal;
  final String email;
  final String? avatarUrlAwal;

  const EditProfilPage({
    super.key,
    required this.namaAwal,
    required this.email,
    this.avatarUrlAwal,
  });

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late final TextEditingController _namaCtrl;
  final _client = AuthService.client;
  final _picker = ImagePicker();

  File? _gambarBaru;        // file lokal foto profil
  String? _avatarUrl;       // URL avatar di Supabase
  File? _ktpBaru;           // file lokal foto KTP
  String? _ktpUrl;          // URL KTP di Supabase
  bool _isSaving = false;

  // ──────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.namaAwal);
    _avatarUrl = widget.avatarUrlAwal;
    _loadKtp(); // muat URL KTP dari DB
  }

  Future<void> _loadKtp() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      final data = await _client
          .from('users')
          .select('ktp_url')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;
      setState(() => _ktpUrl = data?['ktp_url'] as String?);
    } catch (_) {}
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  //  AMBIL GAMBAR
  // ──────────────────────────────────────────────────────────
  void _showPilihFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: Text('Ambil dari Kamera',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pilihGambar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: Text('Pilih dari Galeri',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pilihGambar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pilihGambar(ImageSource source) async {
    try {
      // 1. Pick gambar
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;

      // 2. Crop gambar (rasio 1:1 untuk foto profil)
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 80,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Pangkas Foto Profil',
            toolbarColor: AppColors.primaryDark,
            toolbarWidgetColor: Colors.white,
            statusBarColor: AppColors.primaryDark, // ignore: deprecated_member_use
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Pangkas Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped == null || !mounted) return;
      setState(() => _gambarBaru = File(cropped.path));
    } catch (e) {
      _snack('Gagal memilih/memangkas foto: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  UPLOAD & SIMPAN
  // ──────────────────────────────────────────────────────────
  Future<void> _simpan() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      _snack('Nama tidak boleh kosong.');
      return;
    }

    setState(() => _isSaving = true);

    String? newAvatarUrl = _avatarUrl;
    bool namaOk = false;
    bool fotoOk = _gambarBaru == null;

    // ── 1. Update auth metadata (PRIMARY — selalu berhasil jika session aktif)
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': nama}),
      );
      namaOk = true;
    } catch (_) {/* lanjut ke DB update */}

    // ── 2. Simpan nama ke public.users (SECONDARY — mungkin diblokir RLS)
    try {
      await AuthService().perbaruiProfil(namaLengkap: nama);
      namaOk = true;
    } catch (_) {/* abaikan jika DB update gagal, auth sudah tersimpan */}

    if (!namaOk) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorDialog(
        judul: 'Gagal menyimpan nama',
        pesan: 'Tidak dapat terhubung ke server.',
        solusi: 'Periksa koneksi internet dan pastikan kamu sudah login.',
      );
      return;
    }

    // ── 3. Upload foto profil baru (jika ada)
    if (_gambarBaru != null) {
      try {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) throw Exception('Session habis, silakan login ulang.');

        final ext = _gambarBaru!.path.split('.').last.toLowerCase();
        final storagePath = 'avatars/$userId.$ext';
        final bytes = await _gambarBaru!.readAsBytes();

        await _client.storage.from('avatars').uploadBinary(
              storagePath, bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        newAvatarUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
        await AuthService().perbaruiProfil(avatarUrl: newAvatarUrl);
        fotoOk = true;
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        final pesanErr = e.toString().toLowerCase();
        String solusi = 'Coba lagi beberapa saat.';
        if (pesanErr.contains('not found') || pesanErr.contains('bucket')) {
          solusi = '⚠️ Buat bucket "avatars" di Supabase Storage:\n'
              'Dashboard → Storage → New Bucket → nama: avatars → Public ✓';
        } else if (pesanErr.contains('rls') || pesanErr.contains('policy')) {
          solusi = 'Periksa RLS Policy bucket "avatars".\n'
              'Tambahkan policy: Allow INSERT for authenticated users.';
        }
        _showErrorDialog(
          judul: 'Foto gagal disimpan',
          pesan: '✅ Nama berhasil disimpan!\n\n❌ Foto profil gagal:\n${e.toString()}',
          solusi: solusi,
          onClose: () { if (mounted) Navigator.pop(context, namaOk); },
        );
        return;
      }
    } else {
      fotoOk = true;
    }

    // ── 4. Upload foto KTP baru (jika ada)
    if (_ktpBaru != null) {
      try {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) throw Exception('Session habis.');
        final ext = _ktpBaru!.path.split('.').last.toLowerCase();
        final storagePath = 'ktp-docs/$userId.$ext';
        final bytes = await _ktpBaru!.readAsBytes();
        await _client.storage.from('ktp-docs').uploadBinary(
              storagePath, bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        final ktpPublicUrl =
            _client.storage.from('ktp-docs').getPublicUrl(storagePath);
        await AuthService().perbaruiProfil(ktpUrl: ktpPublicUrl);
        setState(() => _ktpUrl = ktpPublicUrl);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        _showErrorDialog(
          judul: 'KTP gagal disimpan',
          pesan: '✅ Profil berhasil disimpan!\n\n❌ Foto KTP gagal:\n${e.toString()}',
          solusi: 'Buat bucket "ktp-docs" di Supabase Storage (Public ✓).',
          onClose: () { if (mounted) Navigator.pop(context, namaOk); },
        );
        return;
      }
    }

    if (!mounted) return;
    if (namaOk && fotoOk) Navigator.pop(context, true);
  }

  void _showErrorDialog({
    required String judul,
    required String pesan,
    required String solusi,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 22),
          const SizedBox(width: 8),
          Expanded(
              child: Text(judul,
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: AppColors.textPrimary))),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(pesan,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              if (solusi.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '💡 Solusi:\n$solusi',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClose?.call();
            },
            child: Text('Mengerti',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ));
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Bar
              _buildAppBar(context),
              const SizedBox(height: 36),

              // ── Avatar
              _buildAvatar(),
              const SizedBox(height: 36),

              // ── Field Nama
              _buildLabel('Nama Lengkap'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _namaCtrl,
                hint: 'Nama lengkap',
                enabled: true,
              ),
              const SizedBox(height: 20),

              // ── Field Email (read-only)
              _buildLabel('Email'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: TextEditingController(text: widget.email),
                hint: 'Email',
                enabled: false,
              ),
              const SizedBox(height: 24),

              // ── Foto KTP
              _buildLabel('Foto KTP'),
              const SizedBox(height: 4),
              Text(
                'Diperlukan untuk verifikasi identitas penyewa.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
              ),
              const SizedBox(height: 10),
              _buildKtpSection(),
              const SizedBox(height: 36),

              // ── Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    disabledBackgroundColor:
                        AppColors.primaryDark.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Simpan',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Batal
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Text(
                    'Batal',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  WIDGET HELPERS
  // ──────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
        Text(
          'Edit Profil',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textPrimary, size: 18),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final inisial = () {
      final words = widget.namaAwal.trim().split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      }
      return widget.namaAwal.isNotEmpty
          ? widget.namaAwal[0].toUpperCase()
          : 'N';
    }();

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _showPilihFoto,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _gambarBaru != null
                        // Foto baru yang dipilih user (lokal)
                        ? Image.file(_gambarBaru!,
                            width: 100, height: 100, fit: BoxFit.cover)
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            // Foto dari Supabase Storage
                            ? Image.network(_avatarUrl!,
                                width: 100, height: 100, fit: BoxFit.cover)
                            // Fallback: inisial nama
                            : Container(
                                color: AppColors.primaryDark,
                                child: Center(
                                  child: Text(
                                    inisial,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showPilihFoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.namaAwal,
            style: AppTextStyles.headlineLarge.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: AppTextStyles.bodyMedium.copyWith(
          color: enabled ? AppColors.textPrimary : AppColors.textHint,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ── Pick foto KTP dari galeri/kamera
  Future<void> _pilihKtp(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;
      setState(() => _ktpBaru = File(picked.path));
    } catch (e) {
      _snack('Gagal memilih foto KTP: ${e.toString()}');
    }
  }

  // KTP harus diambil via kamera (bukan galeri)
  void _showPilihKtp() => _pilihKtp(ImageSource.camera);

  Widget _buildKtpSection() {
    final hasKtp = _ktpBaru != null || (_ktpUrl != null && _ktpUrl!.isNotEmpty);
    return GestureDetector(
      onTap: _showPilihKtp,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasKtp ? AppColors.primary : AppColors.border,
            width: hasKtp ? 1.5 : 1,
          ),
        ),
        child: hasKtp
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _ktpBaru != null
                        ? Image.file(_ktpBaru!, fit: BoxFit.cover)
                        : Image.network(_ktpUrl!, fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.textHint)),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('Ganti',
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_outlined,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text('Tap untuk upload foto KTP',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Format: JPG / PNG',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
      ),
    );
  }
}
