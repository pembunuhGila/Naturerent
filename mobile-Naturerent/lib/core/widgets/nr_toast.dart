import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum NrToastType { info, success, error }

class NrToast {
  const NrToast._();

  static void show(
    BuildContext context,
    String message, {
    NrToastType type = NrToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final media = MediaQuery.of(context);
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: media.padding.top + 12,
        left: 16,
        right: 16,
        child: SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _color(type),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_icon(type), color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future<void>.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  static Color _color(NrToastType type) {
    return switch (type) {
      NrToastType.success => AppColors.primaryDark,
      NrToastType.error => AppColors.error,
      NrToastType.info => AppColors.textPrimary,
    };
  }

  static IconData _icon(NrToastType type) {
    return switch (type) {
      NrToastType.success => Icons.check_circle_outline_rounded,
      NrToastType.error => Icons.error_outline_rounded,
      NrToastType.info => Icons.info_outline_rounded,
    };
  }
}
