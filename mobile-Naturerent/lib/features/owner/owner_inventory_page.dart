import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/equipment.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/equipment_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';
import 'owner_destination_data.dart';
import 'owner_equipment_form_page.dart';
import 'owner_edit_rental_page.dart';
import 'widgets/owner_header_widget.dart';

class OwnerInventoryPage extends StatefulWidget {
  final int initialTabIndex;

  const OwnerInventoryPage({super.key, this.initialTabIndex = 0});

  @override
  State<OwnerInventoryPage> createState() => _OwnerInventoryPageState();
}

class _OwnerInventoryPageState extends State<OwnerInventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final _rentalService = RentalService();
  final _equipmentService = EquipmentService();

  List<Equipment> _alat = [];
  List<Map<String, dynamic>> _categories = [];
  List<DestinationInfo> _suggestedDestinations = [];
  String? _rentalId;
  RentalProfile? _rentalProfile; // Simpan profil rental lengkap (termasuk lat/lng)
  bool _loading = true;
  bool _preparingAdd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1).toInt(),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) setState(() {});
    });
    _muatAlat();
  }

  @override
  void didUpdateWidget(covariant OwnerInventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialTabIndex.clamp(0, 1).toInt();
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        _tabController.index != nextIndex) {
      _tabController.index = nextIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _muatAlat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rental = await _rentalService.pastikanRentalSayaAda();
      final results = await Future.wait([
        _equipmentService.ambilSemuaAlatByRental(rental.id),
        _equipmentService.ambilKategori(),
      ]);
      final alat = results[0] as List<Equipment>;
      final categories = results[1] as List<Map<String, dynamic>>;
      final suggestedDestinations = await _loadSavedDestinations(rental);
      if (!mounted) return;
      setState(() {
        _rentalId = rental.id;
        _rentalProfile = rental;
        _alat = alat;
        _categories = categories;
        _suggestedDestinations = suggestedDestinations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data kelola.';
        _loading = false;
      });
    }
  }

  void _comingSoon(String fitur) {
    NrToast.show(context, '$fitur segera hadir.', type: NrToastType.info);
  }

  Future<List<DestinationInfo>> _loadSavedDestinations(
    RentalProfile rental,
  ) async {
    try {
      final wisataList = await _rentalService.ambilWisataRental(rental.id);
      final destinations = wisataList
          .map(
            (wisata) => DestinationInfo(
              id: wisata.id,
              title: wisata.nama,
              distance: _jarakDestinasi(rental, wisata.lat, wisata.lng),
              detailDistance:
                  '${_jarakDestinasi(rental, wisata.lat, wisata.lng)} dari rental',
              icon: _iconForKategori(wisata.kategori),
              color: _colorForKategori(wisata.kategori),
              lat: wisata.lat,
              lng: wisata.lng,
            ),
          )
          .toList();
      return destinations;
    } catch (_) {
      return [];
    }
  }

  String _jarakDestinasi(RentalProfile rental, double? lat, double? lng) {
    if (rental.lat == null || rental.lng == null || lat == null || lng == null) {
      return '-';
    }

    final distance = LocationService.calculateDistanceKm(
      rental.lat!,
      rental.lng!,
      lat,
      lng,
    );
    return LocationService.formatJarak(distance);
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

  Future<void> _bukaTambahAlat() async {
    var rentalId = _rentalId;
    if (rentalId == null) {
      setState(() => _preparingAdd = true);
      try {
        final rental = await _rentalService.pastikanRentalSayaAda();
        rentalId = rental.id;
        if (!mounted) return;
        setState(() => _rentalId = rental.id);
      } catch (e) {
        if (!mounted) return;
        setState(() => _preparingAdd = false);
        NrToast.show(
          context,
          'Gagal menyiapkan profil rental: ${e.toString()}',
          type: NrToastType.error,
        );
        return;
      }
      if (mounted) setState(() => _preparingAdd = false);
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerEquipmentFormPage(rentalId: rentalId),
      ),
    );
    if (changed == true) _muatAlat();
  }

  void _onTabTap(int index) {
    setState(() {});
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _bukaEditAlat(Equipment? equipment) async {
    if (equipment == null) {
      _comingSoon('Edit data contoh');
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerEquipmentFormPage(equipment: equipment),
      ),
    );
    if (changed == true) _muatAlat();
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OwnerHeaderWidget(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.ownerPrimaryGreen,
                onRefresh: _muatAlat,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(32, 28, 24, 130),
                  children: [
                    Text(
                      'Kelola',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: const Color(0xFF202321),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pantau operasional tempat rental dan kelola\ninventaris alat camping Anda dengan mudah.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF496171),
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildTabs(),
                    const SizedBox(height: 34),
                    if (_tabController.index == 0)
                      _RentalManageTab(
                        rentalProfile: _rentalProfile,
                        onEdit: () async {
                          await Navigator.push<List<DestinationInfo>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OwnerEditRentalPage(
                                rentalProfile: _rentalProfile,
                                suggestedDestinations: _suggestedDestinations,
                              ),
                            ),
                          );
                          // Selalu reload dari Supabase setelah kembali dari edit
                          // agar data benar-benar sinkron antar device
                          _muatAlat();
                        },
                        suggestedDestinations: _suggestedDestinations,
                      )
                    else
                      _EquipmentManageTab(
                        loading: _loading,
                        error: _error,
                        alat: _alat,
                        categories: _categories,
                        onEdit: _bukaEditAlat,
                        onAdd: _preparingAdd ? null : _bukaTambahAlat,
                        preparingAdd: _preparingAdd,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          onTap: _onTabTap,
          labelColor: AppColors.ownerPrimaryGreen,
          unselectedLabelColor: const Color(0xFF496171),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          indicatorColor: AppColors.ownerPrimaryGreen,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: AppColors.ownerBorderColor,
          tabs: const [
            Tab(text: 'Tempat Rental'),
            Tab(text: 'Kelola Peralatan'),
          ],
        ),
      ],
    );
  }
}

