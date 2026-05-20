import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../auth/onboarding_page.dart';
import '../shell/role_gate.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    Future.delayed(const Duration(seconds: 3), _navigasiBerikutnya);
  }

  void _navigasiBerikutnya() {
    if (!mounted) return;

    final sudahLogin = AuthService().sudahMasuk;
    final halamanTujuan = sudahLogin
        ? const RoleGate()
        : const OnboardingPage();

    if (sudahLogin) {
      AuthService().syncProfilSetelahLogin();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => halamanTujuan,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/loading_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
