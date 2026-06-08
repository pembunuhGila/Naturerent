import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/cart_service.dart';
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
  static const double _defaultMapLat = -7.9425;
  static const double _defaultMapLng = 112.9531;

  final _rentalService = RentalService();
  final _searchController = TextEditingController();

  List<RentalProfile> _semuaRental = [];
  List<RentalWithDistance> _rentalFiltered = [];
  Map<String, int> _equipmentCounts = {};
  bool _isLoading = true;
  String? _error;
  late bool _lokasiSaya;
  Position? _userPos;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _lokasiSaya = widget.wisataId == null;
    _searchController.addListener(_handleSearchChanged);
    _muatRental();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────

  Future<void> _muatRental() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _rentalService.ambilRentalAktif();
      final counts = await _rentalService.ambilJumlahAlatTersedia(
        data.map((item) => item.id).toList(),
      );
      if (_lokasiSaya) {
        final latestPos = await _ambilPosisiSaya(
          showMessages: widget.wisataId == null && _userPos == null,
        );
        if (latestPos != null) _userPos = latestPos;
      }
      if (!mounted) return;
      setState(() {
        _semuaRental = data;
        _equipmentCounts = counts;
        _applyRentalView();
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
      _applyRentalView();
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

  void _handleSearchChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _searchQuery) return;
    setState(() {
      _searchQuery = next;
      _applyRentalView();
    });
  }

  LatLng get _previewPoint {
    if (_lokasiSaya && _userPos != null) {
      return LatLng(_userPos!.latitude, _userPos!.longitude);
    }
    if (!_lokasiSaya &&
        widget.wisataLat != null &&
        widget.wisataLng != null) {
      return LatLng(widget.wisataLat!, widget.wisataLng!);
    }
    return const LatLng(_defaultMapLat, _defaultMapLng);
  }

  bool get _showLocationHint {
    return _lokasiSaya && _userPos == null;
  }

  void _openLocationPreviewMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RentalUserLocationMapPage(
          userPoint: _previewPoint,
          rentals: _rentalFiltered,
        ),
      ),
    );
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

  void _applyRentalView() {
    final sorted = _urutkanRental(_semuaRental);
    if (_searchQuery.isEmpty) {
      _rentalFiltered = sorted;
      return;
    }
    _rentalFiltered = sorted.where((item) {
      final rental = item.rental;
      final text = [
        rental.namaRental,
        rental.alamat ?? '',
        rental.deskripsi ?? '',
      ].join(' ').toLowerCase();
      return text.contains(_searchQuery);
    }).toList();
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
              _buildPinnedAppBar(),
              if (widget.wisataId != null)
                SliverToBoxAdapter(child: _buildLokasiBar()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildLocationSection()),
              SliverToBoxAdapter(child: _buildFilterBar()),
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
                      equipmentCount:
                          _equipmentCounts[_rentalFiltered[i].rental.id] ?? 0,
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

  SliverAppBar _buildPinnedAppBar() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      elevation: 0,
      toolbarHeight: 74,
      titleSpacing: 0,
      title: _buildAppBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.wisataId != null) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: CartService().count,
                builder: (_, count, child) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckoutPage()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: count > 9 ? 7.5 : 9,
                              fontWeight: FontWeight.w800,
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
          const SizedBox(height: 8),
          Text(
            _lokasiSaya
                ? 'Temukan rental terdekat dari lokasimu'
                : 'Temukan rental terdekat dari destinasi pilihanmu',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari rental atau lokasi',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                onPressed: () => _searchController.clear(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildLokasiBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
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
              'Ubah',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lokasi Terdekat',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _switchLokasiSaya,
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primaryDark,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Gunakan Lokasi Saya',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _openLocationPreviewMap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: double.infinity,
                  height: 188,
                  child: _RentalLocationPreviewMap(
                    centerPoint: _previewPoint,
                    rentals: _rentalFiltered,
                    showUserMarker: _lokasiSaya && _userPos != null,
                  ),
                ),
              ),
            ),
          ),
          if (_showLocationHint) ...[
            const SizedBox(height: 10),
            Text(
              'Aktifkan lokasi untuk melihat rental terdekat dari posisimu.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Terdekat',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
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
// ──────────────────────────────────────────────────────────
//  RENTAL CARD
// ──────────────────────────────────────────────────────────
class _RentalCard extends StatelessWidget {
  final RentalProfile rental;
  final double? jarak;
  final int equipmentCount;
  final VoidCallback onTap;

  const _RentalCard({
    required this.rental,
    required this.jarak,
    required this.equipmentCount,
    required this.onTap,
  });

  String get _jarakStr {
    if (jarak == null) return 'Lokasi belum tersedia';
    return LocationService.formatJarak(jarak!);
  }

  String get _alamatRingkas {
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
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
                        _alamatRingkas,
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
                              _jarakStr,
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

class _RentalLocationPreviewMap extends StatelessWidget {
  final LatLng centerPoint;
  final List<RentalWithDistance> rentals;
  final bool showUserMarker;

  const _RentalLocationPreviewMap({
    required this.centerPoint,
    required this.rentals,
    required this.showUserMarker,
  });

  @override
  Widget build(BuildContext context) {
    final rentalMarkers = rentals
        .map((item) => item.rental)
        .where((r) => r.lat != null && r.lng != null)
        .take(8)
        .map(
          (r) => Marker(
            point: LatLng(r.lat!, r.lng!),
            width: 34,
            height: 34,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        )
        .toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: centerPoint,
        initialZoom: 12.5,
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
            ...rentalMarkers,
            if (showUserMarker)
              Marker(
                point: centerPoint,
                width: 38,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ],
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