class _RentalManageTab extends StatelessWidget {
  final RentalProfile? rentalProfile;
  final VoidCallback onEdit;
  final List<DestinationInfo> suggestedDestinations;

  const _RentalManageTab({
    required this.rentalProfile,
    required this.onEdit,
    required this.suggestedDestinations,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            label: Text(
              'Ubah Detail',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ownerPrimaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _RentalProfileCard(rentalProfile: rentalProfile),
        const SizedBox(height: 24),
        _NearbyDestinationSection(
          destinations: suggestedDestinations,
        ),
      ],
    );
  }

}

class _RentalProfileCard extends StatelessWidget {
  final RentalProfile? rentalProfile;

  const _RentalProfileCard({required this.rentalProfile});

  @override
  Widget build(BuildContext context) {
    final namaRental = rentalProfile?.namaRental ?? 'Base Camp Ranu Kumbolo';
    final alamat = rentalProfile?.alamat ??
        'Kaki Gunung Semeru, Desa Ranupani, Senduro, Lumajang, Jawa Timur';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ownerSoftGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'BASE AKTIF',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ownerPrimaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.verified_rounded,
                color: AppColors.ownerPrimaryGreen,
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            namaRental,
            style: AppTextStyles.headlineLarge.copyWith(
              color: const Color(0xFF202321),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.ownerPrimaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alamat,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF58615A),
                    fontSize: 15,
                    height: 1.45,
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

class _NearbyDestinationSection extends StatelessWidget {
  final List<DestinationInfo> destinations;

  const _NearbyDestinationSection({required this.destinations});

  static const _visibleSuggestionCount = 5;

  @override
  Widget build(BuildContext context) {
    final showSeeAll = destinations.length > _visibleSuggestionCount;
    final items = showSeeAll
        ? destinations.take(_visibleSuggestionCount).toList()
        : destinations;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.ownerPageBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saran Destinasi Terdekat',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: const Color(0xFF202321),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (showSeeAll)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OwnerNearbyDestinationsPage(
                          destinations: destinations,
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      'Lihat Semua',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.ownerPrimaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          if (destinations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada saran destinasi terdekat. Tambahkan melalui Ubah Detail.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF7B8794),
                ),
              ),
            )
          else
            ...items.map((item) {
              final isLast = item == items.last;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: _SmallDestinationCard(item: item),
              );
            }),
        ],
      ),
    );
  }
}

class _SmallDestinationCard extends StatelessWidget {
  final DestinationInfo item;
  const _SmallDestinationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF202321),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.distance,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF4D5650),
                    fontSize: 13,
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

class _EquipmentManageTab extends StatefulWidget {
  final bool loading;
  final String? error;
  final List<Equipment> alat;
  final List<Map<String, dynamic>> categories;
  final ValueChanged<Equipment?> onEdit;
  final VoidCallback? onAdd;
  final bool preparingAdd;

