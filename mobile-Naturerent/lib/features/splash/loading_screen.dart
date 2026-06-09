import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:naturerent/core/theme/app_theme.dart';
import 'package:naturerent/core/services/auth_service.dart';
import 'package:naturerent/features/user/auth/onboarding_page.dart';
import 'package:naturerent/features/user/auth/reset_password_page.dart';
import 'package:naturerent/features/user/auth/role_gate.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  StreamSubscription? _authSub;
  bool _handlingPasswordRecovery = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _authSub = AuthService().perubahanStatusAuth.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        _handlingPasswordRecovery = true;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ResetPasswordPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 3), _navigasiBerikutnya);
  }

  Future<void> _navigasiBerikutnya() async {
    if (!mounted) return;
    if (_handlingPasswordRecovery) return;

    final sudahLogin = AuthService().sudahMasuk;

    if (sudahLogin) {
      await AuthService().pastikanProfilPenggunaAda();
      await AuthService().syncProfilSetelahLogin();
    }

    if (!mounted) return;
    final halamanTujuan = sudahLogin
        ? const RoleGate()
        : const OnboardingPage();

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
    _authSub?.cancel();
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
