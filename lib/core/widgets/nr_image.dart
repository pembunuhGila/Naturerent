import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget untuk menampilkan gambar dari URL Supabase Storage.
/// Jika [imageUrl] null/kosong → tampilkan placeholder bertema NatureRent.
/// Jika URL ada tapi gagal load → tampilkan error placeholder.
class NrImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final IconData placeholderIcon;

  const NrImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor = AppColors.primaryDark,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = (imageUrl == null || imageUrl!.isEmpty)
        ? _buildPlaceholder()
        : Image.network(
            imageUrl!,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return _buildLoading();
            },
            errorBuilder: (_, __, ___) => _buildPlaceholder(isError: true),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildPlaceholder({bool isError = false}) {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.broken_image_outlined : placeholderIcon,
              size: 36,
              color: Colors.white24,
            ),
            const SizedBox(height: 6),
            Text(
              isError ? 'Gambar gagal dimuat' : 'Belum ada foto',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white30,
        ),
      ),
    );
  }
}