  const _EquipmentManageTab({
    required this.loading,
    required this.error,
    required this.alat,
    required this.categories,
    required this.onEdit,
    required this.onAdd,
    required this.preparingAdd,
  });

  @override
  State<_EquipmentManageTab> createState() => _EquipmentManageTabState();
}

class _EquipmentManageTabState extends State<_EquipmentManageTab> {
  String? _selectedCategoryId;

  List<MapEntry<String, String>> get _categoryOptions {
    final map = <String, String>{};
    for (final item in widget.categories) {
      final id = item['id'] as String?;
      if (id == null || id.isEmpty) continue;
      map[id] = item['nama'] as String? ?? 'Kategori';
    }
    for (final item in widget.alat) {
      final id = item.categoryId;
      if (id == null || id.isEmpty || map.containsKey(id)) continue;
      map[id] = item.namaKategori ?? 'Kategori';
    }
    return map.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = _categoryOptions;
    final activeCategoryId =
        categoryOptions.any((entry) => entry.key == _selectedCategoryId)
            ? _selectedCategoryId
            : null;
    final filtered = activeCategoryId == null
        ? widget.alat
        : widget.alat
            .where((item) => item.categoryId == activeCategoryId)
            .toList();
    final displayItems = filtered.map(_OwnerEquipmentItem.fromEquipment).toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _EquipmentTopControls(
          categories: categoryOptions,
          selectedCategoryId: activeCategoryId,
          onCategoryChanged: (value) {
            setState(() => _selectedCategoryId = value);
          },
          onAdd: widget.onAdd,
          preparingAdd: widget.preparingAdd,
        ),
        const SizedBox(height: 24),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.ownerPrimaryGreen),
            ),
          )
        else if (widget.error != null)
          _EquipmentEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Data peralatan gagal dimuat',
            message: widget.error!,
          )
        else if (displayItems.isEmpty)
          _EquipmentEmptyState(
            icon: Icons.inventory_2_outlined,
            title: activeCategoryId == null
                ? 'Belum ada peralatan'
                : 'Kategori ini masih kosong',
            message: activeCategoryId == null
                ? 'Tambahkan alat pertama agar bisa dikelola dan diedit.'
                : 'Pilih kategori lain atau tambahkan alat baru.',
          )
        else
          ...displayItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: _EquipmentProductCard(
                item: item,
                onEdit: () => widget.onEdit(item.equipment),
              ),
            ),
          ),
      ],
    );
  }
}

class _EquipmentTopControls extends StatelessWidget {
  final List<MapEntry<String, String>> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback? onAdd;
  final bool preparingAdd;

  const _EquipmentTopControls({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.preparingAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.transparent,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: preparingAdd
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                preparingAdd ? 'Menyiapkan...' : 'Tambah Alat Baru',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ownerPrimaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: selectedCategoryId,
            isExpanded: true,
            onChanged: (value) {
              onCategoryChanged(value == '__all' ? null : value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.ownerCardBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.ownerBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.ownerBorderColor),
              ),
            ),
            hint: Text(
              'Kategori Alat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF202321),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            items: [
              DropdownMenuItem<String>(
                value: '__all',
                child: Text(
                  'Semua Kategori',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...categories.map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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

class _EquipmentEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EquipmentEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF687369), size: 42),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF222523),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF687369),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentProductCard extends StatelessWidget {
  final _OwnerEquipmentItem item;
  final VoidCallback onEdit;

  const _EquipmentProductCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EquipmentVisual(item: item),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: const Color(0xFF222523),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: item.price,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.ownerPrimaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(
                        text: '/hari',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF2D342F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(item.stockIcon, color: item.stockColor, size: 15),
                const SizedBox(width: 7),
                Text(
                  item.stockText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: item.stockColor,
                    fontSize: 13,
                    fontWeight: item.status == _EquipmentStatus.available
                        ? FontWeight.w500
                        : FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF222523),
                  size: 18,
                ),
                label: Text(
                  'Edit',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF222523),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9E9E5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentVisual extends StatelessWidget {
  final _OwnerEquipmentItem item;

  const _EquipmentVisual({required this.item});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _EquipmentImageFallback(item: item);
                },
              )
            else
              _EquipmentImageFallback(item: item),
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.badgeColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  item.badgeLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: item.badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentImageFallback extends StatelessWidget {
  final _OwnerEquipmentItem item;

  const _EquipmentImageFallback({required this.item});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.visualColor,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.1,
          colors: [item.visualColor.withValues(alpha: 0.86), item.visualColor],
        ),
      ),
      child: Center(
        child: Icon(item.icon, size: item.iconSize, color: item.iconColor),
      ),
    );
  }
}

