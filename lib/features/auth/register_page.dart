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

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
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
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
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

  void _handleRegister() async {
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
        // Email konfirmasi OFF → langsung masuk ke MainShell
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else if (response.user != null) {
        // Email konfirmasi ON → minta user cek inbox
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

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('user already registered') ||
        msg.contains('email already in use') ||
        msg.contains('already been registered') ||
        msg.contains('already registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (msg.contains('password should be at least') ||
        msg.contains('password is too short') ||
        msg.contains('weak password')) {
      return 'Kata sandi terlalu lemah. Minimal 8 karakter dengan simbol.';
    }
    if (msg.contains('invalid email') || msg.contains('unable to validate email')) {
      return 'Format email tidak valid.';
    }
    if (msg.contains('email rate limit') || msg.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'Gagal terhubung ke server. Periksa koneksi internetmu.';
    }
    // Tampilkan pesan asli dari Supabase agar mudah di-debug
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
        icon: const Icon(Icons.mark_email_read_outlined,
            color: AppColors.primary, size: 48),
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
              // Kembali ke Onboarding / Login
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Hero Header
          _buildHeader(context),

          // ── Form
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title
                        Text('Daftar Akun', style: AppTextStyles.displayMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Bergabunglah dengan komunitas pecinta alam\nkami dan dapatkan akses ke peralatan teknis terbaik.',
                          style: AppTextStyles.bodyMedium,
                        ),

                        const SizedBox(height: 28),

                        // ── Nama Lengkap
                        NrTextField(
                          label: 'Nama Lengkap',
                          hint: 'Rachmad Zaki Setyawan',
                          controller: _namaController,
                          keyboardType: TextInputType.name,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Nama lengkap wajib diisi';
                            if (v.length < 3) return 'Nama terlalu pendek';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Email
                        NrTextField(
                          label: 'Alamat Email',
                          hint: 'zakiganteng507@gmail.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email wajib diisi';
                            if (!v.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Nomor HP
                        NrTextField(
                          label: 'Nomor HP',
                          hint: '+62 821 9442 1152',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Nomor HP wajib diisi';
                            if (v.length < 9) return 'Nomor HP tidak valid';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Password
                        NrTextField(
                          label: 'Kata Sandi',
                          hint: '••••••••',
                          controller: _passwordController,
                          isPassword: true,
                          helperText: 'Minimal 8 karakter dengan satu simbol spesial.',
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                            if (v.length < 8) return 'Minimal 8 karakter';
                            final hasSymbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v);
                            if (!hasSymbol) return 'Harus mengandung simbol spesial';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Terms checkbox
                        _buildTermsCheckbox(),

                        const SizedBox(height: 28),

                        // ── Register button
                        NrButton(
                          text: 'Selesaikan Pendaftaran',
                          isLoading: _isLoading,
                          onPressed: _handleRegister,
                        ),

                        const SizedBox(height: 20),

                        // ── Already have account
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

                        // ── Divider
                        _buildDivider(),

                        const SizedBox(height: 20),

                        // ── Social buttons
                        _buildSocialButtons(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // ── Image placeholder
        Container(
          width: double.infinity,
          height: 200,
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 40, color: Colors.white38),
                SizedBox(height: 6),
                Text(
                  'Tambahkan gambar di sini',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // ── Gradient bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),

        // ── Close / Back button
        Positioned(
          top: 40,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),

        // ── Logo
        Positioned(
          top: 44,
          left: 0,
          right: 0,
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.park_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'NatureRent',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ATAU DAFTAR DENGAN', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Apple',
            icon: Icons.apple_rounded,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: AppColors.textPrimary),
      label: Text(label, style: AppTextStyles.labelMedium),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
