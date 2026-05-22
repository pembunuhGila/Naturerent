import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';

/// Halaman peta interaktif untuk memilih titik lokasi rental.
/// Mengembalikan [LatLng] yang dipilih user, atau null jika dibatalkan.
class OwnerMapPickerPage extends StatefulWidget {
  /// Koordinat awal yang ditampilkan saat peta dibuka (opsional).
  final double? initialLat;
  final double? initialLng;

  const OwnerMapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<OwnerMapPickerPage> createState() => _OwnerMapPickerPageState();
}

class _OwnerMapPickerPageState extends State<OwnerMapPickerPage> {
  static const _defaultLat = -7.7956; // Default: Jawa Timur
  static const _defaultLng = 110.3695;
  static const _zoomDefault = 13.0;
  static const _zoomDetail = 15.5;

  late final MapController _mapController;
  late LatLng _markerPos;
  bool _loadingGps = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _markerPos = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );
    // Jika tidak ada koordinat awal, langsung ambil GPS
    if (widget.initialLat == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ambilGps());
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  //  GPS
  // ─────────────────────────────────────────────────────
  Future<void> _ambilGps() async {
    setState(() => _loadingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snackError('GPS tidak aktif. Aktifkan lokasi pada perangkat.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _snackError('Izin lokasi ditolak.');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _snackError(
            'Izin lokasi diblokir. Buka Pengaturan > Aplikasi untuk mengizinkan.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;

      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() => _markerPos = newPos);
      if (_mapReady) {
        _mapController.move(newPos, _zoomDetail);
      }
    } on LocationServiceDisabledException {
      _snackError('GPS tidak aktif.');
    } catch (e) {
      _snackError('Gagal ambil lokasi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  void _snackError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ));
  }

  // ─────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Stack(
        children: [
          // ── PETA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _markerPos,
              initialZoom: widget.initialLat != null ? _zoomDetail : _zoomDefault,
              onMapReady: () => setState(() => _mapReady = true),
              // Tap pada peta → pindahkan marker
              onTap: (_, point) => setState(() => _markerPos = point),
            ),
            children: [
              // Tile layer OpenStreetMap (gratis, tanpa API key)
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.naturerent.app',
                maxZoom: 19,
              ),
              // Marker lokasi yang dipilih
              MarkerLayer(
                markers: [
                  Marker(
                    point: _markerPos,
                    width: 48,
                    height: 64,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF18743A),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(12, 8),
                          painter: _TrianglePainter(
                            color: const Color(0xFF18743A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── TOP BAR (transparan dengan tombol kembali)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Tombol kembali
                  _MapButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Tombol ambil GPS
                  _MapButton(
                    icon: _loadingGps
                        ? null
                        : Icons.my_location_rounded,
                    isLoading: _loadingGps,
                    onTap: _loadingGps ? null : _ambilGps,
                  ),
                ],
              ),
            ),
          ),

          // ── HINT tap peta
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 72),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap pada peta untuk memindahkan titik lokasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── BOTTOM CARD — koordinat + tombol konfirmasi
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label lokasi dipilih
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF18743A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Titik Lokasi Dipilih',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: const Color(0xFF202321),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Koordinat
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E5DE)),
                    ),
                    child: Text(
                      'Lat: ${_markerPos.latitude.toStringAsFixed(6)}'
                      '   •   '
                      'Lng: ${_markerPos.longitude.toStringAsFixed(6)}',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF18743A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tombol konfirmasi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _markerPos),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18743A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        'GUNAKAN LOKASI INI',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
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
}

// ─────────────────────────────────────────────────────────────
//  Helper Widgets
// ─────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _MapButton({
    this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF18743A),
                  ),
                )
              : Icon(icon, color: const Color(0xFF18743A), size: 22),
        ),
      ),
    );
  }
}

/// Painter segitiga kecil di bawah ikon marker agar tampak seperti pin.
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
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
