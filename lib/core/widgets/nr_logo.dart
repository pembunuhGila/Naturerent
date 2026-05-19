import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NrLogo extends StatelessWidget {
  final Color color;
  final double fontSize;
  final double iconSize;

  const NrLogo({
    super.key,
    this.color = AppColors.primary,
    this.fontSize = 18,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.park_rounded,
          color: color,
          size: iconSize,
        ),
        const SizedBox(width: 8),
        Text(
          'NATURERENT',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
