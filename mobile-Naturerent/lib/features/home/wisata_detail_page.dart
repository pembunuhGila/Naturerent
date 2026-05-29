import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/wisata_location.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/location_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/widgets/nr_image.dart';
import '../../core/widgets/nr_toast.dart';
import '../equipment/equipment_list_page.dart';
import 'rental_page.dart';

class WisataDetailPage extends StatefulWidget {
  final WisataLocation wisata;
  const WisataDetailPage({super.key, required this.wisata});

  @override
  State<WisataDetailPage> createState() => _WisataDetailPageState();
}

class _WisataDetailPageState extends State<WisataDetailPage> {
  final _mapController = MapController();
  final _rentalService = RentalService();

  List<RentalWithDistance> _rentals = [];
  bool _isLoading = true;
  bool _lokasiSaya = false;
  LatLng? _userLatLng;

  // Koordinat default wisata
  LatLng get _wisataLatLng =>
      LatLng(widget.wisata.lat ?? -7.9425, widget.wisata.lng ?? 112.9531);
  bool get _wisataHasLocation =>
      widget.wisata.lat != null && widget.wisata.lng != null;

  List<RentalProfile> get _rentalProfiles =>
      _rentals.map((r) => r.rental).toList();

  @override
  void initState() {
    super.initState();
    _muatRental();
  }

  Future<void> _muatRental() async {
    try {
      final data = await _rentalService.ambilRentalAktif();
      if (!mounted) return;
      setState(() {
        _rentals = _urutkanRental(data);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pindahLokasiSaya() async {
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        _snack('Aktifkan GPS terlebih dahulu.');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _snack('Izin lokasi ditolak.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLatLng = latlng;
        _lokasiSaya = true;
        _rentals = _urutkanRental(_rentalProfiles);
      });
      _mapController.move(latlng, 13.0);
    } catch (e) {
      _snack('Gagal ambil lokasi.');
    }
  }

  void _pindahDestinasi() {
    setState(() {
      _lokasiSaya = false;
      _rentals = _urutkanRental(_rentalProfiles);
    });
    _mapController.move(_wisataLatLng, 12.0);
  }

  List<RentalWithDistance> _urutkanRental(List<RentalProfile> rentals) {
    final reference = _lokasiSaya
        ? _userLatLng
        : (_wisataHasLocation ? _wisataLatLng : null);
    if (reference == null) {
      return rentals
          .map((r) => RentalWithDistance(rental: r, distanceKm: null))
          .toList();
    }

    return LocationService.sortRentalsByDistance(
      referenceLat: reference.latitude,
      referenceLng: reference.longitude,
      rentals: rentals,
      includeUnknownLocation: true,
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    NrToast.show(context, msg, type: NrToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // ── Peta OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _wisataLatLng,
              initialZoom: 12.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.naturerent.app',
              ),
              // Marker Wisata
              MarkerLayer(
                markers: [
                  Marker(
                    point: _wisataLatLng,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.wisata.nama.split(' ').first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_pin,
                          color: AppColors.primaryDark,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  // Marker Rental
                  ..._rentalProfiles
                      .where((r) => r.lat != null && r.lng != null)
                      .map(
                        (r) => Marker(
                          point: LatLng(r.lat!, r.lng!),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EquipmentListPage(rental: r),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  // Marker Lokasi User
                  if (_userLatLng != null)
                    Marker(
                      point: _userLatLng!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── App Bar atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.wisata.nama,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RentalPage(
                              wisataId: widget.wisata.id,
                              namaWisata: widget.wisata.nama,
                              wisataLat: widget.wisata.lat,
                              wisataLng: widget.wisata.lng,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Rental',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Toggle Lokasi Saya / Dekat Destinasi
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleBtn(
                      label: 'Lokasi Saya',
                      icon: Icons.my_location_rounded,
                      isActive: _lokasiSaya,
                      onTap: _pindahLokasiSaya,
                    ),
                    _ToggleBtn(
                      label: 'Dekat Destinasi',
                      icon: Icons.place_rounded,
                      isActive: !_lokasiSaya,
                      onTap: _pindahDestinasi,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Sheet Rental List
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.12,
            maxChildSize: 0.75,
            builder: (ctx, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rental di Area Ini',
                                style: AppTextStyles.headlineLarge.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                _isLoading
                                    ? 'Memuat...'
                                    : '${_rentals.length} rental terurut ${_lokasiSaya ? 'dari lokasimu' : 'dari destinasi'}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.wisata.kategori ?? 'Wisata',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    // List
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : _rentals.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.store_outlined,
                                    size: 40,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada rental di area ini',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemCount: _rentals.length,
                              itemBuilder: (_, i) => _RentalBottomCard(
                                rental: _rentals[i].rental,
                                jarak: _rentals[i].distanceKm,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EquipmentListPage(
                                      rental: _rentals[i].rental,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TOGGLE BUTTON
// ─────────────────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RENTAL CARD DI BOTTOM SHEET
// ─────────────────────────────────────────────
class _RentalBottomCard extends StatelessWidget {
  final RentalProfile rental;
  final double? jarak;
  final VoidCallback onTap;
  const _RentalBottomCard({
    required this.rental,
    required this.jarak,
    required this.onTap,
  });

  String get _jarakText {
    if (jarak == null) return 'Lokasi belum tersedia';
    return LocationService.formatJarak(jarak!);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            NrImage(
              imageUrl: rental.fotoBanner,
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(10),
              placeholderColor: AppColors.primaryDark,
              placeholderIcon: Icons.storefront_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental.namaRental,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rental.alamat ?? 'Alamat belum tersedia',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _jarakText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      if (rental.isActive)
                        Text(
                          'AKTIF',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
