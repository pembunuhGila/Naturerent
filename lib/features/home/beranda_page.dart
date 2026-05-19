import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/wisata_location.dart';
import '../../core/services/rental_service.dart';
import '../../core/widgets/nr_image.dart';
import '../home/rental_page.dart';
import '../home/wisata_detail_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _searchController = TextEditingController();
  final _rentalService = RentalService();

  int _selectedFilter = 0;
  final List<String> _filters = ['Semua', 'Gunung', 'Ranu', 'Hutan', 'Pantai'];

  // State
  List<WisataLocation> _semuaWisata = [];
  List<WisataLocation> _wisataFiltered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatWisata();
    _searchController.addListener(_filterWisata);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterWisata);
    _searchController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  //  DATA LOADING
  // ──────────────────────────────────────────────────────────

  Future<void> _muatWisata() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _rentalService.ambilSemuaWisata();
      if (!mounted) return;
      setState(() {
        _semuaWisata = data;
        _wisataFiltered = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat destinasi. Tarik untuk muat ulang.';
        _isLoading = false;
      });
    }
  }

  void _filterWisata() {
    final query = _searchController.text.toLowerCase().trim();
    final kategori = _selectedFilter == 0
        ? null
        : _filters[_selectedFilter]; // 'Gunung', 'Ranu', dst.

    setState(() {
      _wisataFiltered = _semuaWisata.where((w) {
        final matchQuery = query.isEmpty ||
            w.nama.toLowerCase().contains(query) ||
            (w.deskripsi?.toLowerCase().contains(query) ?? false);
        final matchKategori =
            kategori == null || w.kategori == kategori;
        return matchQuery && matchKategori;
      }).toList();
    });
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────

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
          onRefresh: _muatWisata,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(child: _buildHeadline()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFilterChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),

              // ── Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: _buildErrorState(),
                )
              else if (_wisataFiltered.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _WisataCard(wisata: _wisataFiltered[index]),
                    childCount: _wisataFiltered.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.park_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 6),
              Text(
                'NatureRent',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primaryDark,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.displayLarge,
          children: [
            const TextSpan(text: 'Pilih Destinasi\n'),
            TextSpan(
              text: 'Petualanganmu!',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari destinasi petualanganmu...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final isSelected = i == _selectedFilter;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = i);
              _filterWisata();
            },
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
                  color:
                      isSelected ? AppColors.white : AppColors.textSecondary,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off_rounded,
              size: 52, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'Belum ada destinasi',
            style: AppTextStyles.headlineMedium
                .copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 6),
          Text(
            'Data akan muncul setelah admin\nmenambahkan lokasi wisata.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textHint),
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
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _muatWisata,
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
//  CARD WIDGET
// ──────────────────────────────────────────────────────────

class _WisataCard extends StatelessWidget {
  final WisataLocation wisata;
  const _WisataCard({required this.wisata});

  // Warna placeholder berbeda-beda berdasarkan index nama (biar beda warna tiap card)
  static const List<Color> _placeholderColors = [
    Color(0xFF2D4A2D),
    Color(0xFF1A2B3C),
    Color(0xFF3B2A1A),
    Color(0xFF1A3020),
    Color(0xFF2A1A3B),
  ];

  @override
  Widget build(BuildContext context) {
    final colorIndex = wisata.nama.length % _placeholderColors.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Gambar dari kolom foto_url di tabel wisata_locations
            NrImage(
              imageUrl: wisata.fotoUrl,
              width: double.infinity,
              height: 200,
              placeholderColor: _placeholderColors[colorIndex],
              placeholderIcon: Icons.landscape_rounded,
            ),

            // ── Dark gradient overlay
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 130,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Badge kategori kanan atas (ganti rating)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.landscape_rounded,
                        color: AppColors.primary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      wisata.kategori ?? 'Wisata',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Teks info bawah
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESTINASI WISATA',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white60,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wisata.nama,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (wisata.deskripsi != null &&
                        wisata.deskripsi!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        wisata.deskripsi!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white60),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Seluruh area clickable → ke WisataDetailPage
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WisataDetailPage(wisata: wisata),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
