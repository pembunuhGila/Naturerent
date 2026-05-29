import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable header "Mitra NatureRent" yang digunakan di semua halaman
/// area Pemilik Rental (Owner). Jangan digunakan di halaman Customer/User.
class OwnerHeaderWidget extends StatelessWidget {
  /// [showBackButton] — tampilkan tombol kembali (untuk halaman bukan tab utama)
  final bool showBackButton;

  /// [trailingWidget] — widget opsional di sisi kanan header
  final Widget? trailingWidget;
  final String title;
  final bool showBrandIcon;
  final EdgeInsetsGeometry padding;

  const OwnerHeaderWidget({
    super.key,
    this.showBackButton = false,
    this.trailingWidget,
    this.title = 'Mitra NatureRent',
    this.showBrandIcon = true,
    this.padding = const EdgeInsets.fromLTRB(32, 28, 24, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (showBackButton) ...[
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.ownerPrimaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (showBrandIcon) ...[
            const Icon(
              Icons.park_rounded,
              color: AppColors.ownerPrimaryGreen,
              size: 24,
            ),
            const SizedBox(width: 7),
          ],
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.ownerPrimaryGreen,
              fontSize: showBrandIcon ? 18 : 21,
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
