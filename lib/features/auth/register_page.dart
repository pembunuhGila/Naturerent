import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_button.dart';
import '../../core/widgets/nr_text_field.dart';
import '../../features/shell/role_gate.dart';
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
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _agreedToTerms = false;
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

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
    _animController.dispose();
    _namaController.dispose();
    _namaTokoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static bool _hasUpper(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool _hasDigit(String v) => v.contains(RegExp(r'[0-9]'));
  static bool _hasSymbol(String v) =>
      v.contains(RegExp(r'[!@#\$%\^&\*()\-_=\+\[\]{}|;:,.<>?/\\`~"]'));

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.role != UserRole.pemilik && !_agreedToTerms) {
      _showError('Harap setujui Ketentuan Layanan terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService().daftar(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        namaLengkap: _namaController.text.trim(),
        noWa: widget.role == UserRole.pemilik
            ? ''
            : _phoneController.text.trim(),
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
        await AuthService().syncProfilSetelahLogin();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleGate()),
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
    try {
      await AuthService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.naturerent://login-callback/',
      );
    } catch (e) {
      if (mounted) _showError('Google gagal: ${e.toString()}');
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
              'Mulailah petualangan bisnis penyewaan alat\ncamping Anda bersama kami.',
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
              'assets/images/loading_background.png',
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
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _MitraTextField(
            label: 'NAMA PEMILIK',
            hint: 'Contoh: Rachmad Zaki Setyawan',
            icon: Icons.person_outline_rounded,
            controller: _namaController,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nama pemilik wajib diisi';
              if (v.length < 3) return 'Nama terlalu pendek';
              return null;
            },
          ),
          const SizedBox(height: 22),
          _MitraTextField(
            label: 'NAMA TOKO',
            hint: 'Contoh: Sekawan Outdoor',
            icon: Icons.storefront_outlined,
            controller: _namaTokoController,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nama toko wajib diisi';
              if (v.length < 3) return 'Nama toko terlalu pendek';
              return null;
            },
          ),
          const SizedBox(height: 22),
          _MitraTextField(
            label: 'ALAMAT EMAIL',
            hint: 'mitra04@gmail.com',
            icon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email wajib diisi';
              if (!v.contains('@')) return 'Format email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 22),
          _MitraTextField(
            label: 'KATA SANDI',
            hint: '........',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            isPassword: true,
            validator: _passwordValidator,
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
                  borderRadius: BorderRadius.circular(7),
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
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFE8EBE5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sudah punya akun Mitra? ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF496171),
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Masuk di sini',
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
            const SizedBox(height: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _passwordController,
              builder: (_, val, child) => _PwStrength(pw: val.text),
            ),
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
                onPressed: _handleGoogleRegister,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
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
            color: const Color(0xFF7A8277),
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.1,
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
            fillColor: const Color(0xFFE1E3DF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(
                color: Color(0xFF18743A),
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppColors.error, width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppColors.error, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        children: [
          TextSpan(
            text: 'G',
            style: TextStyle(color: Color(0xFF4285F4)),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(color: Color(0xFFEA4335)),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(color: Color(0xFFFBBC05)),
          ),
          TextSpan(
            text: 'g',
            style: TextStyle(color: Color(0xFF4285F4)),
          ),
          TextSpan(
            text: 'l',
            style: TextStyle(color: Color(0xFF34A853)),
          ),
          TextSpan(
            text: 'e',
            style: TextStyle(color: Color(0xFFEA4335)),
          ),
        ],
      ),
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
