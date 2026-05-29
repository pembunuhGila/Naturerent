import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/equipment.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/equipment_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/widgets/nr_image.dart';
import '../../core/widgets/nr_toast.dart';
import '../checkout/checkout_page.dart';
import 'equipment_detail_page.dart';

class EquipmentListPage extends StatefulWidget {
  final RentalProfile rental;
  const EquipmentListPage({super.key, required this.rental});

  @override
  State<EquipmentListPage> createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> {
  final _equipmentService = EquipmentService();

  List<Equipment> _semuaAlat = [];
  List<Equipment> _alatFiltered = [];
  List<Map<String, dynamic>> _kategori = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedKategoriId; // null = Semua

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _equipmentService.ambilAlatByRental(widget.rental.id),
        _equipmentService.ambilKategori(),
      ]);
      if (!mounted) return;
      setState(() {
        _semuaAlat = results[0] as List<Equipment>;
        _kategori  = results[1] as List<Map<String, dynamic>>;
        _alatFiltered = _semuaAlat;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Gagal memuat data. Tarik untuk muat ulang.'; _isLoading = false; });
    }
  }

  void _filterKategori(String? kategoriId) {
    setState(() {
      _selectedKategoriId = kategoriId;
      _alatFiltered = kategoriId == null
          ? _semuaAlat
          : _semuaAlat.where((a) => a.categoryId == kategoriId).toList();
    });
  }

  // ── Icon untuk tiap kategori berdasarkan nama
  IconData _iconKategori(String? nama) {
    switch (nama?.toLowerCase()) {
      case 'tenda':           return Icons.cabin_rounded;
      case 'sleeping bag':    return Icons.airline_seat_flat_rounded;
      case 'carrier / tas':   return Icons.backpack_rounded;
      case 'matras':          return Icons.horizontal_rule_rounded;
      case 'kompor & masak':  return Icons.outdoor_grill_rounded;
      case 'lampu & senter':  return Icons.flashlight_on_rounded;
      case 'pakaian':         return Icons.checkroom_rounded;
      case 'navigasi':        return Icons.explore_rounded;
      case 'p3k':             return Icons.medical_services_rounded;
      default:                return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _muatData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header rental
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Filter kategori
              if (_kategori.isNotEmpty)
                SliverToBoxAdapter(child: _buildKategoriFilter()),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentDetailPage(
                            equipmentId: _alatFiltered[i].id,
                            rental: widget.rental,
                          ),
                        ),
                      ),
                      onSewa: () {
                        CartService().tambah(_alatFiltered[i], widget.rental);
                        NrToast.show(
                          context,
                          '${_alatFiltered[i].nama} ditambahkan ke keranjang',
                          type: NrToastType.success,
                          duration: const Duration(seconds: 2),
                        );
                      },
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

  // ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // App bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.rental.namaRental,
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Cart icon with badge
              ValueListenableBuilder<int>(
                valueListenable: CartService().count,
                builder: (_, count, widget) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckoutPage()),
                      ),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: AppColors.textPrimary, size: 18),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4, right: -4,
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
        ),

        // Banner + info rental
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Foto banner rental
                NrImage(
                  imageUrl: widget.rental.fotoBanner,
                  width: 56, height: 56,
                  borderRadius: BorderRadius.circular(12),
                  placeholderColor: AppColors.primaryDark,
                  placeholderIcon: Icons.storefront_rounded,
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
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.textHint, size: 13),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              widget.rental.alamat ?? 'Lokasi tidak tersedia',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textHint),
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
            onTap: () => _filterKategori(isAll ? null : kategori?['id'] as String?),
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
                    isAll ? Icons.grid_view_rounded : _iconKategori(kategori?['nama'] as String?),
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAll ? 'Semua' : (kategori?['nama'] as String? ?? '').split(' ').first,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
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
          Text('Belum ada alat', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 6),
          Text('Rental ini belum menambahkan\nperalatan camping.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
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
          Text(_error!, textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _muatData,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: Text('Coba Lagi', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  CARD ALAT
// ──────────────────────────────────────────────────────────
class _AlatCard extends StatelessWidget {
  final Equipment alat;
  final String namaRental;
  final VoidCallback onTap;
  final VoidCallback onSewa;

  const _AlatCard({
    required this.alat,
    required this.namaRental,
    required this.onTap,
    required this.onSewa,
  });

  String get _hargaFormatted {
    final harga = alat.hargaPerHari.toInt();
    if (harga >= 1000) {
      return 'Rp ${(harga / 1000).toStringAsFixed(harga % 1000 == 0 ? 0 : 1)}k';
    }
    return 'Rp $harga';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ── Foto alat
                NrImage(
                  imageUrl: alat.gambarprimaryUrl,
                  width: 88, height: 88,
                  borderRadius: BorderRadius.circular(12),
                  placeholderColor: const Color(0xFF2D4A2D),
                  placeholderIcon: Icons.inventory_2_outlined,
                ),

                const SizedBox(width: 14),

                // ── Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama alat
                      Text(
                        alat.nama,
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // Nama rental
                      Text(
                        namaRental,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Harga + kategori
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Harga
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _hargaFormatted,
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: '/hr',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textHint),
                                ),
                              ],
                            ),
                          ),

                          // Badge kategori
                          if (alat.namaKategori != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                alat.namaKategori!.split(' ').first,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Stok tersedia
                          Row(
                          children: [
                            Icon(
                              alat.stock > 0 ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                              size: 13,
                              color: alat.stock > 0 ? AppColors.primary : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                alat.stock > 0
                                    ? '${alat.stock} unit tersedia'
                                    : 'Stok habis',
                                style: AppTextStyles.caption.copyWith(
                                  color: alat.stock > 0 ? AppColors.primary : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // ── Tombol Sewa
                            GestureDetector(
                              onTap: alat.stock > 0 ? onSewa : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: alat.stock > 0
                                      ? AppColors.primaryDark
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Sewa',
                                  style: AppTextStyles.caption.copyWith(
                                    color: alat.stock > 0
                                        ? Colors.white
                                        : AppColors.textHint,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
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

class _AlatShowcaseCard extends StatelessWidget {
  final Equipment alat;
  final String namaRental;
  final VoidCallback onTap;
  final VoidCallback onSewa;

  const _AlatShowcaseCard({
    required this.alat,
    required this.namaRental,
    required this.onTap,
    required this.onSewa,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                NrImage(
                  imageUrl: alat.gambarprimaryUrl,
                  width: double.infinity,
                  height: 236,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(18),
                  placeholderColor: const Color(0xFF2D4A2D),
                  placeholderIcon: Icons.inventory_2_outlined,
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: alat.stock > 0
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      alat.stock > 0 ? 'TERSEDIA' : 'STOK HABIS',
                      style: AppTextStyles.caption.copyWith(
                        color:
                            alat.stock > 0 ? AppColors.primaryDark : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alat.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alat.deskripsi ?? namaRental,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _hargaFormatted,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/HARI',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (alat.namaKategori != null)
                  _SpecChip(label: alat.namaKategori!),
                const SizedBox(width: 6),
                _SpecChip(label: '${alat.stock} unit'),
                const Spacer(),
                GestureDetector(
                  onTap: alat.stock > 0 ? onSewa : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          alat.stock > 0 ? AppColors.primaryDark : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_shopping_cart_rounded,
                      color: alat.stock > 0 ? Colors.white : AppColors.textHint,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
