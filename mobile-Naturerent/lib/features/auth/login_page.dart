import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';
import '../shell/role_gate.dart';
import 'onboarding_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final UserRole role;
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  late final AnimationController _anim;
  late final Animation<double> _fade;
  StreamSubscription? _authSub;

  _LoginRoleConfig get _config => _LoginRoleConfig.fromRole(widget.role);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _anim.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().masuk(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );
      await AuthService().syncProfilSetelahLogin();
      final role = await AuthService().ambilRolePengguna();
      if (role == 'rental_owner') {
        await RentalService().pastikanRentalSayaAda();
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleGate()),
        (r) => false,
      );
    } on AuthException catch (e) {
      _showError(_mapErr(e.message));
    } catch (_) {
      _showError('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _googleLoading = true);
    try {
      // Dengarkan perubahan auth setelah browser OAuth selesai
      _authSub?.cancel();
      _authSub = AuthService.client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn && mounted) {
          _authSub?.cancel();
          await AuthService().pastikanProfilPenggunaAda();
          await AuthService().syncProfilSetelahLogin();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const RoleGate()),
              (r) => false,
            );
          }
        }
      });
      await AuthService().masukDenganGoogle();
    } catch (e) {
      if (mounted) _showError('Login Google gagal: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _mapErr(String message) {
    final s = message.toLowerCase();
    if (s.contains('invalid login') ||
        s.contains('invalid email or password')) {
      return 'Email atau kata sandi salah.';
    }
    if (s.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox kamu.';
    }
    if (s.contains('too many')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }
    return message;
  }

  void _showError(String message) {
    NrToast.show(context, message, type: NrToastType.error);
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
      backgroundColor: _config.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: widget.role == UserRole.pemilik
              ? _buildPartnerLayout()
              : _buildDefaultLayout(),
        ),
      ),
    );
  }

  Widget _buildPartnerLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 70),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _BrandMark(color: _config.accentColor, centered: true),
                  const SizedBox(height: 28),
                  Text(
                    _config.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: const Color(0xFF202321),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _config.subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF687067),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildPartnerCard(),
                  const SizedBox(height: 82),
                  _buildPartnerFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPartnerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('EMAIL ATAU USERNAME'),
          const SizedBox(height: 8),
          _buildEmailField(compact: true),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _buildFieldLabel('KATA SANDI')),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Lupa Password?',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF687067),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPasswordField(compact: true),
          const SizedBox(height: 32),
          _buildLoginButton(),
          const SizedBox(height: 34),
          const Divider(color: Color(0xFFE7E9E3)),
          const SizedBox(height: 20),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  Widget _buildDefaultLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackButton(),
            const SizedBox(height: 32),
            _BrandMark(color: _config.accentColor),
            const SizedBox(height: 36),
            Text(
              _config.title,
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: _config.titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _config.subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            _buildFieldLabel(_config.emailLabel),
            const SizedBox(height: 8),
            _buildEmailField(),
            const SizedBox(height: 18),
            _buildFieldLabel('Kata Sandi'),
            const SizedBox(height: 8),
            _buildPasswordField(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Lupa kata sandi?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _config.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLoginButton(),
            if (_config.showGoogleLogin) ...[
              const SizedBox(height: 24),
              _buildDivider('ATAU MASUK DENGAN'),
              const SizedBox(height: 20),
              _buildGoogleButton(),
            ],
            const SizedBox(height: 28),
            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
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
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: _config.labelColor,
        fontWeight: FontWeight.w900,
        fontSize: widget.role == UserRole.pemilik ? 12 : 13,
        letterSpacing: widget.role == UserRole.pemilik ? 1.1 : 0.2,
      ),
    );
  }

  Widget _buildEmailField({bool compact = false}) {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontSize: compact ? 16 : 14,
      ),
      decoration: _inputDecoration(
        hint: compact ? 'nama@email.com' : 'contoh@gmail.com',
        icon: compact ? null : Icons.alternate_email_rounded,
        compact: compact,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Email wajib diisi';
        if (!v.contains('@')) return 'Format email tidak valid';
        return null;
      },
    );
  }

  Widget _buildPasswordField({bool compact = false}) {
    return TextFormField(
      controller: _pwCtrl,
      obscureText: _obscure,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontSize: compact ? 16 : 14,
      ),
      decoration: _inputDecoration(
        hint: '........',
        icon: compact ? null : Icons.lock_outline_rounded,
        compact: compact,
        suffix: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: compact ? 20 : 18,
            color: AppColors.textHint,
          ),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
        if (v.length < 8) return 'Minimal 8 karakter';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Widget? suffix,
    bool compact = false,
  }) {
    final radius = compact ? 14.0 : 12.0;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: compact ? const Color(0xFFB8BDB5) : AppColors.textHint,
        fontSize: compact ? 16 : 14,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 18, color: AppColors.textHint),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(),
      filled: true,
      fillColor: compact ? const Color(0xFFFAFBF8) : AppColors.surface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 16,
        vertical: compact ? 17 : 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFD7DDD2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFD7DDD2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: _config.accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _buildLoginButton() {
    final isPartner = widget.role == UserRole.pemilik;
    return SizedBox(
      width: double.infinity,
      height: isPartner ? 54 : 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _config.accentColor,
          disabledBackgroundColor: _config.accentColor.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: isPartner ? 9 : 0,
          shadowColor: _config.accentColor.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPartner ? 14 : 14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _config.buttonText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isPartner ? 16 : 15,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _config.registerPrompt,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF687067),
            fontSize: widget.role == UserRole.pemilik ? 15 : 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegisterPage(role: widget.role)),
          ),
          child: Text(
            'Daftar Sekarang',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _config.accentColor,
              fontWeight: FontWeight.w900,
              fontSize: widget.role == UserRole.pemilik ? 15 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _googleLoading ? null : _loginGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _googleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Lanjutkan dengan Google',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPartnerFooter() {
    return Column(
      children: [
        Text(
          '2026 MITRA NATURERENT\nALL RIGHTS RESERVED.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF9DA39A),
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
            height: 1.6,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _footerLink('SYARAT & KETENTUAN'),
            const SizedBox(width: 28),
            _footerLink('KEBIJAKAN PRIVASI'),
          ],
        ),
      ],
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: const Color(0xFF9DA39A),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
        fontSize: 10,
      ),
    );
  }
}

