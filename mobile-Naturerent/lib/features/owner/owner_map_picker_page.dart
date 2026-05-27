import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';

class OwnerMapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const OwnerMapPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<OwnerMapPickerPage> createState() => _OwnerMapPickerPageState();
}

class _OwnerMapPickerPageState extends State<OwnerMapPickerPage> {
  static const _defaultLat = -7.7956;
  static const _defaultLng = 110.3695;
  static const _defaultZoom = 13.0;
  static const _detailZoom = 16.0;

  late final MapController _mapController;
  late LatLng _selectedPoint;
  bool _loadingGps = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );

    if (widget.initialLat == null || widget.initialLng == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _useCurrentLocation(),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('GPS tidak aktif. Aktifkan lokasi pada perangkat.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError(
          'Izin lokasi ditolak. Anda tetap bisa memilih titik di peta.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Izin lokasi diblokir. Buka pengaturan aplikasi untuk mengizinkan lokasi.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _moveTo(LatLng(position.latitude, position.longitude), _detailZoom);
    } on LocationServiceDisabledException {
      _showError('GPS tidak aktif. Aktifkan lokasi pada perangkat.');
    } catch (_) {
      _showError('Lokasi saat ini belum bisa diambil. Coba lagi sebentar.');
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  void _moveTo(LatLng point, double zoom) {
    if (!mounted) return;
    setState(() => _selectedPoint = point);
    if (_mapReady) _mapController.move(point, zoom);
  }

  void _showError(String message) {
    if (!mounted) return;
    NrToast.show(
      context,
      message,
      type: NrToastType.error,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202321),
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Text(
          'Pilih Titik Lokasi',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF202321),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPoint,
                  initialZoom: widget.initialLat != null
                      ? _detailZoom
                      : _defaultZoom,
                  onMapReady: () => setState(() => _mapReady = true),
                  onTap: (_, point) =>
                      _moveTo(point, _mapController.camera.zoom),
                  onPositionChanged: (camera, hasGesture) {
                    if (!hasGesture) return;
                    setState(() => _selectedPoint = camera.center);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.naturerent.app',
                    maxZoom: 19,
                  ),
                ],
              ),
            ),
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 38),
                  child: _StorePin(),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 14,
              child: _GpsLocationButton(
                loadingGps: _loadingGps,
                onCurrentLocation: _loadingGps ? null : _useCurrentLocation,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      'Lat: ${_selectedPoint.latitude.toStringAsFixed(6)}  |  '
                      'Lng: ${_selectedPoint.longitude.toStringAsFixed(6)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selectedPoint),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Pilih Lokasi Ini',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsLocationButton extends StatelessWidget {
  final bool loadingGps;
  final VoidCallback? onCurrentLocation;

  const _GpsLocationButton({
    required this.loadingGps,
    required this.onCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onCurrentLocation,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loadingGps)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  loadingGps ? 'Mengecek GPS...' : 'Cek Lokasi Sesuai GPS',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _StorePin extends StatelessWidget {
  const _StorePin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
        ),
        CustomPaint(
          size: const Size(18, 12),
          painter: _TrianglePainter(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
