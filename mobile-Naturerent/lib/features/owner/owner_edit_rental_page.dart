import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/rental_profile.dart';
import '../../core/models/wisata_location.dart';
import '../../core/services/destination_suggestion_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';
import 'owner_destination_data.dart';
import 'owner_map_picker_page.dart';

class OwnerEditRentalPage extends StatefulWidget {
  /// Profil rental yang akan diedit. Boleh null jika rental belum dibuat.
  final RentalProfile? rentalProfile;
  final List<DestinationInfo> suggestedDestinations;

  const OwnerEditRentalPage({
    super.key,
    this.rentalProfile,
    this.suggestedDestinations = const [],
  });

  @override
  State<OwnerEditRentalPage> createState() => _OwnerEditRentalPageState();
}

class _OwnerEditRentalPageState extends State<OwnerEditRentalPage> {
  late final TextEditingController _namaRentalController;
  late final TextEditingController _alamatController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  final _rentalService = RentalService();
  final _destinationSuggestionService = DestinationSuggestionService();
  late List<DestinationInfo> _suggestedDestinations;
  List<DestinationInfo> _nearbyDestinations = [];
  final Set<String> _removedDestinationKeys = {};
  bool _loadingDestinations = true;
  String? _destinationMessage;

  // ── State GPS
  double? _lat;
  double? _lng;
  TimeOfDay? _jamBuka;
  TimeOfDay? _jamTutup;
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
      text:
          rental?.alamat ??
          'Kaki Gunung Semeru, Desa Ranupani, Senduro, Lumajang, Jawa Timur',
    );
    // Muat koordinat yang sudah tersimpan sebelumnya
    _lat = rental?.lat;
    _lng = rental?.lng;
    _latitudeController = TextEditingController(text: _formatCoordinate(_lat));
    _longitudeController = TextEditingController(text: _formatCoordinate(_lng));
    _jamBuka = _timeOfDayFromText(rental?.openTime);
    _jamTutup = _timeOfDayFromText(rental?.closeTime);
    _suggestedDestinations = _uniqueDestinations(
      widget.suggestedDestinations,
    );
    _muatDestinasiDekat();
  }

  @override
  void dispose() {
    _namaRentalController.dispose();
    _alamatController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  //  GPS Logic
  // ─────────────────────────────────────────────────────

  Future<void> _cekLokasiGps() async {
    setState(() => _loadingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snackError('GPS tidak aktif. Aktifkan lokasi pada perangkat.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _snackError('Izin lokasi ditolak. Anda tetap bisa memilih dari maps.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _snackError(
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
      if (!mounted) return;
      _setKoordinat(
        position.latitude,
        position.longitude,
        message:
            'Lokasi GPS diterapkan: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      );
    } on LocationServiceDisabledException {
      _snackError('GPS tidak aktif. Aktifkan lokasi pada perangkat.');
    } catch (_) {
      _snackError('Lokasi saat ini belum bisa diambil. Coba lagi sebentar.');
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  /// Buka map picker — user bisa tap peta atau gunakan GPS di dalam map picker.
  Future<void> _pilihLokasiDariMaps() async {
    setState(() => _loadingGps = true);

    // Buka halaman map picker
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerMapPickerPage(initialLat: _lat, initialLng: _lng),
        fullscreenDialog: true,
      ),
    );
    if (mounted) setState(() => _loadingGps = false);

    if (result != null && mounted) {
      _setKoordinat(
        result.latitude,
        result.longitude,
        message:
            'Lokasi maps diterapkan: ${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}',
      );
    }
  }

  void _terapkanKoordinatManual() {
    final latText = _latitudeController.text.trim().replaceAll(',', '.');
    final lngText = _longitudeController.text.trim().replaceAll(',', '.');
    final lat = double.tryParse(latText);
    final lng = double.tryParse(lngText);

    if (lat == null) {
      _snackError('Latitude harus berupa angka.');
      return;
    }
    if (lng == null) {
      _snackError('Longitude harus berupa angka.');
      return;
    }
    if (lat < -90 || lat > 90) {
      _snackError('Latitude harus berada di rentang -90 sampai 90.');
      return;
    }
    if (lng < -180 || lng > 180) {
      _snackError('Longitude harus berada di rentang -180 sampai 180.');
      return;
    }

    _setKoordinat(
      lat,
      lng,
      message:
          'Koordinat manual diterapkan: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
    );
  }

  void _setKoordinat(double lat, double lng, {String? message}) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _latitudeController.text = _formatCoordinate(lat);
      _longitudeController.text = _formatCoordinate(lng);
    });
    _muatDestinasiDekat();
    if (message != null) _snackSuccess(message);
  }

  String _formatCoordinate(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(6);
  }

  Future<void> _muatDestinasiDekat() async {
    setState(() {
      _loadingDestinations = true;
      _destinationMessage = null;
    });

    if (_lat == null || _lng == null) {
      setState(() {
        _nearbyDestinations = _suggestedDestinations;
        _destinationMessage =
            'Pilih titik lokasi rental untuk melihat destinasi terdekat.';
        _loadingDestinations = false;
      });
      return;
    }

    try {
      final nearest = await _destinationSuggestionService
          .ambilSaranDestinasiTerdekat(
            rentalLat: _lat,
            rentalLng: _lng,
            limit: 10,
          );
      if (!mounted) return;
      setState(() {
        final nearestDestinations = nearest
            .map(
              (wd) => _destinationInfoFromWisata(wd.wisata, wd.jarakFormatted),
            )
            .toList();
        _nearbyDestinations = _mergeNearbyWithSuggested(nearestDestinations);
        _destinationMessage = _nearbyDestinations.isEmpty
            ? 'Belum ada destinasi terdekat dengan data koordinat.'
            : null;
        _loadingDestinations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyDestinations = _suggestedDestinations;
        _destinationMessage =
            'Gagal memuat destinasi wisata terdekat dari database.';
        _loadingDestinations = false;
      });
    }
  }

  DestinationInfo _destinationInfoFromWisata(
    WisataLocation wisata,
    String jarakFormatted,
  ) {
    return DestinationInfo(
      id: wisata.id,
      title: wisata.nama,
      distance: jarakFormatted,
      detailDistance: '$jarakFormatted dari rental',
      icon: _iconForKategori(wisata.kategori),
      color: _colorForKategori(wisata.kategori),
      lat: wisata.lat,
      lng: wisata.lng,
    );
  }

  IconData _iconForKategori(String? kategori) {
    final value = kategori?.toLowerCase() ?? '';
    if (value.contains('gunung')) return Icons.terrain_rounded;
    if (value.contains('ranu') || value.contains('danau')) {
      return Icons.water_rounded;
    }
    if (value.contains('hutan')) return Icons.forest_rounded;
    if (value.contains('pantai')) return Icons.beach_access_rounded;
    if (value.contains('air terjun') || value.contains('curug')) {
      return Icons.waterfall_chart_rounded;
    }
    return Icons.landscape_rounded;
  }

  Color _colorForKategori(String? kategori) {
    return switch (kategori?.toLowerCase()) {
      'gunung' => const Color(0xFF336A77),
      'pantai' => const Color(0xFF336A77),
      _ => AppColors.ownerPrimaryGreen,
    };
  }

  String _destinationTitleKey(DestinationInfo item) {
    return 'title:${item.title.trim().toLowerCase()}';
  }

  String _destinationKey(DestinationInfo item) {
    final id = item.id?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    return _destinationTitleKey(item);
  }

  bool _isSameDestination(DestinationInfo a, DestinationInfo b) {
    final aId = a.id?.trim();
    final bId = b.id?.trim();
    if (aId != null && aId.isNotEmpty && bId != null && bId.isNotEmpty) {
      return aId == bId;
    }
    return _destinationTitleKey(a) == _destinationTitleKey(b);
  }

  bool _isDestinationAdded(DestinationInfo item) {
    return _suggestedDestinations.any((dest) => _isSameDestination(dest, item));
  }

  List<DestinationInfo> _mergeNearbyWithSuggested(
    List<DestinationInfo> nearby,
  ) {
    final visibleNearby = nearby
        .where((item) => !_removedDestinationKeys.contains(_destinationKey(item)))
        .toList();
    return _uniqueDestinations([..._suggestedDestinations, ...visibleNearby]);
  }

  List<DestinationInfo> _uniqueDestinations(List<DestinationInfo> items) {
    final result = <DestinationInfo>[];
    for (final item in items) {
      final exists = result.any((dest) => _isSameDestination(dest, item));
      if (!exists) result.add(item);
    }
    return result;
  }

  void _tambahDestinasi(DestinationInfo item) {
    if (_isDestinationAdded(item)) return;
    setState(() {
      _removedDestinationKeys.remove(_destinationKey(item));
      _suggestedDestinations = _uniqueDestinations([
        ..._suggestedDestinations,
        item,
      ]);
    });
    _snackSuccess('${item.title} ditambahkan ke Saran Destinasi Terdekat.');
  }

  void _hapusDestinasi(DestinationInfo item) {
    if (!_isDestinationAdded(item)) return;
    setState(() {
      _removedDestinationKeys.add(_destinationKey(item));
      _suggestedDestinations = _suggestedDestinations
          .where((dest) => !_isSameDestination(dest, item))
          .toList();
      _nearbyDestinations = _nearbyDestinations
          .where((dest) => !_isSameDestination(dest, item))
          .toList();
    });
    _snackSuccess('${item.title} dihapus dari Saran Destinasi Terdekat.');
  }

  void _toggleDestinasi(DestinationInfo item) {
    if (_isDestinationAdded(item)) {
      _hapusDestinasi(item);
    } else {
      _tambahDestinasi(item);
    }
  }

  Future<void> _pilihJamBuka() async {
    final picked = await _pickJam(
      _jamBuka ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && mounted) setState(() => _jamBuka = picked);
  }

  Future<void> _pilihJamTutup() async {
    final picked = await _pickJam(
      _jamTutup ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null && mounted) setState(() => _jamTutup = picked);
  }

  Future<TimeOfDay?> _pickJam(TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Pilih Jam Operasional',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.ownerPrimaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF202321),
            ),
          ),
          child: child!,
        );
      },
    );
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
    if (_lat == null || _lng == null) {
      _snackError('Silakan pilih lokasi toko rental terlebih dahulu');
      return;
    }
    if (_jamBuka == null || _jamTutup == null) {
      _snackError('Silakan lengkapi jam operasional toko');
      return;
    }
    if (_minutesOf(_jamBuka!) == _minutesOf(_jamTutup!) ||
        _minutesOf(_jamTutup!) < _minutesOf(_jamBuka!)) {
      _snackError('Jam tutup harus lebih besar dari jam buka');
      return;
    }

    // Jika belum ada rentalId, tidak bisa simpan ke backend
    final rentalId = widget.rentalProfile?.id;
    if (rentalId == null) {
      // Fallback: tampilkan snackbar saja (rental belum dibuat)
      _snackSuccess('Perubahan detail rental tersimpan (lokal).');
      Navigator.pop(context, _suggestedDestinations);
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
        openTime: _formatJam(_jamBuka!),
        closeTime: _formatJam(_jamTutup!),
      );

      await _rentalService.simpanWisataRental(
        rentalId: rentalId,
        wisataIds: _suggestedDestinations
            .map((item) => item.id?.trim())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList(),
      );

      if (!mounted) return;
      _snackSuccess('Perubahan detail rental berhasil disimpan.');
      Navigator.pop(context, _suggestedDestinations);
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
    NrToast.show(context, msg, type: NrToastType.success);
  }

  void _snackError(String msg) {
    if (!mounted) return;
    NrToast.show(
      context,
      msg,
      type: NrToastType.error,
      duration: const Duration(seconds: 4),
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
      backgroundColor: AppColors.ownerPageBackground,
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
                      color: const Color(0xFF496171),
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _IdentityCard(controller: _namaRentalController),
                  const SizedBox(height: 22),
                  _LocationCard(
                    controller: _alamatController,
                    latitudeController: _latitudeController,
                    longitudeController: _longitudeController,
                    lat: _lat,
                    lng: _lng,
                    loadingGps: _loadingGps,
                    onCekGps: _cekLokasiGps,
                    onPilihMaps: _pilihLokasiDariMaps,
                    onTerapkanKoordinat: _terapkanKoordinatManual,
                  ),
                  const SizedBox(height: 22),
                  _OperationalHoursCard(
                    jamBuka: _jamBuka,
                    jamTutup: _jamTutup,
                    onPilihBuka: _pilihJamBuka,
                    onPilihTutup: _pilihJamTutup,
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
                  if (_loadingDestinations)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.ownerPrimaryGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else ...[
                    if (_destinationMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          _destinationMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF7B8794),
                            height: 1.4,
                          ),
                        ),
                      ),
                    if (_nearbyDestinations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'Belum ada destinasi untuk ditampilkan.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF7B8794),
                          ),
                        ),
                      )
                    else
                      ..._nearbyDestinations.map((item) {
                        final added = _isDestinationAdded(item);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _DestinationCard(
                            item: item,
                            added: added,
                            onTap: () => _toggleDestinasi(item),
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.ownerPageBackground,
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
              backgroundColor: AppColors.ownerPrimaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.ownerPrimaryGreen.withValues(
                alpha: 0.5,
              ),
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
            onPressed: () => Navigator.pop(context, _suggestedDestinations),
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
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final double? lat;
  final double? lng;
  final bool loadingGps;
  final VoidCallback onCekGps;
  final VoidCallback onPilihMaps;
  final VoidCallback onTerapkanKoordinat;

  const _LocationCard({
    required this.controller,
    required this.latitudeController,
    required this.longitudeController,
    required this.lat,
    required this.lng,
    required this.loadingGps,
    required this.onCekGps,
    required this.onPilihMaps,
    required this.onTerapkanKoordinat,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = lat != null && lng != null;

    return _EditSectionCard(
      title: 'Lokasi Toko Rental',
      subtitle: 'Pastikan titik GPS akurat agar penyewa\ntidak tersesat.',
      child: Column(
        children: [
          _LocationActionButton(
            icon: Icons.my_location_rounded,
            label: loadingGps ? 'Mengecek GPS...' : 'Cek Lokasi Sesuai GPS',
            onTap: loadingGps ? null : onCekGps,
            loading: loadingGps,
          ),
          const SizedBox(height: 10),
          _LocationActionButton(
            icon: Icons.map_rounded,
            label: 'Pilih dari Maps',
            onTap: loadingGps ? null : onPilihMaps,
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'INPUT KOORDINAT MANUAL',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF798076),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'LATITUDE',
                  controller: latitudeController,
                  maxLines: 1,
                  hint: 'Masukkan latitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledInput(
                  label: 'LONGITUDE',
                  controller: longitudeController,
                  maxLines: 1,
                  hint: 'Masukkan longitude',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LocationActionButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Terapkan Koordinat',
            onTap: onTerapkanKoordinat,
            filled: true,
          ),
          const SizedBox(height: 20),
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
                                        color: AppColors.ownerPrimaryGreen,
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
                                        color: AppColors.ownerPrimaryGreen,
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

                  // ── Tombol "Pilih dari Maps" — selalu di pojok kanan bawah
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: loadingGps ? null : onPilihMaps,
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
                                  color: AppColors.ownerPrimaryGreen,
                                ),
                              )
                            else
                              const Icon(
                                Icons.map_rounded,
                                color: AppColors.ownerPrimaryGreen,
                                size: 15,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              loadingGps
                                  ? 'Membuka...'
                                  : hasLocation
                                  ? 'Ubah Lokasi'
                                  : 'Pilih dari Maps',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.ownerPrimaryGreen,
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
                color: AppColors.ownerSoftGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.ownerBorderColor,
                  width: AppColors.ownerBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.ownerPrimaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${lat!.toStringAsFixed(6)}  •  Lng: ${lng!.toStringAsFixed(6)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ownerPrimaryGreen,
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

class _LocationActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool filled;

  const _LocationActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        filled ? AppColors.ownerPrimaryGreen : AppColors.ownerSoftGreen;
    final foreground =
        filled ? Colors.white : AppColors.ownerPrimaryGreen;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: foreground,
          backgroundColor: background,
          disabledForegroundColor: foreground.withValues(alpha: 0.55),
          disabledBackgroundColor: background.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: filled
                  ? AppColors.ownerPrimaryGreen
                  : AppColors.ownerBorderColor,
              width: AppColors.ownerBorderWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationalHoursCard extends StatelessWidget {
  final TimeOfDay? jamBuka;
  final TimeOfDay? jamTutup;
  final VoidCallback onPilihBuka;
  final VoidCallback onPilihTutup;

  const _OperationalHoursCard({
    required this.jamBuka,
    required this.jamTutup,
    required this.onPilihBuka,
    required this.onPilihTutup,
  });

  @override
  Widget build(BuildContext context) {
    final hasRange = jamBuka != null && jamTutup != null;
    final summary = hasRange
        ? '${_formatJam(jamBuka!)} - ${_formatJam(jamTutup!)} WIB'
        : 'Jam operasional belum diatur';

    return _EditSectionCard(
      title: 'Jam Operasional',
      subtitle:
          'Atur jam buka dan tutup toko rental untuk ditampilkan ke penyewa.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TimePickerField(
                  label: 'JAM BUKA',
                  value: jamBuka == null ? 'Pilih jam' : _formatJam(jamBuka!),
                  onTap: onPilihBuka,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerField(
                  label: 'JAM TUTUP',
                  value: jamTutup == null ? 'Pilih jam' : _formatJam(jamTutup!),
                  onTap: onPilihTutup,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.ownerSoftGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.ownerBorderColor,
                width: AppColors.ownerBorderWidth,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.ownerPrimaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.ownerPrimaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
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

class _TimePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.ownerCardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.ownerBorderColor,
                width: AppColors.ownerBorderWidth,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.ownerPrimaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF384036),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

String _formatJam(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

TimeOfDay? _timeOfDayFromText(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(value);
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
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
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
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
  final String? hint;
  final TextInputType? keyboardType;

  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.maxLines,
    this.hint,
    this.keyboardType,
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
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF384036),
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.ownerCardBackground,
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF9BA19A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.ownerBorderColor,
                width: AppColors.ownerBorderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.ownerBorderColor,
                width: AppColors.ownerBorderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.ownerPrimaryGreen),
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final DestinationInfo item;
  final bool added;
  final VoidCallback? onTap;

  const _DestinationCard({
    required this.item,
    required this.added,
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
              color: added ? item.color.withValues(alpha: 0.74) : item.color,
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
                          color: AppColors.ownerPrimaryGreen,
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
                  width: added ? 38 : 92,
                  height: 38,
                  decoration: BoxDecoration(
                    color: added
                        ? const Color(0xFFEAEAE7)
                        : AppColors.ownerPrimaryGreen,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: added
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFFB7BDB5),
                          size: 24,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tambah',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
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