class _LoginRoleConfig {
  final String title;
  final String subtitle;
  final String buttonText;
  final String registerPrompt;
  final String emailLabel;
  final Color accentColor;
  final Color titleColor;
  final Color labelColor;
  final Color backgroundColor;
  final bool showGoogleLogin;

  const _LoginRoleConfig({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.registerPrompt,
    required this.emailLabel,
    required this.accentColor,
    required this.titleColor,
    required this.labelColor,
    required this.backgroundColor,
    required this.showGoogleLogin,
  });

  factory _LoginRoleConfig.fromRole(UserRole role) {
    return switch (role) {
      UserRole.pemilik => const _LoginRoleConfig(
        title: 'Selamat Datang, Mitra',
        subtitle: 'Masuk ke dasbor pengelolaan camping Anda',
        buttonText: 'Masuk sebagai Mitra',
        registerPrompt: 'Belum bergabung?  ',
        emailLabel: 'EMAIL ATAU USERNAME',
        accentColor: Color(0xFF18743A),
        titleColor: Color(0xFF202321),
        labelColor: Color(0xFF666D64),
        backgroundColor: Color(0xFFF5F4F0),
        showGoogleLogin: false,
      ),
      UserRole.penyewa => const _LoginRoleConfig(
        title: 'Masuk Akun',
        subtitle: 'Lanjutkan petualanganmu bersama kami.',
        buttonText: 'Masuk sebagai Penyewa',
        registerPrompt: 'Belum punya akun?  ',
        emailLabel: 'Email',
        accentColor: AppColors.primaryDark,
        titleColor: AppColors.textPrimary,
        labelColor: AppColors.textSecondary,
        backgroundColor: AppColors.background,
        showGoogleLogin: true,
      ),
    };
  }
}

class _BrandMark extends StatelessWidget {
  final Color color;
  final bool centered;

  const _BrandMark({required this.color, this.centered = false});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(Icons.park_rounded, color: color, size: 28),
        const SizedBox(width: 10),
        Text(
          'NatureRent',
          style: AppTextStyles.headlineLarge.copyWith(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    return centered ? Center(child: content) : content;
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
