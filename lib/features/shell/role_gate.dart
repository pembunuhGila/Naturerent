import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/onboarding_page.dart';
import '../owner/owner_shell.dart';
import 'main_shell.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService().sudahMasuk) return const OnboardingPage();

    return FutureBuilder<String?>(
      future: AuthService().ambilRolePengguna(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final role = snapshot.data;
        if (role == 'rental_owner') return const OwnerShell();
        return const MainShell();
      },
    );
  }
}
