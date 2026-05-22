import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/splash/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke portrait saja
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inisialisasi Supabase & layanan auth
  await AuthService.initialize();

  runApp(const NatureRentApp());
}

class NatureRentApp extends StatelessWidget {
  const NatureRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NatureRent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // LoadingScreen tampil pertama, setelah 3 detik navigasi otomatis
      home: const LoadingScreen(),
    );
  }
}
