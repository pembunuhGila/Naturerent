import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/equipment.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/equipment_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/widgets/nr_image.dart';
import '../checkout/checkout_page.dart';
import '../home/rental_detail_page.dart';
import 'equipment_detail_page.dart';

class EquipmentListPage extends StatefulWidget {
  final RentalProfile rental;
  const EquipmentListPage({super.key, required this.rental});

  @override
  State<EquipmentListPage> createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> {
  final _equipmentService = EquipmentService();
  final _searchCtrl = TextEditingController();

  List<Equipment> _semuaAlat = [];
  List<Equipment> _alatFiltered = [];
  List<Map<String, dynamic>> _kategori = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedKategoriId; // null = Semua
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _equipmentService.ambilAlatByRental(widget.rental.id),
        _equipmentService.ambilKategori(),
      ]);
      if (!mounted) return;
      setState(() {
        _semuaAlat = results[0] as List<Equipment>;
        _kategori = results[1] as List<Map<String, dynamic>>;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data. Tarik untuk muat ulang.';
        _isLoading = false;
      });
    }
  }

  void _filterKategori(String? kategoriId) {
    setState(() {
      _selectedKategoriId = kategoriId;
      _applyFilters();
    });
  }

  void _filterSearch(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    Iterable<Equipment> data = _semuaAlat;
    if (_selectedKategoriId != null) {
      data = data.where((a) => a.categoryId == _selectedKategoriId);
    }
    if (_searchQuery.isNotEmpty) {
      data = data.where((a) {
        final text = [
          a.nama,
          a.deskripsi ?? '',
          a.namaKategori ?? '',
          a.size ?? '',
        ].join(' ').toLowerCase();
        return text.contains(_searchQuery);
      });
    }
    _alatFiltered = data.toList();
  }

  // -- Icon untuk tiap kategori berdasarkan nama
  IconData _iconKategori(String? nama) {
    switch (nama?.toLowerCase()) {
      case 'tenda':
        return Icons.cabin_rounded;
      case 'sleeping bag':
        return Icons.airline_seat_flat_rounded;
      case 'carrier / tas':
        return Icons.backpack_rounded;
      case 'matras':
        return Icons.horizontal_rule_rounded;
      case 'kompor & masak':
        return Icons.outdoor_grill_rounded;
      case 'lampu & senter':
        return Icons.flashlight_on_rounded;
      case 'pakaian':
        return Icons.checkroom_rounded;
      case 'navigasi':
        return Icons.explore_rounded;
      case 'p3k':
        return Icons.medical_services_rounded;
      default:
        return Icons.category_rounded;
    }
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _muatData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildStickyAppBar(),
              // -- Header rental
              SliverToBoxAdapter(child: _buildHeader()),

              SliverToBoxAdapter(child: _buildSearchBox()),

              // -- Filter kategori
              if (_kategori.isNotEmpty)
                SliverToBoxAdapter(child: _buildKategoriFilter()),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // -- Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildErrorState())
              else if (_alatFiltered.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AlatShowcaseCard(
                      alat: _alatFiltered[i],
                      namaRental: widget.rental.namaRental,
                      lokasi: widget.rental.alamat,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentDetailPage(
                            equipmentId: _alatFiltered[i].id,
                            rental: widget.rental,
                          ),
                        ),
                      ),
                    ),
                    childCount: _alatFiltered.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  SliverAppBar _buildStickyAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      automaticallyImplyLeading: false,
      toolbarHeight: 62,
      titleSpacing: 16,
      title: Row(
        children: [
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.rental.namaRental,
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentalDetailPage(rental: widget.rental),
              ),
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
                Icons.info_outline_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: CartService().count,
            builder: (_, count, widget) => Stack(
              clipBehavior: Clip.none,
              children: [
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
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 9,
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

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filterSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari alat camping...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _filterSearch('');
                  },
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Banner + info rental
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Foto profil rental
                    ClipOval(
                      child: NrImage(
                        imageUrl: widget.rental.fotoProfil,
                        width: 56,
                        height: 56,
                        placeholderColor: AppColors.primaryDark,
                        placeholderIcon: Icons.storefront_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.rental.namaRental,
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.textHint,
                                size: 13,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  widget.rental.alamat ??
                                      'Lokasi tidak tersedia',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textHint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RentalDetailPage(rental: widget.rental),
                      ),
                    ),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Lihat Detail Toko'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriFilter() {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: _kategori.length + 1, // +1 untuk "Semua"
        itemBuilder: (context, i) {
          final isAll = i == 0;
          final kategori = isAll ? null : _kategori[i - 1];
          final isSelected = isAll
              ? _selectedKategoriId == null
              : _selectedKategoriId == kategori?['id'];

          return GestureDetector(
            onTap: () =>
                _filterKategori(isAll ? null : kategori?['id'] as String?),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAll
                        ? Icons.grid_view_rounded
                        : _iconKategori(kategori?['nama'] as String?),
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAll
                        ? 'Semua'
                        : (kategori?['nama'] as String? ?? '').split(' ').first,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'Belum ada alat',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rental ini belum menambahkan\nperalatan camping.',
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
          Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _muatData,
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

// ----------------------------------------------------------
//  CARD ALAT
// ----------------------------------------------------------
class _AlatShowcaseCard extends StatelessWidget {
  final Equipment alat;
  final String namaRental;
  final String? lokasi;
  final VoidCallback onTap;

  const _AlatShowcaseCard({
    required this.alat,
    required this.namaRental,
    required this.lokasi,
    required this.onTap,
  });

  String get _hargaFormatted {
    final harga = alat.hargaPerHari.toInt();
    final s = harga.toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 172,
                    width: double.infinity,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: NrImage(
                        imageUrl: alat.gambarprimaryUrl,
                        width: double.infinity,
                        height: 152,
                        fit: BoxFit.contain,
                        placeholderColor: const Color(0xFF2D4A2D),
                        placeholderIcon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: alat.stock > 0
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        alat.stock > 0 ? 'TERSEDIA' : 'STOK HABIS',
                        style: AppTextStyles.caption.copyWith(
                          color: alat.stock > 0
                              ? AppColors.primaryDark
                              : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alat.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      namaRental,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lokasi ?? 'Lokasi belum tersedia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '$_hargaFormatted / hari',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (alat.size != null && alat.size!.isNotEmpty) ...[
                          _SpecChip(label: 'Size ${alat.size}'),
                          const SizedBox(width: 6),
                        ],
                        _SpecChip(label: '${alat.stock} unit'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;

  const _SpecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
