import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/rental_profile.dart';
import '../../core/services/cart_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';

class ReturnDetailPage extends StatelessWidget {
  final RentalProfile rental;
  final List<CartItem> items;
  final DateTime returnDate;
  final String statusLabel;

  const ReturnDetailPage({
    super.key,
    required this.rental,
    required this.items,
    required this.returnDate,
    required this.statusLabel,
  });

  bool get _hasLocation => rental.lat != null && rental.lng != null;

  String get _ownerName =>
      _firstValue([rental.ownerName, rental.qrisMerchantName]) ??
      'Pemilik belum tersedia';

  String get _phone =>
      _firstValue([rental.noWa, rental.ownerPhone]) ??
      'Nomor pemilik belum tersedia';

  String get _address => rental.alamat ?? 'Alamat toko belum tersedia';

  String get _hours =>
      rental.operationalHours ?? 'Jam operasional belum tersedia';

  int get _itemCount => items.fold<int>(0, (sum, item) => sum + item.qty);

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _buildAppBar(context),
            const SizedBox(height: 18),
            _buildHeader(),
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Informasi Pengembalian',
              children: [
                _InfoTile(
                  icon: Icons.storefront_rounded,
                  label: 'Toko Rental',
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
                  icon: Icons.schedule_rounded,
                  label: 'Jam Operasional',
                  value: _hours,
                ),
                _InfoTile(
                  icon: Icons.place_outlined,
                  label: 'Alamat',
                  value: _address,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMapSection(context),
            const SizedBox(height: 16),
            _buildNotes(),
            const SizedBox(height: 18),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Detail Pengembalian',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_return_rounded,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengembalian Barang',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$statusLabel - $_itemCount item dikembalikan paling lambat ${_fmtTgl(returnDate)}.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return _InfoSection(
      title: 'Lokasi Toko Rental',
      children: [
        if (_hasLocation)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReturnMapPage(rental: rental)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 210,
                child: _ReturnMapPreview(rental: rental),
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
              'Lokasi pengembalian belum tersedia',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pastikan semua peralatan dikembalikan dalam kondisi lengkap dan sesuai waktu pengembalian. Pemilik rental akan mengonfirmasi setelah barang diterima.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _hasLocation ? _openExternalMaps : null,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Buka di Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.textHint.withValues(
                alpha: 0.25,
              ),
              disabledForegroundColor: AppColors.textHint,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _contactOwner(context),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Hubungi Pemilik'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openExternalMaps() async {
    if (!_hasLocation) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${rental.lat},${rental.lng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _contactOwner(BuildContext context) async {
    final phone = _firstValue([rental.noWa, rental.ownerPhone]);
    if (phone == null) {
      NrToast.show(
        context,
        'Nomor pemilik rental belum tersedia',
        type: NrToastType.info,
      );
      return;
    }

    final normalized = _normalizePhone(phone);
    final message = Uri.encodeComponent(
      'Halo, saya ingin mengembalikan peralatan rental di ${rental.namaRental}.',
    );
    final uri = Uri.parse('https://wa.me/$normalized?text=$message');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      NrToast.show(
        context,
        'WhatsApp belum bisa dibuka.',
        type: NrToastType.info,
      );
    }
  }
}

class ReturnMapPage extends StatelessWidget {
  final RentalProfile rental;

  const ReturnMapPage({super.key, required this.rental});

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
              MarkerLayer(markers: [_storeMarker(_point)]),
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
        ],
      ),
    );
  }
}

class _ReturnMapPreview extends StatelessWidget {
  final RentalProfile rental;

  const _ReturnMapPreview({required this.rental});

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
        MarkerLayer(markers: [_storeMarker(point)]),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
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

Marker _storeMarker(LatLng point) {
  return Marker(
    point: point,
    width: 50,
    height: 50,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: Colors.white,
        size: 22,
      ),
    ),
  );
}

String _fmtTgl(DateTime dt) {
  const b = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${dt.day} ${b[dt.month]} ${dt.year}';
}

String _normalizePhone(String phone) {
  var normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized.startsWith('+')) normalized = normalized.substring(1);
  if (normalized.startsWith('0')) {
    normalized = '62${normalized.substring(1)}';
  }
  return normalized;
}

String? _firstValue(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
