import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_button.dart';
import '../../core/widgets/nr_text_field.dart';
import '../../core/services/auth_service.dart';
import '../../features/shell/main_shell.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Password rules helper
  static bool _hasUpper(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool _hasDigit(String v) => v.contains(RegExp(r'[0-9]'));
  static bool _hasSymbol(String v) =>
      v.contains(RegExp(r'[!@#\$%\^&\*()\-_=\+\[\]{}|;:,.<>?/\\`~"]'));

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Harap setujui Ketentuan Layanan terlebih dahulu.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await AuthService().daftar(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        namaLengkap: _namaController.text.trim(),
        noWa: _phoneController.text.trim(),
        role: widget.role,
      );
      if (!mounted) return;
      if (response.session != null) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        icon: const Icon(Icons.mark_email_read_outlined,
            color: AppColors.primary, size: 48),
        title: const Text('Konfirmasi Email',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          'Kami telah mengirim link konfirmasi ke\n${_emailController.text.trim()}.\n\nSilakan cek inbox kamu, lalu masuk.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Inter', color: AppColors.textSecondary, height: 1.5),
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
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Oke, Masuk Sekarang',
                style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Logo + title
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.park_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NatureRent',
                            style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.primaryDark, fontSize: 22)),
                        Text('Daftar & mulai berpetualang',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ]),
                    ]),
                    const SizedBox(height: 32),

                    Text('Buat Akun', style: AppTextStyles.displayMedium
                        .copyWith(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Bergabunglah dengan komunitas pecinta alam.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 28),

                    // ── Nama
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

                    // ── Email (@gmail.com)
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

                    // ── No HP
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

                    // ── Password
                    NrTextField(
                      label: 'Kata Sandi',
                      hint: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                      helperText:
                          'Min 8 karakter · Huruf kapital · Angka · Simbol',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                        if (v.length < 8) return 'Minimal 8 karakter';
                        if (!_hasUpper(v)) return 'Harus ada huruf kapital (A-Z)';
                        if (!_hasDigit(v)) return 'Harus ada angka (0-9)';
                        if (!_hasSymbol(v)) return 'Harus ada simbol (!@#\$%^&*)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // ── Password strength indicator
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _passwordController,
                      builder: (_, val, child) =>
                          _PwStrength(pw: val.text),
                    ),
                    const SizedBox(height: 20),

                    // ── Terms
                    _buildTermsCheckbox(),
                    const SizedBox(height: 28),

                    // ── Register button
                    NrButton(
                      text: 'Selesaikan Pendaftaran',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 20),

                    // ── Login redirect
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Sudah punya akun? ',
                            style: AppTextStyles.bodyMedium),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('Masuk',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Divider
                    Row(children: [
                      const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ATAU DAFTAR DENGAN',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textHint,
                                    letterSpacing: 0.5)),
                      ),
                      const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1)),
                    ]),
                    const SizedBox(height: 20),

                    // ── Google button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _handleGoogleRegister,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(
                              color: AppColors.border, width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GoogleLogo(),
                            const SizedBox(width: 12),
                            Text('Daftar dengan Google',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22, height: 22,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              children: [
                const TextSpan(text: 'Saya menyetujui '),
                TextSpan(
                  text: 'Ketentuan Layanan',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary),
                ),
                const TextSpan(text: ' dan '),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary),
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

// ── Google colorful logo
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 18),
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

// ── Password strength widget
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
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: ok ? AppColors.primary : AppColors.textHint,
                fontSize: 11)),
      ],
    );
  }
}
