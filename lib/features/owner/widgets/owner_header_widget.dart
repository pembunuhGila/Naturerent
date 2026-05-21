import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable header "Mitra NatureRent" yang digunakan di semua halaman
/// area Pemilik Rental (Owner). Jangan digunakan di halaman Customer/User.
class OwnerHeaderWidget extends StatelessWidget {
  /// [showBackButton] — tampilkan tombol kembali (untuk halaman bukan tab utama)
  final bool showBackButton;

  /// [trailingWidget] — widget opsional di sisi kanan header
  final Widget? trailingWidget;

  const OwnerHeaderWidget({
    super.key,
    this.showBackButton = false,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 24, 0),
      child: Row(
        children: [
          if (showBackButton) ...[
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF116229),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
          ],
          const Icon(
            Icons.park_rounded,
            color: Color(0xFF116229),
            size: 24,
          ),
          const SizedBox(width: 7),
          Text(
            'Mitra NatureRent',
            style: AppTextStyles.headlineMedium.copyWith(
              color: const Color(0xFF116229),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          ?trailingWidget,
        ],
      ),
    );
  }
}
