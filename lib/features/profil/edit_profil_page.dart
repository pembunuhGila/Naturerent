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

  File? _gambarBaru;        // file lokal yang dipilih user
  String? _avatarUrl;       // URL yang tersimpan di Supabase
  bool _isSaving = false;

  // ──────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.namaAwal);
    _avatarUrl = widget.avatarUrlAwal;
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
            statusBarColor: AppColors.primaryDark,
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

    try {
      String? newAvatarUrl = _avatarUrl;

      // Upload foto baru ke Supabase Storage jika ada
      if (_gambarBaru != null) {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) throw Exception('User tidak ditemukan.');

        final ext = _gambarBaru!.path.split('.').last.toLowerCase();
        final storagePath = 'avatars/$userId.$ext';
        final bytes = await _gambarBaru!.readAsBytes();

        await _client.storage.from('avatars').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        newAvatarUrl =
            _client.storage.from('avatars').getPublicUrl(storagePath);
      }

      // Simpan ke public.users
      await AuthService().perbaruiProfil(
        namaLengkap: nama,
        avatarUrl: newAvatarUrl,
      );

      // Sync ke auth metadata juga
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': nama}),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // true = ada perubahan
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('Gagal menyimpan: ${e.toString()}');
    }
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
              _buildLabel('Nama'),
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
              const SizedBox(height: 40),

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
}
