import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/location_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/widgets/nr_image.dart';
import '../../core/widgets/nr_toast.dart';
import '../checkout/checkout_page.dart';
import '../equipment/equipment_list_page.dart';

class RentalPage extends StatefulWidget {
  /// Jika [wisataId] diisi, hanya tampilkan rental dekat wisata tersebut.
  final String? wisataId;
  final String? namaWisata;
  final double? wisataLat;
  final double? wisataLng;

  const RentalPage({
    super.key,
    this.wisataId,
    this.namaWisata,
    this.wisataLat,
    this.wisataLng,
  });

  @override
  State<RentalPage> createState() => _RentalPageState();
}

class _RentalPageState extends State<RentalPage> {
  final _rentalService = RentalService();

  List<RentalProfile> _semuaRental = [];
  List<RentalWithDistance> _rentalFiltered = [];
  bool _isLoading = true;
  String? _error;
  late bool _lokasiSaya;
  Position? _userPos;

  @override
  void initState() {
    super.initState();
    _lokasiSaya = widget.wisataId == null;
    _muatRental();
  }

  // ──────────────────────────────────────────────────────────

  Future<void> _muatRental() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _rentalService.ambilRentalAktif();
      if (_lokasiSaya) {
        final latestPos = await _ambilPosisiSaya(
          showMessages: widget.wisataId == null && _userPos == null,
        );
        if (latestPos != null) _userPos = latestPos;
      }
      if (!mounted) return;
      setState(() {
        _semuaRental = data;
        _rentalFiltered = _urutkanRental(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data rental.';
        _isLoading = false;
      });
    }
  }

  Future<void> _switchLokasiSaya() async {
    final pos = await _ambilPosisiSaya();
    if (pos == null || !mounted) return;

    setState(() {
      _userPos = pos;
      _lokasiSaya = true;
      _rentalFiltered = _urutkanRental(_semuaRental);
    });
    _bukaPetaLokasiSaya(pos);
  }

  void _bukaPetaLokasiSaya(Position pos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RentalUserLocationMapPage(
          userPoint: LatLng(pos.latitude, pos.longitude),
          rentals: _rentalFiltered,
        ),
      ),
    );
  }

  Future<Position?> _ambilPosisiSaya({bool showMessages = true}) async {
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) {
        if (showMessages) _snack('Aktifkan GPS terlebih dahulu.');
        return null;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        if (showMessages) _snack('Izin lokasi ditolak.');
        return null;
      }
      if (perm == LocationPermission.deniedForever) {
        if (showMessages) {
          _snack('Izin lokasi diblokir. Buka pengaturan aplikasi.');
        }
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      if (showMessages) _snack('Gagal mendapatkan lokasi.');
      return null;
    }
  }

  void _switchDestinasi() {
    if (widget.wisataLat == null || widget.wisataLng == null) {
      _snack('Pilih destinasi dulu untuk melihat rental terdekat.');
      return;
    }

    setState(() {
      _lokasiSaya = false;
      _rentalFiltered = _urutkanRental(_semuaRental);
    });
  }

  void _snack(String msg) {
    NrToast.show(context, msg, type: NrToastType.info);
  }

  List<RentalWithDistance> _urutkanRental(List<RentalProfile> rentals) {
    final lat = _lokasiSaya ? _userPos?.latitude : widget.wisataLat;
    final lng = _lokasiSaya ? _userPos?.longitude : widget.wisataLng;
    if (lat == null || lng == null) {
      return rentals
          .map((r) => RentalWithDistance(rental: r, distanceKm: null))
          .toList();
    }

    return LocationService.sortRentalsByDistance(
      referenceLat: lat,
      referenceLng: lng,
      rentals: rentals,
      includeUnknownLocation: true,
    );
  }

  // ──────────────────────────────────────────────────────────

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
        bottom: false, // MainShell sudah handle bottom nav spacing
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _muatRental,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              if (widget.wisataId != null)
                SliverToBoxAdapter(child: _buildLokasiBar()),
              SliverToBoxAdapter(child: _buildToggle()),
              SliverToBoxAdapter(child: _buildSectionHeader()),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildErrorState())
              else if (_rentalFiltered.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RentalCard(
                      rental: _rentalFiltered[i].rental,
                      jarak: _rentalFiltered[i].distanceKm,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentListPage(
                            rental: _rentalFiltered[i].rental,
                          ),
                        ),
                      ),
                    ),
                    childCount: _rentalFiltered.length,
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 132,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  WIDGETS
  // ──────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          if (widget.wisataId != null) ...[
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
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              'Pilih Tempat Rental',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'Menampilkan rental di sekitar '),
                  TextSpan(
                    text: widget.namaWisata ?? 'Destinasi',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'UBAH',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    if (widget.wisataId == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _ToggleTab(
            label: 'Lokasi Saya',
            isActive: _lokasiSaya,
            onTap: _switchLokasiSaya,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ToggleTab(
                label: 'Lokasi Saya',
                isActive: _lokasiSaya,
                onTap: _switchLokasiSaya,
              ),
            ),
            Expanded(
              child: _ToggleTab(
                label: 'Dekat Destinasi',
                isActive: !_lokasiSaya,
                onTap: _switchDestinasi,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rental Terdekat',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _sectionSubtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _sectionSubtitle {
    if (_isLoading) return 'Memuat...';
    if (_lokasiSaya && _userPos == null) {
      return 'Lokasi belum tersedia';
    }
    final source = _lokasiSaya ? 'dari lokasimu' : 'dari destinasi';
    return '${_rentalFiltered.length} rental tersedia, terurut $source';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_outlined, size: 52, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'Belum ada rental',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Data rental akan muncul setelah\npemilik mendaftarkan usahanya.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 52,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _muatRental,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: Text(
              'Coba Lagi',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  TOGGLE TAB
// ──────────────────────────────────────────────────────────
class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ToggleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  RENTAL CARD
// ──────────────────────────────────────────────────────────
class _RentalCard extends StatelessWidget {
  final RentalProfile rental;
  final double? jarak;
  final VoidCallback onTap;

  const _RentalCard({
    required this.rental,
    required this.jarak,
    required this.onTap,
  });

  String get _jarakStr {
    if (jarak == null) return 'Lokasi belum tersedia';
    return LocationService.formatJarak(jarak!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Foto rental
                NrImage(
                  imageUrl: rental.fotoBanner,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(12),
                  placeholderColor: AppColors.primaryDark,
                  placeholderIcon: Icons.storefront_rounded,
                ),
                const SizedBox(width: 12),
                // ── Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.namaRental,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 19,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              rental.alamat ?? 'Alamat belum tersedia',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            jarak == null
                                ? Icons.location_on_outlined
                                : Icons.near_me_rounded,
                            size: 16,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _jarakStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (rental.isActive)
                            const _Badge(
                              label: 'AKTIF',
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryDark,
                    size: 22,
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _RentalUserLocationMapPage extends StatelessWidget {
  final LatLng userPoint;
  final List<RentalWithDistance> rentals;

  const _RentalUserLocationMapPage({
    required this.userPoint,
    required this.rentals,
  });

  @override
  Widget build(BuildContext context) {
    final rentalMarkers = rentals
        .map((item) => item.rental)
        .where((r) => r.lat != null && r.lng != null)
        .map(
          (r) => Marker(
            point: LatLng(r.lat!, r.lng!),
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
        )
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: userPoint,
              initialZoom: 13,
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
                  ...rentalMarkers,
                  Marker(
                    point: userPoint,
                    width: 46,
                    height: 46,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 20,
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
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
                      'Lokasi Saya',
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
