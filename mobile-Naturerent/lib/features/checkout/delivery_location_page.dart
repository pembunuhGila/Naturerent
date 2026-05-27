import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/cart_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';

class DeliveryFeeDetail {
  final String rentalId;
  final String rentalName;
  final double distanceKm;
  final double fee;

  const DeliveryFeeDetail({
    required this.rentalId,
    required this.rentalName,
    required this.distanceKm,
    required this.fee,
  });
}

class DeliveryLocationResult {
  final LatLng userLocation;
  final List<DeliveryFeeDetail> details;

  const DeliveryLocationResult({
    required this.userLocation,
    required this.details,
  });

  double get totalDistanceKm =>
      details.fold(0.0, (sum, detail) => sum + detail.distanceKm);

  double get totalFee => details.fold(0.0, (sum, detail) => sum + detail.fee);

  Map<String, double> get feesByRentalId => {
        for (final detail in details) detail.rentalId: detail.fee,
      };
}

class DeliveryLocationPage extends StatefulWidget {
  final List<CartRentalGroup> groups;

  const DeliveryLocationPage({
    super.key,
    required this.groups,
  });

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  static const _defaultLat = -7.9666;
  static const _defaultLng = 112.6326;
  static const _freeDistanceKm = 5.0;
  static const _feePerKm = 2000.0;

  late final MapController _mapController;
  late LatLng _userLocation;
  bool _loadingGps = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _userLocation = _initialCenter();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ambilLokasiSaya());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _initialCenter() {
    for (final group in widget.groups) {
      final rental = group.rental;
      if (rental.lat != null && rental.lng != null) {
        return LatLng(rental.lat!, rental.lng!);
      }
    }
    return LatLng(_defaultLat, _defaultLng);
  }

  bool get _allRentalHasLocation => widget.groups.every(
        (group) => group.rental.lat != null && group.rental.lng != null,
      );

  List<DeliveryFeeDetail> get _details {
    return widget.groups.map((group) {
      final rental = group.rental;
      final distanceKm = rental.lat == null || rental.lng == null
          ? 0.0
          : Geolocator.distanceBetween(
                rental.lat!,
                rental.lng!,
                _userLocation.latitude,
                _userLocation.longitude,
              ) /
              1000;
      final feeableKm = distanceKm <= _freeDistanceKm
          ? 0.0
          : distanceKm - _freeDistanceKm;
      return DeliveryFeeDetail(
        rentalId: rental.id,
        rentalName: rental.namaRental,
        distanceKm: distanceKm,
        fee: feeableKm.ceil() * _feePerKm,
      );
    }).toList(growable: false);
  }

  double get _totalFee => _details.fold(0.0, (sum, detail) => sum + detail.fee);

  Future<void> _ambilLokasiSaya() async {
    setState(() => _loadingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('GPS belum aktif. Aktifkan lokasi dulu.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showError('Izin lokasi ditolak.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Izin lokasi diblokir. Buka pengaturan aplikasi.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLocation = point);
      if (_mapReady) _mapController.move(point, 14);
    } catch (e) {
      _showError('Lokasi gagal dibaca. Kamu bisa tap peta manual.');
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    NrToast.show(context, message, type: NrToastType.error);
  }

  void _lanjut() {
    if (!_allRentalHasLocation) {
      _showError('Ada toko rental yang belum punya titik lokasi.');
      return;
    }
    Navigator.pop(
      context,
      DeliveryLocationResult(
        userLocation: _userLocation,
        details: _details,
      ),
    );
  }

  String _fmtRupiah(double value) {
    final s = value.toInt().toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _fmtKm(double value) => '${value.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final details = _details;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 13,
              onMapReady: () => setState(() => _mapReady = true),
              onTap: (_, point) => setState(() => _userLocation = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.naturerent.app',
                maxZoom: 19,
              ),
              MarkerLayer(markers: _markers()),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _MapButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _MapButton(
                    icon: _loadingGps ? null : Icons.my_location_rounded,
                    isLoading: _loadingGps,
                    onTap: _loadingGps ? null : _ambilLokasiSaya,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cek Lokasi Delivery',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Text(
                        _fmtRupiah(_totalFee),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap peta untuk menyesuaikan titik tujuan. Dalam 5 km pertama gratis, setelah itu ongkir Rp 2.000/km per toko.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...details.map(_buildDetailRow),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _lanjut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'LANJUT PEMBAYARAN',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _markers() {
    final markers = <Marker>[
      Marker(
        point: _userLocation,
        width: 54,
        height: 54,
        child: _MapMarker(
          color: AppColors.primaryDark,
          icon: Icons.person_pin_circle_rounded,
        ),
      ),
    ];

    for (final group in widget.groups) {
      final rental = group.rental;
      if (rental.lat == null || rental.lng == null) continue;
      markers.add(
        Marker(
          point: LatLng(rental.lat!, rental.lng!),
          width: 54,
          height: 54,
          child: _MapMarker(
            color: AppColors.success,
            icon: Icons.storefront_rounded,
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildDetailRow(DeliveryFeeDetail detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail.rentalName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_fmtKm(detail.distanceKm)} - ${_fmtRupiah(detail.fee)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _MapMarker({
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}
