import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_button.dart';
import '../../core/widgets/nr_logo.dart';
import 'login_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Content scrollable area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // ── Logo
                    const NrLogo(),

                    const SizedBox(height: 28),

                    // ── Hero Image Placeholder
                    _buildHeroImage(),

                    const SizedBox(height: 32),

                    // ── Headline
                    Text(
                      'Selamat Datang di\nNatureRent',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Subtitle
                    Text(
                      'Petualangan dimulai di sini. Pilih peran\nAnda untuk melanjutkan perjalanan di\nalam terbuka.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge,
                    ),

                    const SizedBox(height: 40),

                    // ── Masuk sebagai Penyewa
                    NrButton(
                      text: 'Masuk sebagai Penyewa',
                      style: NrButtonStyle.filled,
                      onPressed: () {
                        Navigator.push(
                          context,
                          _fadeRoute(const LoginPage(role: UserRole.penyewa)),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // ── Masuk sebagai Pemilik Rental
                    NrButton(
                      text: 'Masuk sebagai Pemilik Rental',
                      style: NrButtonStyle.outlined,
                      onPressed: () {
                        Navigator.push(
                          context,
                          _fadeRoute(const LoginPage(role: UserRole.pemilik)),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Hero image placeholder (kosong — bisa diganti dengan Image.asset)
  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/halaman_awal.jpeg',
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        children: [
          Text(
            '© 2026 NATURERENT THE QUIET TRAIL.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerLink('PRIVACY'),
              const SizedBox(width: 16),
              _footerLink('TERMS'),
              const SizedBox(width: 16),
              _footerLink('CONTACT'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textHint,
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// ── Role enum (shared across pages)
enum UserRole { penyewa, pemilik }
