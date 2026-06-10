import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naturerent/core/theme/app_theme.dart';
import 'package:naturerent/core/models/equipment.dart';
import 'package:naturerent/core/models/rental_profile.dart';
import 'package:naturerent/core/services/equipment_service.dart';
import 'package:naturerent/core/services/cart_service.dart';
import 'package:naturerent/core/widgets/nr_image.dart';
import 'package:naturerent/core/widgets/nr_toast.dart';
import 'package:naturerent/features/user/checkout/checkout_page.dart';
import 'package:naturerent/features/user/rental/rental_detail_page.dart';
import 'package:naturerent/features/user/rental/user_equipment_detail_page.dart';

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
    final lower = nama?.toLowerCase() ?? '';
    if (lower.contains('tenda')) return Icons.cabin_rounded;
    if (lower.contains('sleeping')) return Icons.airline_seat_flat_rounded;
    if (lower.contains('carrier') || lower.contains('tas'))
      return Icons.backpack_rounded;
    if (lower.contains('matras')) return Icons.horizontal_rule_rounded;
    if (lower.contains('masak')) return Icons.outdoor_grill_rounded;
    if (lower.contains('lampu') || lower.contains('senter'))
      return Icons.flashlight_on_rounded;
    if (lower.contains('pakaian') || lower.contains('alas kaki'))
      return Icons.checkroom_rounded;
    if (lower.contains('p3k')) return Icons.medical_services_rounded;
    if (lower.contains('hiking')) return Icons.hiking_rounded;
    if (lower.contains('meja') || lower.contains('kursi'))
      return Icons.chair_rounded;
    if (lower.contains('lainnya')) return Icons.more_horiz_rounded;
    return Icons.category_rounded;
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 304,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _AlatShowcaseCard(
                        alat: _alatFiltered[i],
                        rental: widget.rental,
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textHint,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _filterSearch('');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textHint,
                  ),
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
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: _kategori.length + 1, // +1 untuk "Semua"
        itemBuilder: (context, i) {
          final isAll = i == 0;
          final kategori = isAll ? null : _kategori[i - 1];
          final isSelected = isAll
              ? _selectedKategoriId == null
              : _selectedKategoriId == kategori?['id'];
          final namaKategori = isAll
              ? 'Semua'
              : (kategori?['nama'] as String? ?? 'Kategori');

          return GestureDetector(
            onTap: () =>
                _filterKategori(isAll ? null : kategori?['id'] as String?),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAll
                        ? Icons.grid_view_rounded
                        : _iconKategori(kategori?['nama'] as String?),
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    namaKategori,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 11,
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
  final RentalProfile rental;
  final VoidCallback onTap;

  const _AlatShowcaseCard({
    required this.alat,
    required this.rental,
    required this.onTap,
  });

  String get _hargaFormatted {
    final harga = alat.hargaPerHari.toInt();
    if (harga >= 1000) {
      final compact = harga / 1000;
      final text = compact == compact.roundToDouble()
          ? compact.toInt().toString()
          : compact.toStringAsFixed(1).replaceAll('.0', '');
      return 'Rp ${text}k';
    }
    return 'Rp $harga';
  }

  bool get _isTersedia => alat.isAvailable && alat.stock > 0;

  bool get _prioritizeSizeCategory {
    final kategori = alat.namaKategori?.toLowerCase() ?? '';
    return kategori.contains('pakaian') || kategori.contains('alas kaki');
  }

  List<String> get _specChips {
    final specs = <String>[];
    final sizes = alat.availableSizes;

    if (_prioritizeSizeCategory && sizes.isNotEmpty) {
      specs.add(
        sizes.length == 1 ? 'Size ${sizes.first}' : '${sizes.length} Size',
      );
    }

    if (alat.capacity != null && alat.capacity! > 0) {
      specs.add('${alat.capacity} Org');
    }
    if (alat.weightKg != null && alat.weightKg! > 0) {
      final weight = alat.weightKg!;
      final text = weight == weight.roundToDouble()
          ? '${weight.toInt()} Kg'
          : '${weight.toStringAsFixed(1)} Kg';
      specs.add(text);
    }
    if (!_prioritizeSizeCategory && specs.length < 2) {
      if (!_prioritizeSizeCategory && sizes.isNotEmpty) {
        specs.add(
          sizes.length == 1 ? 'Size ${sizes.first}' : 'Size ${sizes.first}',
        );
      }
    }
    return specs.take(_prioritizeSizeCategory ? 3 : 2).toList(growable: false);
  }

  void _handleTambah(BuildContext context) {
    if (!_isTersedia) {
      NrToast.show(
        context,
        'Maaf, alat tidak tersedia',
        type: NrToastType.info,
      );
      return;
    }

    final sizes = alat.availableSizes;
    if (sizes.length > 1) {
      NrToast.show(
        context,
        'Pilih ukuran terlebih dahulu di detail peralatan.',
        type: NrToastType.info,
      );
      return;
    }

    CartService().tambah(
      alat,
      rental,
      selectedSize: sizes.length == 1 ? sizes.first : null,
    );
    NrToast.show(
      context,
      'Produk ditambahkan ke keranjang.',
      type: NrToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
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
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                    height: 162,
                    width: double.infinity,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: NrImage(
                      imageUrl: alat.gambarprimaryUrl,
                      width: double.infinity,
                      height: 162,
                      fit: BoxFit.cover,
                      placeholderColor: const Color(0xFF2D4A2D),
                      placeholderIcon: Icons.inventory_2_outlined,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _isTersedia
                            ? AppColors.primaryLight
                            : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _isTersedia ? 'Tersedia' : 'Habis',
                        style: AppTextStyles.caption.copyWith(
                          color: _isTersedia
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 24),
                  child: _specChips.isEmpty
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.topLeft,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _specChips
                                .map(
                                  (label) => _SpecChip(
                                    label: label,
                                    isPrimary: label == _specChips.first,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Text(
                  alat.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _hargaFormatted,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            TextSpan(
                              text: '/hari',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleTambah(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _isTersedia
                              ? AppColors.primaryDark
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isTersedia
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryDark.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: _isTersedia
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
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
  final bool isPrimary;

  const _SpecChip({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primaryDark.withValues(alpha: 0.88)
            : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: isPrimary ? Colors.white : AppColors.primaryDark,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
