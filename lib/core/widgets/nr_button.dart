import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NrButtonStyle { filled, outlined }

class NrButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final NrButtonStyle style;
  final bool isLoading;
  final Widget? prefixIcon;
  final double? width;

  const NrButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = NrButtonStyle.filled,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = style == NrButtonStyle.filled;

    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: isFilled
            ? ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.primaryLight.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _buildChild(isFilled),
              )
            : OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _buildChild(isFilled),
              ),
      ),
    );
  }

  Widget _buildChild(bool isFilled) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isFilled ? AppColors.white : AppColors.primary,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          prefixIcon!,
          const SizedBox(width: 10),
        ],
        Text(
          text,
          style: isFilled
              ? AppTextStyles.labelLarge
              : AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
