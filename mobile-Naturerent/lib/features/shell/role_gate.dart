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

        final role =
            snapshot.data ??
            AuthService().penggunaSaatIni?.userMetadata?['role'] as String?;

        if (role == 'rental_owner') return const OwnerShell();
        if (snapshot.hasError || role == null || role == 'customer') {
          return const MainShell();
        }

        return const _UnsupportedRoleLogout();
      },
    );
  }
}

class _UnsupportedRoleLogout extends StatefulWidget {
  const _UnsupportedRoleLogout();

  @override
  State<_UnsupportedRoleLogout> createState() => _UnsupportedRoleLogoutState();
}

class _UnsupportedRoleLogoutState extends State<_UnsupportedRoleLogout> {
  @override
  void initState() {
    super.initState();
    _logout();
  }

  Future<void> _logout() async {
    await AuthService().keluar();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