enum _EquipmentStatus { available, low, empty }

class _OwnerEquipmentItem {
  final Equipment? equipment;
  final String? imageUrl;
  final String name;
  final String price;
  final int stock;
  final _EquipmentStatus status;
  final IconData icon;
  final Color visualColor;
  final Color iconColor;
  final double iconSize;

  const _OwnerEquipmentItem({
    this.equipment,
    this.imageUrl,
    required this.name,
    required this.price,
    required this.stock,
    required this.status,
    required this.icon,
    required this.visualColor,
    this.iconColor = Colors.white,
  }) : iconSize = 118;

  factory _OwnerEquipmentItem.fromEquipment(Equipment equipment) {
    final status = equipment.stock <= 0
        ? _EquipmentStatus.empty
        : equipment.stock <= 2
        ? _EquipmentStatus.low
        : _EquipmentStatus.available;

    return _OwnerEquipmentItem(
      equipment: equipment,
      imageUrl: equipment.gambarprimaryUrl,
      name: equipment.nama,
      price: _formatCompactRupiah(equipment.hargaPerHari),
      stock: equipment.stock,
      status: status,
      icon: _iconForCategory(equipment.namaKategori ?? equipment.nama),
      visualColor: _visualColorForStatus(status),
      iconColor: status == _EquipmentStatus.empty
          ? const Color(0xFF666966)
          : Colors.white,
    );
  }

  String get badgeLabel => switch (status) {
    _EquipmentStatus.available => 'TERSEDIA',
    _EquipmentStatus.low => 'HAMPIR HABIS',
    _EquipmentStatus.empty => 'HABIS',
  };

  Color get badgeColor => switch (status) {
    _EquipmentStatus.available => AppColors.ownerSoftGreen,
    _EquipmentStatus.low => const Color(0xFFC65787),
    _EquipmentStatus.empty => const Color(0xFFFFE0E0),
  };

  Color get badgeTextColor => switch (status) {
    _EquipmentStatus.available => AppColors.ownerPrimaryGreen,
    _EquipmentStatus.low => Colors.white,
    _EquipmentStatus.empty => const Color(0xFFD65B66),
  };

  String get stockText => switch (status) {
    _EquipmentStatus.available => 'Stok: $stock Unit',
    _EquipmentStatus.low => 'Tersisa $stock Unit',
    _EquipmentStatus.empty => 'Stok Kosong',
  };

  IconData get stockIcon => switch (status) {
    _EquipmentStatus.available => Icons.inventory_2_outlined,
    _EquipmentStatus.low => Icons.warning_amber_rounded,
    _EquipmentStatus.empty => Icons.block_rounded,
  };

  Color get stockColor => switch (status) {
    _EquipmentStatus.available => const Color(0xFF3F4942),
    _EquipmentStatus.low => const Color(0xFFC65787),
    _EquipmentStatus.empty => const Color(0xFFE05C60),
  };
}

String _formatCompactRupiah(double value) {
  final amount = value.round();
  if (amount >= 1000) {
    final compact = amount ~/ 1000;
    return 'Rp ${compact}k';
  }
  return 'Rp $amount';
}

IconData _iconForCategory(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('tenda')) return Icons.cabin_rounded;
  if (lower.contains('carrier') || lower.contains('tas')) {
    return Icons.work_rounded;
  }
  if (lower.contains('masak') || lower.contains('cooking')) {
    return Icons.soup_kitchen_rounded;
  }
  if (lower.contains('sepatu')) return Icons.hiking_rounded;
  return Icons.inventory_2_rounded;
}

Color _visualColorForStatus(_EquipmentStatus status) => switch (status) {
  _EquipmentStatus.available => AppColors.ownerPrimaryGreen,
  _EquipmentStatus.low => const Color(0xFF1A2420),
  _EquipmentStatus.empty => const Color(0xFFF7F7F4),
};

class OwnerNearbyDestinationsPage extends StatelessWidget {
  final List<DestinationInfo> destinations;

  const OwnerNearbyDestinationsPage({
    super.key,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ownerPageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF263229)),
        ),
        title: Text(
          'Saran Destinasi Terdekat',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF263229),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        children: destinations
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SmallDestinationCard(item: item),
              ),
            )
            .toList(),
      ),
    );
  }
}
