import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/rental_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_image.dart';

class RentalDetailPage extends StatelessWidget {
  final RentalProfile rental;

  const RentalDetailPage({super.key, required this.rental});

  bool get _hasLocation => rental.lat != null && rental.lng != null;

  String get _ownerName =>
      _firstValue([rental.ownerName, rental.qrisMerchantName]) ??
      'Pemilik belum tersedia';

  String get _phone =>
      _firstValue([rental.noWa, rental.ownerPhone]) ??
      'Nomor telepon belum tersedia';

  String get _email => rental.ownerEmail ?? 'Email belum tersedia';

  String get _address => rental.alamat ?? 'Alamat toko belum tersedia';

  _OperationalHours get _hours => _OperationalHours.fromRental(rental);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context)),
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(
              child: _Section(
                title: 'Informasi Toko',
                children: [
                  _InfoTile(
                    icon: Icons.storefront_rounded,
                    label: 'Nama Toko Rental',
                    value: rental.namaRental,
                  ),
                  _InfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Pemilik Rental',
                    value: _ownerName,
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon',
                    value: _phone,
                  ),
                  _InfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: _email,
                  ),
                  _InfoTile(
                    icon: Icons.place_outlined,
                    label: 'Alamat',
                    value: _address,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(child: _buildOperationalHours()),
            SliverToBoxAdapter(child: _buildLocationSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Detail Toko Rental',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                NrImage(
                  imageUrl: rental.fotoBanner,
                  width: double.infinity,
                  height: 176,
                  fit: BoxFit.cover,
                  placeholderColor: AppColors.primaryDark,
                  placeholderIcon: Icons.landscape_rounded,
                ),
                Positioned(
                  left: 16,
                  bottom: -28,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: NrImage(
                      imageUrl: rental.fotoProfil,
                      width: 72,
                      height: 72,
                      borderRadius: BorderRadius.circular(16),
                      placeholderColor: AppColors.primaryDark,
                      placeholderIcon: Icons.storefront_rounded,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalHours() {
    return _Section(
      title: 'Jam Operasional',
      children: [
        _InfoTile(
          icon: Icons.schedule_rounded,
          label: _hours.hasRange ? 'Jam Operasional' : 'Keterangan',
          value: _hours.displayText,
        ),
        if (_hours.hasRange)
          _StatusPill(hours: _hours, isActive: rental.isActive),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return _Section(
      title: 'Lokasi Toko Rental',
      children: [
        Column(
          children: [
            if (_hasLocation)
              GestureDetector(
                onTap: () => _openMap(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 200,
                    child: _RentalMapPreview(rental: rental),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Lokasi toko belum tersedia',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _hasLocation ? () => _openMap(context) : null,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Lihat Lokasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.textHint.withValues(
                    alpha: 0.25,
                  ),
                  disabledForegroundColor: AppColors.textHint,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openMap(BuildContext context) {
    if (!_hasLocation) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RentalMapPage(rental: rental)),
    );
  }
}

class RentalMapPage extends StatelessWidget {
  final RentalProfile rental;

  const RentalMapPage({super.key, required this.rental});

  LatLng get _point => LatLng(rental.lat!, rental.lng!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 15,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.naturerent.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _point,
                    width: 54,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _MapButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      rental.namaRental,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 18,
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openExternalMaps,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Buka di Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${rental.lat},${rental.lng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _RentalMapPreview extends StatelessWidget {
  final RentalProfile rental;

  const _RentalMapPreview({required this.rental});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(rental.lat!, rental.lng!);
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.naturerent.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _OperationalHours hours;
  final bool isActive;

  const _StatusPill({required this.hours, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final open = isActive && hours.isOpenNow;
    final text = !isActive ? 'Tidak Aktif' : hours.statusText;
    final color = open ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

class _OperationalHours {
  final String? openTime;
  final String? closeTime;
  final String? rawText;

  const _OperationalHours({this.openTime, this.closeTime, this.rawText});

  bool get hasRange => openTime != null && closeTime != null;

  String get displayText {
    if (hasRange) return '$openTime - $closeTime WIB';
    return rawText ?? 'Jam operasional belum tersedia';
  }

  bool get isOpenNow {
    if (!hasRange) return false;
    final open = _parseMinutes(openTime!);
    final close = _parseMinutes(closeTime!);
    if (open == null || close == null) return false;

    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    if (open <= close) return current >= open && current <= close;
    return current >= open || current <= close;
  }

  String get statusText {
    if (!hasRange) return 'Jam belum tersedia';
    return isOpenNow ? 'Buka Sekarang' : 'Tutup';
  }

  static _OperationalHours fromRental(RentalProfile rental) {
    final raw = rental.settings?['jam_operasional'];
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = _fromText(raw);
      if (parsed != null) return parsed;
      return _OperationalHours(rawText: raw);
    }
    if (raw is Map) {
      final open = _readTime(raw, [
        'buka',
        'open',
        'open_time',
        'start',
        'from',
        'jam_buka',
      ]);
      final close = _readTime(raw, [
        'tutup',
        'close',
        'close_time',
        'end',
        'to',
        'jam_tutup',
      ]);
      if (open != null && close != null) {
        return _OperationalHours(openTime: open, closeTime: close);
      }
      final text = _firstValue([
        raw['label']?.toString(),
        raw['text']?.toString(),
        raw['operational_hours']?.toString(),
        raw['jam_operasional']?.toString(),
      ]);
      if (text != null) return _OperationalHours(rawText: text);
    }
    return const _OperationalHours();
  }

  static _OperationalHours? _fromText(String text) {
    final match = RegExp(
      r'(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})',
    ).firstMatch(text);
    if (match == null) return null;
    return _OperationalHours(
      openTime: _normalizeTime(match.group(1)!),
      closeTime: _normalizeTime(match.group(2)!),
    );
  }

  static String? _readTime(Map raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final normalized = _normalizeTime(value.toString());
      if (normalized != null) return normalized;
    }
    return null;
  }

  static String? _normalizeTime(String value) {
    final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(value);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static int? _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}

String? _firstValue(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
