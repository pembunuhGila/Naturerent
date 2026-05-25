import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/rental_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/widgets/nr_toast.dart';

class EditProfilPage extends StatefulWidget {
  /// Nama & avatarUrl yang sudah ada (dari ProfilPage)
  final String namaAwal;
  final String email;
  final String? avatarUrlAwal;
  final bool isMitra;
  final String? namaTokoAwal;
  final RentalProfile? rentalProfile;

  const EditProfilPage({
    super.key,
    required this.namaAwal,
    required this.email,
    this.avatarUrlAwal,
    this.isMitra = false,
    this.namaTokoAwal,
    this.rentalProfile,
  });

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  late final TextEditingController _namaCtrl;
  late final TextEditingController _namaTokoCtrl;
  late final TextEditingController _emailBisnisCtrl;
  final _client = AuthService.client;
  final _rentalService = RentalService();
  final _picker = ImagePicker();

  File? _gambarBaru;        // file lokal foto profil
  String? _avatarUrl;       // URL avatar di Supabase
  String? _fotoProfilTokoUrl;
  File? _coverBaru;
  String? _coverUrl;
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
    _namaTokoCtrl = TextEditingController(
      text: widget.namaTokoAwal ?? widget.rentalProfile?.namaRental ?? '',
    );
    _emailBisnisCtrl = TextEditingController(text: widget.email);
    _avatarUrl = widget.avatarUrlAwal;
    _fotoProfilTokoUrl = widget.rentalProfile?.fotoProfil ?? widget.avatarUrlAwal;
    _coverUrl = widget.rentalProfile?.fotoBanner;
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
    _namaTokoCtrl.dispose();
    _emailBisnisCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  //  AMBIL GAMBAR
  // ──────────────────────────────────────────────────────────
  void _showPilihFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  color: const Color(0xFFE0E5DE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EFE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF18743A)),
                ),
                title: Text('Ambil dari Kamera',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Color(0xFF202321))),
                onTap: () {
                  Navigator.pop(context);
                  _pilihGambar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EFE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF18743A)),
                ),
                title: Text('Pilih dari Galeri',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Color(0xFF202321))),
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
            toolbarColor: const Color(0xFF18743A),
            toolbarWidgetColor: Colors.white,
            statusBarColor: const Color(0xFF18743A), // ignore: deprecated_member_use
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFF18743A),
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

  Future<void> _pilihFotoMitra({required bool cover}) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null || !mounted) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: cover
            ? const CropAspectRatio(ratioX: 16, ratioY: 8)
            : const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                cover ? 'Pangkas Foto Sampul' : 'Pangkas Foto Profil',
            toolbarColor: const Color(0xFF18743A),
            toolbarWidgetColor: Colors.white,
            statusBarColor: const Color(0xFF18743A),
            backgroundColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFF18743A),
            initAspectRatio: cover
                ? CropAspectRatioPreset.ratio16x9
                : CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: cover ? 'Pangkas Foto Sampul' : 'Pangkas Foto Profil',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped == null || !mounted) return;
      setState(() {
        if (cover) {
          _coverBaru = File(cropped.path);
        } else {
          _gambarBaru = File(cropped.path);
        }
      });
    } catch (e) {
      _snack('Gagal memilih/memangkas foto: ${e.toString()}');
    }
  }

  // ──────────────────────────────────────────────────────────
  //  UPLOAD & SIMPAN
  // ──────────────────────────────────────────────────────────
  Future<void> _simpanMitra() async {
    final namaToko = _namaTokoCtrl.text.trim();
    final namaPemilik = _namaCtrl.text.trim();
    final emailBisnis = _emailBisnisCtrl.text.trim();

    if (namaToko.isEmpty) {
      _snack('Nama toko wajib diisi.');
      return;
    }
    if (namaPemilik.isEmpty) {
      _snack('Nama pemilik wajib diisi.');
      return;
    }
    if (emailBisnis.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(emailBisnis)) {
      _snack('Email bisnis tidak valid.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Session habis.');

      String? fotoProfilTokoUrl = _fotoProfilTokoUrl;
      if (_gambarBaru != null) {
        fotoProfilTokoUrl = await _uploadImage(
          bucket: 'rental_avatar',
          pathPrefix: 'rental-profiles',
          userId: userId,
          file: _gambarBaru!,
        );
      }

      String? coverUrl = _coverUrl;
      if (_coverBaru != null) {
        coverUrl = await _uploadImage(
          bucket: 'rental_avatar',
          pathPrefix: 'rental-banners',
          userId: userId,
          file: _coverBaru!,
        );
      }

      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': namaPemilik}),
      );

      final rental =
          widget.rentalProfile ?? await _rentalService.pastikanRentalSayaAda();
      final rentalPayload = <String, dynamic>{
        'nama_rental': namaToko,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fotoProfilTokoUrl != null) {
        rentalPayload['foto_profil'] = fotoProfilTokoUrl;
      }
      if (coverUrl != null) {
        rentalPayload['foto_banner'] = coverUrl;
      }

      final updatedRentalData = await _client
          .from('rental_profiles')
          .update(rentalPayload)
          .eq('id', rental.id)
          .eq('owner_id', userId)
          .select('*, rental_settings(*)')
          .single();
      final updatedRental = RentalProfile.fromMap(updatedRentalData);

      if (!mounted) return;
      Navigator.pop(context, updatedRental);
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal menyimpan profil toko: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _uploadImage({
    required String bucket,
    required String pathPrefix,
    required String userId,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path =
        '$pathPrefix/$userId-${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 22),
          const SizedBox(width: 8),
          Expanded(
              child: Text(judul,
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: const Color(0xFF202321)))),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(pesan,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF496171))),
              if (solusi.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EFE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '💡 Solusi:\n$solusi',
                    style: AppTextStyles.caption.copyWith(
                        color: Color(0xFF18743A),
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
                    color: Color(0xFF18743A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    NrToast.show(context, msg, type: NrToastType.info);
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

    if (widget.isMitra) return _buildMitraEditPage();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F5),
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
                style: AppTextStyles.caption.copyWith(color: const Color(0xFF7B8794)),
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
                    backgroundColor: const Color(0xFF18743A),
                    disabledBackgroundColor:
                        const Color(0xFF18743A).withValues(alpha: 0.5),
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
                      color: const Color(0xFF18743A),
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

  Widget _buildMitraEditPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildMitraBottomNav(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMitraEditAppBar(),
              const SizedBox(height: 26),
              _buildMitraEditHero(),
              const SizedBox(height: 48),
              _buildMitraEditForm(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _simpanMitra,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF123D1D),
                    disabledBackgroundColor:
                        const Color(0xFF123D1D).withValues(alpha: 0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F6F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Batalkan',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF626A60),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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

  Widget _buildMitraEditAppBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF626A60),
                size: 25,
              ),
            ),
          ),
          Text(
            'Edit Profil Toko',
            style: AppTextStyles.headlineLarge.copyWith(
              color: const Color(0xFF202321),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMitraEditHero() {
    return SizedBox(
      height: 224,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          GestureDetector(
            onTap: () => _pilihFotoMitra(cover: true),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: double.infinity,
                height: 158,
                child: _buildMitraCoverImage(),
              ),
            ),
          ),
          Positioned(
            top: 56,
            child: _MitraCameraButton(
              icon: Icons.camera_alt_outlined,
              onTap: () => _pilihFotoMitra(cover: true),
            ),
          ),
          Positioned(
            top: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEFEA),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _buildMitraProfileImage(),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -3,
                  child: _MitraCameraButton(
                    icon: Icons.camera_alt_rounded,
                    small: true,
                    onTap: () => _pilihFotoMitra(cover: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMitraCoverImage() {
    if (_coverBaru != null) return Image.file(_coverBaru!, fit: BoxFit.cover);
    if (_coverUrl != null && _coverUrl!.isNotEmpty) {
      return Image.network(
        _coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/loading_background.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset('assets/images/loading_background.png',
        fit: BoxFit.cover);
  }

  Widget _buildMitraProfileImage() {
    if (_gambarBaru != null) return Image.file(_gambarBaru!, fit: BoxFit.cover);
    if (_fotoProfilTokoUrl != null && _fotoProfilTokoUrl!.isNotEmpty) {
      return Image.network(
        _fotoProfilTokoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildMitraInitialAvatar(),
      );
    }
    return _buildMitraInitialAvatar();
  }

  Widget _buildMitraInitialAvatar() {
    final nama = _namaCtrl.text.trim().isNotEmpty ? _namaCtrl.text.trim() : 'N';
    final words = nama.split(' ');
    final initial =
        words.length >= 2 ? '${words[0][0]}${words[1][0]}' : nama[0];
    return Container(
      color: const Color(0xFF18743A),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: AppTextStyles.headlineLarge.copyWith(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMitraEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMitraEditField(
          label: 'NAMA TOKO',
          controller: _namaTokoCtrl,
          hint: 'Rimba Basecamp',
        ),
        const SizedBox(height: 24),
        _buildMitraEditField(
          label: 'NAMA PEMILIK',
          controller: _namaCtrl,
          hint: 'Andi Herlambang',
        ),
        const SizedBox(height: 24),
        _buildMitraEditField(
          label: 'EMAIL BISNIS',
          controller: _emailBisnisCtrl,
          hint: 'rimbasendang@gmail.com',
          keyboardType: TextInputType.emailAddress,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildMitraEditField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF727970),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color:
                readOnly ? const Color(0xFFF7F8F6) : const Color(0xFFF1F3F0),
            borderRadius: BorderRadius.circular(26),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            readOnly: readOnly,
            style: AppTextStyles.bodyMedium.copyWith(
              color: readOnly
                  ? const Color(0xFF626A60)
                  : const Color(0xFF202321),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF9BA19A),
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: minLines > 1 ? 18 : 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMitraBottomNav() {
    final items = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.receipt_long_rounded, 'Pesanan'),
      (Icons.edit_note_rounded, 'Kelola'),
      (Icons.person_outline_rounded, 'Profil'),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final isActive = index == 3;
              return Expanded(
                child: GestureDetector(
                  onTap: isActive ? null : () => Navigator.pop(context, false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      width: isActive ? 92 : null,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF18743A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[index].$1,
                            size: 21,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF817B72),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[index].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF817B72),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF202321), size: 20),
        ),
        Text(
          'Edit Profil',
          style: AppTextStyles.headlineLarge.copyWith(
            color: const Color(0xFF202321),
            fontSize: 20,
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E5DE)),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: Color(0xFF202321), size: 18),
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
                        color: const Color(0xFF18743A).withValues(alpha: 0.25),
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
                                color: const Color(0xFF18743A),
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
                      color: const Color(0xFF18743A),
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
                .copyWith(color: const Color(0xFF496171)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: const Color(0xFF496171),
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
        color: enabled ? Colors.white : const Color(0xFFF8F8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? const Color(0xFFE0E5DE)
              : const Color(0xFFE0E5DE).withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: AppTextStyles.bodyMedium.copyWith(
          color: enabled ? const Color(0xFF202321) : const Color(0xFF7B8794),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF7B8794)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasKtp ? const Color(0xFF18743A) : const Color(0xFFE0E5DE),
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
                                color: Color(0xFF7B8794))),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF18743A).withValues(alpha: 0.85),
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
                      color: const Color(0xFFE4EFE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_outlined,
                        color: Color(0xFF18743A), size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text('Tap untuk upload foto KTP',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Color(0xFF18743A),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Format: JPG / PNG',
                      style: AppTextStyles.caption
                          .copyWith(color: Color(0xFF7B8794))),
                ],
              ),
      ),
    );
  }
}

class _MitraCameraButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  const _MitraCameraButton({
    required this.icon,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 48.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: small ? const Color(0xFF123D1D) : Colors.white,
          shape: BoxShape.circle,
          border: small ? Border.all(color: Colors.white, width: 4) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: small ? Colors.white : const Color(0xFF123D1D),
          size: small ? 17 : 22,
        ),
      ),
    );
  }
}
