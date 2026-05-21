import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import 'owner_destination_data.dart';
import 'owner_map_picker_page.dart';

class OwnerEditRentalPage extends StatefulWidget {
  /// Profil rental yang akan diedit. Boleh null jika rental belum dibuat.
  final RentalProfile? rentalProfile;

  const OwnerEditRentalPage({super.key, this.rentalProfile});

  @override
  State<OwnerEditRentalPage> createState() => _OwnerEditRentalPageState();
}

class _OwnerEditRentalPageState extends State<OwnerEditRentalPage> {
  late final TextEditingController _namaRentalController;
  late final TextEditingController _alamatController;

  final Set<String> _nearbyTitles = {'Ranu Kumbolo', 'Gunung Semeru'};
  final Set<String> _selected = {'Ranu Kumbolo', 'Gunung Semeru'};
  final _rentalService = RentalService();

  // ── State GPS
  double? _lat;
  double? _lng;
  bool _loadingGps = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rental = widget.rentalProfile;
    _namaRentalController = TextEditingController(
      text: rental?.namaRental ?? 'Rimba Basecamp',
    );
    _alamatController = TextEditingController(
      text: rental?.alamat ??
          'Kaki Gunung Semeru, Desa Ranupani, Senduro, Lumajang, Jawa Timur',
    );
    // Muat koordinat yang sudah tersimpan sebelumnya
    _lat = rental?.lat;
    _lng = rental?.lng;
  }

  @override
  void dispose() {
    _namaRentalController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  //  GPS Logic
  // ─────────────────────────────────────────────────────

  /// Buka map picker — user bisa tap peta atau gunakan GPS di dalam map picker.
  Future<void> _ambilLokasiGps() async {
    setState(() => _loadingGps = true);

    // Minta permission dulu sebelum buka peta
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snackError('GPS tidak aktif. Aktifkan lokasi pada perangkat.');
        setState(() => _loadingGps = false);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _snackError('Izin lokasi ditolak.');
          setState(() => _loadingGps = false);
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _snackError('Izin lokasi diblokir. Buka Pengaturan > Aplikasi.');
        setState(() => _loadingGps = false);
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loadingGps = false);

    // Buka halaman map picker
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerMapPickerPage(
          initialLat: _lat,
          initialLng: _lng,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
      _snackSuccess(
        'Lokasi disimpan: ${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}',
      );
    }
  }

  // ─────────────────────────────────────────────────────
  //  Save Logic
  // ─────────────────────────────────────────────────────

  Future<void> _save() async {
    final namaRental = _namaRentalController.text.trim();
    final alamat = _alamatController.text.trim();

    if (namaRental.isEmpty) {
      _snackError('Nama rental tidak boleh kosong.');
      return;
    }

    // Jika belum ada rentalId, tidak bisa simpan ke backend
    final rentalId = widget.rentalProfile?.id;
    if (rentalId == null) {
      // Fallback: tampilkan snackbar saja (rental belum dibuat)
      _snackSuccess('Perubahan detail rental tersimpan (lokal).');
      Navigator.pop(context, true);
      return;
    }

    setState(() => _saving = true);
    try {
      await _rentalService.perbaruiDetailRental(
        rentalId: rentalId,
        namaRental: namaRental,
        alamat: alamat.isEmpty ? null : alamat,
        lat: _lat,
        lng: _lng,
      );

      if (!mounted) return;
      _snackSuccess('Perubahan detail rental berhasil disimpan.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snackError('Gagal menyimpan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────────────────────────────────
  //  Snackbar Helpers
  // ─────────────────────────────────────────────────────

  void _snackSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF123E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _snackError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(38, 26, 20, 120),
                children: [
                  Text(
                    'Ubah Detail Base\nCamp',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: const Color(0xFF202321),
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Perbarui informasi rental Anda agar\ntetap relevan bagi para petualang.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF757D73),
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _IdentityCard(controller: _namaRentalController),
                  const SizedBox(height: 22),
                  _LocationCard(
                    controller: _alamatController,
                    lat: _lat,
                    lng: _lng,
                    loadingGps: _loadingGps,
                    onAmbilGps: _ambilLokasiGps,
                  ),
                  const SizedBox(height: 54),
                  Text(
                    'Dekat dari Lokasimu',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: const Color(0xFF263229),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...ownerCandidateDestinations.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _DestinationCard(
                        item: item,
                        selected: _selected.contains(item.title),
                        disabled: _nearbyTitles.contains(item.title),
                        onTap: () {
                          if (_nearbyTitles.contains(item.title)) {
                            _snackSuccess(
                              '${item.title} sudah ada di destinasi terdekat.',
                            );
                            return;
                          }
                          setState(() {
                            if (_selected.contains(item.title)) {
                              _selected.remove(item.title);
                            } else {
                              _selected.add(item.title);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFF8F8F5),
        padding: EdgeInsets.fromLTRB(
          38,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: (_saving || _loadingGps) ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF123E1E),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF123E1E).withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'SIMPAN PERUBAHAN',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF263229),
              size: 24,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Ubah Detail Rental',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF263229),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Section Cards
// ─────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final TextEditingController controller;
  const _IdentityCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _EditSectionCard(
      title: 'Identitas Rental',
      subtitle: 'Nama ini akan muncul pada hasil\npencarian dan halaman utama.',
      child: _LabeledInput(
        label: 'NAMA TEMPAT RENTAL',
        controller: controller,
        maxLines: 1,
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final TextEditingController controller;
  final double? lat;
  final double? lng;
  final bool loadingGps;
  final VoidCallback onAmbilGps;

  const _LocationCard({
    required this.controller,
    required this.lat,
    required this.lng,
    required this.loadingGps,
    required this.onAmbilGps,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = lat != null && lng != null;

    return _EditSectionCard(
      title: 'Lokasi & Alamat',
      subtitle: 'Pastikan titik GPS akurat agar penyewa\ntidak tersesat.',
      child: Column(
        children: [
          // ── Area peta / placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: Stack(
                children: [
                  // ── Peta interaktif (read-only preview) jika ada koordinat
                  if (hasLocation)
                    AbsorbPointer(
                      // Nonaktifkan interaksi agar scroll halaman tidak terganggu
                      absorbing: false,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat!, lng!),
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none, // preview saja
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.naturerent.app',
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat!, lng!),
                                width: 48,
                                height: 60,
                                alignment: Alignment.topCenter,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF123E1E),
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
                                        color: const Color(0xFF123E1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // ── Placeholder sebelum ada koordinat
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/loading_background.png',
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                color: Colors.white70,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Titik lokasi belum dipilih',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ketuk tombol di bawah untuk buka peta',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // ── Tombol "Buka Peta / GPS" — selalu di pojok kanan bawah
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: loadingGps ? null : onAmbilGps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (loadingGps)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF123E1E),
                                ),
                              )
                            else
                              const Icon(
                                Icons.map_rounded,
                                color: Color(0xFF123E1E),
                                size: 15,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              loadingGps
                                  ? 'Membuka...'
                                  : hasLocation
                                      ? 'Ubah di Peta'
                                      : 'Buka Peta GPS',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF123E1E),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tampilkan koordinat jika sudah ada
          if (hasLocation) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF5EB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA8D5A2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF1A6B30),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${lat!.toStringAsFixed(6)}  •  Lng: ${lng!.toStringAsFixed(6)}',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF1A6B30),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          _LabeledInput(
            label: 'ALAMAT LENGKAP',
            controller: controller,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

// Painter segitiga untuk marker pin (shared dengan map picker)
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


// ─────────────────────────────────────────────────────────────
//  Shared Widgets
// ─────────────────────────────────────────────────────────────

class _EditSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _EditSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEAEDE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: const Color(0xFF303B32),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF7F877E),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 34),
          child,
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF798076),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF384036),
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F0ED),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF123E1E)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final DestinationInfo item;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.item,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 178,
            decoration: BoxDecoration(
              color: disabled ? item.color.withValues(alpha: 0.74) : item.color,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Icon(item.icon, color: Colors.white, size: 72),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFF337F52),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '4.9',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF8F968E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: const Color(0xFF202321),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFB4BBB2),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.detailDistance,
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFB4BBB2),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: disabled
                        ? const Color(0xFFEAEAE7)
                        : const Color(0xFF337F52),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    disabled
                        ? Icons.check_rounded
                        : selected
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    color: disabled ? const Color(0xFFB7BDB5) : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
