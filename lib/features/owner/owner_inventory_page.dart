import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/equipment.dart';
import '../../core/services/equipment_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import 'owner_destination_data.dart';
import 'owner_edit_rental_page.dart';

class OwnerInventoryPage extends StatefulWidget {
  const OwnerInventoryPage({super.key});

  @override
  State<OwnerInventoryPage> createState() => _OwnerInventoryPageState();
}

class _OwnerInventoryPageState extends State<OwnerInventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _rentalService = RentalService();
  final _equipmentService = EquipmentService();

  List<Equipment> _alat = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) setState(() {});
    });
    _muatAlat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _muatAlat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rental = await _rentalService.ambilRentalSaya();
      final alat = rental == null
          ? <Equipment>[]
          : await _equipmentService.ambilSemuaAlatByRental(rental.id);
      if (!mounted) return;
      setState(() {
        _alat = alat;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fitur segera hadir.'),
        backgroundColor: const Color(0xFF13733A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
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
      backgroundColor: const Color(0xFFF8F8F5),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF13733A),
          onRefresh: _muatAlat,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 64, 24, 130),
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
                  color: const Color(0xFF4C554D),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              _buildTabs(),
              const SizedBox(height: 34),
              if (_tabController.index == 0)
                _RentalManageTab(
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OwnerEditRentalPage(),
                    ),
                  ),
                  onAddDestination: () => _comingSoon('Tambah rekomendasi'),
                )
              else
                _EquipmentManageTab(
                  loading: _loading,
                  error: _error,
                  alat: _alat,
                  onEdit: () => _comingSoon('Edit alat'),
                  onAdd: () => _comingSoon('Tambah alat'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: const Color(0xFF0E6F2A),
          unselectedLabelColor: const Color(0xFF475048),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          indicatorColor: const Color(0xFF0E6F2A),
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: const Color(0xFFE8EAE4),
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
  final VoidCallback onEdit;
  final VoidCallback onAddDestination;

  const _RentalManageTab({
    required this.onEdit,
    required this.onAddDestination,
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
              backgroundColor: const Color(0xFF087027),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const _RentalProfileCard(),
        const SizedBox(height: 24),
        const _NearbyDestinationSection(),
        const SizedBox(height: 24),
        InkWell(
          onTap: onAddDestination,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE7DC), width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF6E7A6E),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Tambah Rekomendasi Baru',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF4F5A50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RentalProfileCard extends StatelessWidget {
  const _RentalProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 192,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/loading_background.png',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.42)),
                  Center(
                    child: Text(
                      'CURRENT RENTAL\nBASE',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F5E3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'BASE AKTIF',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF148036),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF148036),
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Base Camp Ranu\nKumbolo',
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
                color: Color(0xFF0B7130),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kaki Gunung Semeru, Desa Ranupani,\nSenduro, Lumajang, Jawa Timur',
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
  const _NearbyDestinationSection();

  @override
  Widget build(BuildContext context) {
    final showSeeAll = ownerNearbyDestinations.length > 3;
    final items = showSeeAll
        ? ownerNearbyDestinations.take(3).toList()
        : ownerNearbyDestinations;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Destinasi Terdekat',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: const Color(0xFF202321),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (showSeeAll)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OwnerNearbyDestinationsPage(),
                    ),
                  ),
                  child: Text(
                    'Lihat Semua',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF0B7130),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
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

class _EquipmentManageTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Equipment> alat;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  const _EquipmentManageTab({
    required this.loading,
    required this.error,
    required this.alat,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = loading || error != null || alat.isEmpty
        ? _demoEquipmentItems
        : alat.map(_OwnerEquipmentItem.fromEquipment).toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...displayItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: _EquipmentProductCard(item: item, onEdit: onEdit),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: SizedBox(
            width: 206,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Tambah Alat Baru',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF087027),
                elevation: 14,
                shadowColor: const Color(0xFF087027).withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
      ],
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
                      color: const Color(0xFF0E7C35),
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
      aspectRatio: 1.68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: item.visualColor,
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.1,
                  colors: [
                    item.visualColor.withValues(alpha: 0.86),
                    item.visualColor,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: item.iconSize,
                  color: item.iconColor,
                ),
              ),
            ),
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

enum _EquipmentStatus { available, low, empty }

class _OwnerEquipmentItem {
  final String name;
  final String price;
  final int stock;
  final _EquipmentStatus status;
  final IconData icon;
  final Color visualColor;
  final Color iconColor;
  final double iconSize;

  const _OwnerEquipmentItem({
    required this.name,
    required this.price,
    required this.stock,
    required this.status,
    required this.icon,
    required this.visualColor,
    this.iconColor = Colors.white,
    this.iconSize = 118,
  });

  factory _OwnerEquipmentItem.fromEquipment(Equipment equipment) {
    final status = equipment.stock <= 0
        ? _EquipmentStatus.empty
        : equipment.stock <= 2
        ? _EquipmentStatus.low
        : _EquipmentStatus.available;

    return _OwnerEquipmentItem(
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
    _EquipmentStatus.available => const Color(0xFF9BFA8D),
    _EquipmentStatus.low => const Color(0xFFC65787),
    _EquipmentStatus.empty => const Color(0xFFFFE0E0),
  };

  Color get badgeTextColor => switch (status) {
    _EquipmentStatus.available => const Color(0xFF087027),
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

const _demoEquipmentItems = [
  _OwnerEquipmentItem(
    name: 'Tenda Dome 4P',
    price: 'Rp 75k',
    stock: 12,
    status: _EquipmentStatus.available,
    icon: Icons.inventory_2_rounded,
    visualColor: Color(0xFF0D6075),
    iconSize: 120,
  ),
  _OwnerEquipmentItem(
    name: 'Carrier 60L Pro',
    price: 'Rp 45k',
    stock: 2,
    status: _EquipmentStatus.low,
    icon: Icons.work_rounded,
    visualColor: Color(0xFF1A2420),
    iconColor: Color(0xFFFF7F2A),
    iconSize: 124,
  ),
  _OwnerEquipmentItem(
    name: 'Cooking Set Elite',
    price: 'Rp 25k',
    stock: 0,
    status: _EquipmentStatus.empty,
    icon: Icons.soup_kitchen_rounded,
    visualColor: Color(0xFFF7F7F4),
    iconColor: Color(0xFF666966),
    iconSize: 126,
  ),
  _OwnerEquipmentItem(
    name: 'Tenda Arpenaz 4.1',
    price: 'Rp 150k',
    stock: 25,
    status: _EquipmentStatus.available,
    icon: Icons.cabin_rounded,
    visualColor: Color(0xFF82B75E),
    iconSize: 128,
  ),
];

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
  _EquipmentStatus.available => const Color(0xFF0D6075),
  _EquipmentStatus.low => const Color(0xFF1A2420),
  _EquipmentStatus.empty => const Color(0xFFF7F7F4),
};

class OwnerNearbyDestinationsPage extends StatelessWidget {
  const OwnerNearbyDestinationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF263229)),
        ),
        title: Text(
          'Destinasi Terdekat',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF263229),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        children: ownerNearbyDestinations
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
