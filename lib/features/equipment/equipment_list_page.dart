import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/equipment.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/equipment_service.dart';
import '../../core/widgets/nr_image.dart';
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
                    (_, i) => _AlatCard(
                      alat: _alatFiltered[i],
                      namaRental: widget.rental.namaRental,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentDetailPage(
                            equipmentId: _alatFiltered[i].id,
                            namaRental: widget.rental.namaRental,
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
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.textPrimary, size: 18),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.rental.namaRental,
                              style: AppTextStyles.headlineMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Buka Sekarang',
                                style: AppTextStyles.caption.copyWith(
                                    color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
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
                          if (widget.rental.noWa != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_rounded,
                                      size: 10,
                                      color: Color(0xFF25D366)),
                                  const SizedBox(width: 3),
                                  Text('WA',
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFF25D366),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                      )),
                                ],
                              ),
                            ),
                          ],
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

  const _AlatCard({
    required this.alat,
    required this.namaRental,
    required this.onTap,
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
                          Text(
                            alat.stock > 0
                                ? '${alat.stock} unit tersedia'
                                : 'Stok habis',
                            style: AppTextStyles.caption.copyWith(
                              color: alat.stock > 0 ? AppColors.primary : AppColors.error,
                              fontWeight: FontWeight.w600,
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
