import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_button.dart';
import '../../core/widgets/nr_text_field.dart';
import '../shell/main_shell.dart';
import 'login_page.dart';
import 'onboarding_page.dart';

class RegisterPage extends StatefulWidget {
  final UserRole role;
  const RegisterPage({super.key, required this.role});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _namaTokoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alamatController = TextEditingController();
  final _rekeningController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _googleLoading = false;
  bool _agreedToTerms = false;
  File? _ktpFile;
  File? _fotoProfilTokoFile;
  File? _fotoKtpOwnerFile;
  File? _fotoNpwpFile;
  File? _fotoNibFile;
  String? _selectedKota;
  String? _selectedBank;
  StreamSubscription? _authSub;
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  static const _kotaOptions = [
    'Malang',
    'Surabaya',
    'Jakarta',
    'Bandung',
    'Yogyakarta',
  ];

  static const _bankOptions = [
    'BCA',
    'BRI',
    'MANDIRI',
    'BNI',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _animController.dispose();
    _namaController.dispose();
    _namaTokoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    _rekeningController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static bool _hasUpper(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool _hasDigit(String v) => v.contains(RegExp(r'[0-9]'));
  static bool _hasSymbol(String v) =>
      v.contains(RegExp(r'[!@#\$%\^&\*()\-_=\+\[\]{}|;:,.<>?/\\`~"]'));

  Future<void> _pilihKtp() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _ktpFile = File(picked.path));
    }
  }

  Future<void> _pickOwnerImage(_OwnerUploadType type) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    setState(() {
      final file = File(picked.path);
      switch (type) {
        case _OwnerUploadType.profile:
          _fotoProfilTokoFile = file;
          break;
        case _OwnerUploadType.ktp:
          _fotoKtpOwnerFile = file;
          break;
        case _OwnerUploadType.npwp:
          _fotoNpwpFile = file;
          break;
        case _OwnerUploadType.nib:
          _fotoNibFile = file;
          break;
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.role != UserRole.pemilik && !_agreedToTerms) {
      _showError('Harap setujui Ketentuan Layanan terlebih dahulu.');
      return;
    }
    if (widget.role == UserRole.pemilik) {
      if (_fotoProfilTokoFile == null) {
        _showError('Foto profil toko wajib diupload.');
        return;
      }
      if (_fotoKtpOwnerFile == null) {
        _showError('Foto KTP wajib diupload.');
        return;
      }
      if (_fotoNpwpFile == null) {
        _showError('Foto NPWP wajib diupload.');
        return;
      }
      if (_fotoNibFile == null) {
        _showError('Foto NIB wajib diupload.');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService().daftar(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        namaLengkap: _namaController.text.trim(),
        noWa: _phoneController.text.trim(),
        namaToko: widget.role == UserRole.pemilik
            ? _namaTokoController.text.trim()
            : null,
        role: widget.role,
      );

      if (!mounted) return;
      if (widget.role == UserRole.pemilik) {
        if (response.session != null) {
          await AuthService().keluar();
        }
        if (!mounted) return;
        _showMitraSuccessDialog();
      } else if (response.session != null) {
        if (_ktpFile != null && response.user != null) {
          try {
            final uid = response.user!.id;
            final ext = _ktpFile!.path.split('.').last.toLowerCase();
            final path = 'ktp-docs/$uid.$ext';
            final bytes = await _ktpFile!.readAsBytes();
            await AuthService.client.storage.from('ktp-docs').uploadBinary(
                  path, bytes, fileOptions: const FileOptions(upsert: true));
            final url = AuthService.client.storage
                .from('ktp-docs')
                .getPublicUrl(path);
            await AuthService().perbaruiProfil(ktpUrl: url);
          } catch (_) {}
        }
        await AuthService().syncProfilSetelahLogin();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else if (response.user != null) {
        _showSuccessDialog();
      } else {
        _showError('Pendaftaran gagal. Silakan coba lagi.');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(_mapAuthError(e.message));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showError('DB Error: ${e.message} (${e.code})');
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() => _googleLoading = true);
    try {
      await AuthService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.naturerent://login-callback/',
      );
      // Dengarkan perubahan auth setelah browser OAuth selesai
      _authSub?.cancel();
      _authSub = AuthService.client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn && mounted) {
          _authSub?.cancel();
          await AuthService().syncProfilSetelahLogin();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainShell()),
              (r) => false,
            );
          }
        }
      });
    } catch (e) {
      if (mounted) _showError('Google gagal: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        msg.contains('email already in use')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (msg.contains('weak password') || msg.contains('password should be')) {
      return 'Kata sandi terlalu lemah.';
    }
    if (msg.contains('invalid email')) return 'Format email tidak valid.';
    if (msg.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit.';
    }
    return 'Pendaftaran gagal: $message';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        icon: const Icon(
          Icons.mark_email_read_outlined,
          color: AppColors.primary,
          size: 48,
        ),
        title: const Text(
          'Konfirmasi Email',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Kami telah mengirim link konfirmasi ke\n${_emailController.text.trim()}.\n\nSilakan cek inbox kamu, lalu masuk.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Oke, Masuk Sekarang',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMitraSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        icon: const Icon(
          Icons.storefront_rounded,
          color: Color(0xFF18743A),
          size: 48,
        ),
        title: const Text(
          'Registrasi Mitra Berhasil',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Akun mitra ${_emailController.text.trim()} sudah dibuat.\nSilakan masuk sebagai Mitra untuk membuka dashboard rental.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(role: UserRole.pemilik),
                ),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF18743A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: const Text(
              'Masuk sebagai Mitra',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKtpPicker() {
    return GestureDetector(
      onTap: _pilihKtp,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: _ktpFile == null
            ? const Center(child: Icon(Icons.add_a_photo_outlined, color: AppColors.textHint))
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_ktpFile!, fit: BoxFit.cover, width: double.infinity),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: widget.role == UserRole.pemilik
          ? const Color(0xFFF8F8F5)
          : AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.role == UserRole.pemilik
                ? _buildMitraRegister()
                : _buildCustomerRegister(),
          ),
        ),
      ),
    );
  }

  Widget _buildMitraRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 34),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _BrandMark(),
            const SizedBox(height: 26),
            _buildMitraHero(),
            const SizedBox(height: 28),
            Text(
              'Daftar Akun Mitra',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayLarge.copyWith(
                color: const Color(0xFF202321),
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kembangkan Bisnis Penyewaan Alat\nCamping Anda Bersama Kami.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF496171),
                fontSize: 17,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 26),
            _buildMitraFormCard(),
            const SizedBox(height: 26),
            Text.rich(
              TextSpan(
                text: 'Dengan mendaftar, Anda menyetujui ',
                children: [
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF6F7B6E),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '\nserta '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF6F7B6E),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' NatureRent Partners.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF7E887B),
                letterSpacing: 0,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMitraHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: double.infinity,
        height: 202,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/registrasi_owner.png',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMitraFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MitraSection(
            title: 'Detail Toko',
            children: [
              _MitraTextField(
                label: 'Nama Toko',
                hint: 'Masukkan nama toko',
                icon: Icons.storefront_outlined,
                controller: _namaTokoController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama toko wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _MitraTextField(
                label: 'Nomor Telepon',
                hint: 'Masukkan nomor telepon',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nomor telepon wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _MitraDropdownField(
                label: 'Kota',
                hint: 'Pilih kota',
                icon: Icons.location_city_outlined,
                value: _selectedKota,
                items: _kotaOptions,
                onChanged: (value) => setState(() => _selectedKota = value),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kota wajib dipilih';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _MitraTextField(
                label: 'Alamat',
                hint: 'Masukkan alamat toko',
                icon: Icons.place_outlined,
                controller: _alamatController,
                keyboardType: TextInputType.streetAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Alamat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _OwnerUploadButton(
                label: 'Foto Profil Toko',
                buttonText: 'Upload Foto Profil',
                file: _fotoProfilTokoFile,
                onTap: () => _pickOwnerImage(_OwnerUploadType.profile),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _MitraSection(
            title: 'Verifikasi Dokumen',
            children: [
              _OwnerUploadButton(
                label: 'Foto KTP',
                buttonText: 'Upload Foto KTP',
                file: _fotoKtpOwnerFile,
                onTap: () => _pickOwnerImage(_OwnerUploadType.ktp),
              ),
              const SizedBox(height: 16),
              _OwnerUploadButton(
                label: 'Foto NPWP',
                buttonText: 'Upload Foto NPWP',
                file: _fotoNpwpFile,
                onTap: () => _pickOwnerImage(_OwnerUploadType.npwp),
              ),
              const SizedBox(height: 16),
              _OwnerUploadButton(
                label: 'Foto NIB',
                buttonText: 'Upload Foto NIB',
                file: _fotoNibFile,
                onTap: () => _pickOwnerImage(_OwnerUploadType.nib),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _MitraSection(
            title: 'Detail Keuangan',
            children: [
              _MitraDropdownField(
                label: 'Pilih Bank',
                hint: 'Pilih Bank',
                icon: Icons.account_balance_outlined,
                value: _selectedBank,
                items: _bankOptions,
                onChanged: (value) => setState(() => _selectedBank = value),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Bank wajib dipilih';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _MitraTextField(
                label: 'Nomor Rekening',
                hint: 'Masukkan nomor rekening',
                icon: Icons.credit_card_outlined,
                controller: _rekeningController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nomor rekening wajib diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          _MitraSection(
            title: 'Akun Rental',
            children: [
              _MitraTextField(
                label: 'Nama Pemilik Toko',
                hint: 'Masukkan nama pemilik toko',
                icon: Icons.person_outline_rounded,
                controller: _namaController,
                keyboardType: TextInputType.name,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama pemilik toko wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _MitraTextField(
                label: 'Email',
                hint: 'Masukkan email',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  final email = v.trim();
                  final valid = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(email);
                  if (!valid) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _MitraTextField(
                label: 'Password',
                hint: 'Masukkan password',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                isPassword: true,
                validator: _ownerPasswordValidator,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18743A),
                disabledBackgroundColor: const Color(
                  0xFF18743A,
                ).withValues(alpha: 0.55),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFF18743A).withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      'Selesaikan Pendaftaran',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sudah punya akun? ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF496171),
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(role: UserRole.pemilik),
                  ),
                ),
                child: Text(
                  'Masuk',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF176B37),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.park_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NatureRent',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Daftar & mulai berpetualang',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Buat Akun',
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bergabunglah dengan komunitas pecinta alam.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            NrTextField(
              label: 'Nama Lengkap',
              hint: 'Nama lengkap kamu',
              controller: _namaController,
              keyboardType: TextInputType.name,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nama wajib diisi';
                if (v.length < 3) return 'Nama terlalu pendek';
                return null;
              },
            ),
            const SizedBox(height: 18),
            NrTextField(
              label: 'Alamat Email',
              hint: 'nama@gmail.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email wajib diisi';
                if (!v.toLowerCase().endsWith('@gmail.com')) {
                  return 'Email harus menggunakan @gmail.com';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            NrTextField(
              label: 'Nomor HP',
              hint: '+62 812 3456 7890',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nomor HP wajib diisi';
                if (v.length < 9) return 'Nomor HP tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 18),
            NrTextField(
              label: 'Kata Sandi',
              hint: '........',
              controller: _passwordController,
              isPassword: true,
              helperText: 'Min 8 karakter - Huruf kapital - Angka - Simbol',
              validator: _passwordValidator,
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _passwordController,
              builder: (_, val, child) => _PwStrength(pw: val.text),
            ),
            const SizedBox(height: 20),
            Text('Foto KTP',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Opsional · Bisa diupload nanti via Edit Profil',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint)),
            const SizedBox(height: 10),
            _buildKtpPicker(),
            const SizedBox(height: 20),
            _buildTermsCheckbox(),
            const SizedBox(height: 28),
            NrButton(
              text: 'Selesaikan Pendaftaran',
              isLoading: _isLoading,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sudah punya akun? ', style: AppTextStyles.bodyMedium),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Masuk',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Divider(color: AppColors.border, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ATAU DAFTAR DENGAN',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: AppColors.border, thickness: 1),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _googleLoading ? null : _handleGoogleRegister,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _googleLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleLogo(),
                          const SizedBox(width: 12),
                          Text(
                            'Daftar dengan Google',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Minimal 8 karakter';
    if (!_hasUpper(v)) return 'Harus ada huruf kapital (A-Z)';
    if (!_hasDigit(v)) return 'Harus ada angka (0-9)';
    if (!_hasSymbol(v)) return 'Harus ada simbol (!@#\$%^&*)';
    return null;
  }

  String? _ownerPasswordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    if (v.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                const TextSpan(text: 'Saya menyetujui '),
                TextSpan(
                  text: 'Ketentuan Layanan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
                const TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _OwnerUploadType { profile, ktp, npwp, nib }

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.park_rounded, color: Color(0xFF103D20), size: 28),
        const SizedBox(width: 10),
        Text(
          'NatureRent',
          style: AppTextStyles.headlineLarge.copyWith(
            color: const Color(0xFF103D20),
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MitraSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _MitraSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: const Color(0xFF18743A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _MitraTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;

  const _MitraTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
  });

  @override
  State<_MitraTextField> createState() => _MitraTextFieldState();
}

class _MitraTextFieldState extends State<_MitraTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF344B3B),
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscure : false,
          validator: widget.validator,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF25302A),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF7B8794),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: const Color(0xFF748078),
              size: 17,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF748078),
                      size: 17,
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF2F4F1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF18743A),
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _MitraDropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _MitraDropdownField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF344B3B),
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF748078),
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF25302A),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF7B8794),
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF748078), size: 17),
            filled: true,
            fillColor: const Color(0xFFF2F4F1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF18743A),
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.3),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _OwnerUploadButton extends StatelessWidget {
  final String label;
  final String buttonText;
  final File? file;
  final VoidCallback onTap;

  const _OwnerUploadButton({
    required this.label,
    required this.buttonText,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = file?.path.split(Platform.pathSeparator).last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF344B3B),
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: file == null
                    ? const Color(0xFFE0E5DE)
                    : const Color(0xFF18743A),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EFE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFF18743A),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fileName ?? buttonText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: file == null
                          ? const Color(0xFF496171)
                          : const Color(0xFF25302A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (file != null) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      file!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PwStrength extends StatelessWidget {
  final String pw;
  const _PwStrength({required this.pw});

  bool get _hasLen => pw.length >= 8;
  bool get _hasCap => pw.contains(RegExp(r'[A-Z]'));
  bool get _hasNum => pw.contains(RegExp(r'[0-9]'));
  bool get _hasSym =>
      pw.contains(RegExp(r'[!@#\$%\^&\*()\-_=\+\[\]{}|;:,.<>?/\\`~"]'));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Req(ok: _hasLen, label: 'Minimal 8 karakter'),
        const SizedBox(height: 3),
        _Req(ok: _hasCap, label: 'Mengandung huruf kapital (A-Z)'),
        const SizedBox(height: 3),
        _Req(ok: _hasNum, label: 'Mengandung angka (0-9)'),
        const SizedBox(height: 3),
        _Req(ok: _hasSym, label: 'Mengandung simbol (!@#\$%^&*)'),
      ],
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 18),
        children: [
          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
          TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
          TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final bool ok;
  final String label;
  const _Req({required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: ok ? AppColors.primary : AppColors.textHint,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: ok ? AppColors.primary : AppColors.textHint,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
