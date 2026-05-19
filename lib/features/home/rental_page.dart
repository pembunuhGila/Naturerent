import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/rental_service.dart';
import '../../core/widgets/nr_image.dart';
import '../equipment/equipment_list_page.dart';

class RentalPage extends StatefulWidget {
  /// Jika [wisataId] diisi, hanya tampilkan rental dekat wisata tersebut.
  final String? wisataId;
  final String? namaWisata;

  const RentalPage({super.key, this.wisataId, this.namaWisata});

  @override
  State<RentalPage> createState() => _RentalPageState();
}

class _RentalPageState extends State<RentalPage> {
  final _rentalService = RentalService();

  List<RentalProfile> _semuaRental = [];
  List<RentalProfile> _rentalFiltered = [];
  bool _isLoading = true;
  String? _error;

  // Filter kategori (nanti bisa dari equipment_categories)
  int _selectedFilter = 0;
  final List<String> _filters = ['Semua', 'Tenda', 'Carrier', 'Sleeping Bag', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _muatRental();
  }

  Future<void> _muatRental() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = widget.wisataId != null
          ? await _rentalService.ambilRentalDekatWisata(widget.wisataId!)
          : await _rentalService.ambilRentalAktif();
      if (!mounted) return;
      setState(() {
        _semuaRental = data;
        _rentalFiltered = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data rental. Tarik untuk muat ulang.';
        _isLoading = false;
      });
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
          onRefresh: _muatRental,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App Bar
              SliverToBoxAdapter(child: _buildAppBar()),

              // ── Filter chips
              SliverToBoxAdapter(child: _buildFilterChips()),

              // ── Section header
              SliverToBoxAdapter(child: _buildSectionHeader()),

              // ── Content
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
                    (context, index) =>
                        _RentalCard(rental: _rentalFiltered[index]),
                    childCount: _rentalFiltered.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final isFiltered = widget.wisataId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Tombol back jika dibuka dari wisata card
          if (isFiltered) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 16),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFiltered)
                  Text(
                    widget.namaWisata ?? 'Destinasi',
                    style: AppTextStyles.headlineLarge
                        .copyWith(color: AppColors.textPrimary, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Rental di sekitarmu',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
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
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final isSelected = i == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                _filters[i],
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    final isFiltered = widget.wisataId != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFiltered ? 'Rental di Area Ini' : 'Rental Terdekat',
                style: AppTextStyles.headlineLarge
                    .copyWith(color: AppColors.textPrimary),
              ),
              Text(
                isFiltered
                    ? '${_semuaRental.length} rental tersedia'
                    : 'Kurasi terbaik di sekitarmu',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 52, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('Belum ada rental',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.textHint)),
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
          Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textHint)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _muatRental,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: Text('Coba Lagi',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  RENTAL CARD
// ──────────────────────────────────────────────────────────

class _RentalCard extends StatelessWidget {
  final RentalProfile rental;
  const _RentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EquipmentListPage(rental: rental),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ── Foto Banner (dari foto_banner di DB)
                NrImage(
                  imageUrl: rental.fotoBanner, // null → placeholder
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(12),
                  placeholderColor: AppColors.primaryDark,
                  placeholderIcon: Icons.storefront_rounded,
                ),

                const SizedBox(width: 14),

                // ── Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama rental
                      Text(
                        rental.namaRental,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Jarak & jam operasional
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            rental.alamat ?? '—',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Badge status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rental.isActive ? 'Aktif' : 'Tutup',
                          style: AppTextStyles.caption.copyWith(
                            color: rental.isActive
                                ? AppColors.primary
                                : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
