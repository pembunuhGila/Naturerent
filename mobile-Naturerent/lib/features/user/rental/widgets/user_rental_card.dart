import 'package:flutter/material.dart';

import 'package:naturerent/core/models/rental_profile.dart';
import 'package:naturerent/core/services/location_service.dart';
import 'package:naturerent/core/theme/app_theme.dart';
import 'package:naturerent/core/widgets/nr_image.dart';

class UserRentalCard extends StatelessWidget {
  final RentalProfile rental;
  final double? distanceKm;
  final int equipmentCount;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const UserRentalCard({
    super.key,
    required this.rental,
    required this.distanceKm,
    required this.equipmentCount,
    required this.onTap,
    this.margin = EdgeInsets.zero,
  });

  String get _distanceText {
    if (distanceKm == null) return 'Lokasi belum tersedia';
    return LocationService.formatJarak(distanceKm!);
  }

  String get _addressText {
    final text = rental.alamat?.trim();
    if (text == null || text.isEmpty) return 'Alamat belum tersedia';
    return text;
  }

  String get _statusLabel => _isOpenNow ? 'Buka' : 'Aktif';

  bool get _isOpenNow {
    if (!rental.isActive) return false;
    final open = rental.openTime;
    final close = rental.closeTime;
    if (open == null || close == null) return true;

    int parse(String value) {
      final parts = value.split(':');
      if (parts.length != 2) return -1;
      final h = int.tryParse(parts[0]) ?? -1;
      final m = int.tryParse(parts[1]) ?? -1;
      return h < 0 || m < 0 ? -1 : h * 60 + m;
    }

    final now = TimeOfDay.now();
    final current = now.hour * 60 + now.minute;
    final openMinutes = parse(open);
    final closeMinutes = parse(close);
    if (openMinutes < 0 || closeMinutes < 0) return true;
    if (closeMinutes < openMinutes) {
      return current >= openMinutes || current <= closeMinutes;
    }
    return current >= openMinutes && current <= closeMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                ClipOval(
                  child: NrImage(
                    imageUrl: rental.fotoProfil,
                    width: 56,
                    height: 56,
                    placeholderColor: AppColors.primaryDark,
                    placeholderIcon: Icons.storefront_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.namaRental,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _addressText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _distanceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '$equipmentCount alat tersedia',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textHint,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
