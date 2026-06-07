import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/equipment.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/equipment_service.dart';
import '../../core/widgets/nr_image.dart';
import '../../core/widgets/nr_toast.dart';
import '../checkout/checkout_page.dart';
import '../home/rental_detail_page.dart';

class EquipmentDetailPage extends StatefulWidget {
  final String equipmentId;
  final RentalProfile rental;

  const EquipmentDetailPage({
    super.key,
    required this.equipmentId,
    required this.rental,
  });

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  final _equipmentService = EquipmentService();

  Equipment? _alat;
  bool _isLoading = true;
  String? _error;
  int _fotoIndex = 0; // index foto yang aktif di gallery
  String? _selectedSize; // ukuran yang dipilih user

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _equipmentService.ambilDetailAlat(widget.equipmentId);
      if (!mounted) return;
      setState(() {
        _alat = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat detail alat.';
        _isLoading = false;
      });
    }
  }

  String _formatHarga(double harga) {
    final h = harga.toInt();
    if (h >= 1000000) return 'Rp ${(h / 1000000).toStringAsFixed(1)}jt';
    if (h >= 1000) {
      final rb = h ~/ 1000;
      final sisa = h % 1000;
      return sisa == 0 ? 'Rp ${rb}k' : 'Rp $h';
    }
    return 'Rp $h';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _buildErrorState()
          : _alat == null
          ? _buildNotFound()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final alat = _alat!;
    final gambar = alat.semuaGambar;

    return Column(
      children: [
        // ── Foto area (scrollable content atas)
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Hero foto
              SliverToBoxAdapter(child: _buildFotoHero(gambar)),

              // ── Info area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori label
                      if (alat.namaKategori != null)
                        Text(
                          alat.namaKategori!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Nama alat
                      Text(
                        alat.nama,
                        style: AppTextStyles.displayMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Harga
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatHarga(alat.hargaPerHari),
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3, left: 4),
                            child: Text(
                              '/ Hari',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Size selector (jika ada)
                      if (alat.size != null &&
                          alat.size!.trim().isNotEmpty) ...[
                        _buildSizeSelector(alat),
                        const SizedBox(height: 20),
                      ],

                      // ── Deskripsi (jika ada)
                      if (alat.deskripsi != null &&
                          alat.deskripsi!.isNotEmpty) ...[
                        Text(
                          'DESKRIPSI',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alat.deskripsi!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Spesifikasi chips
                      Text(
                        'SPESIFIKASI',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SpecChip(
                            icon: Icons.inventory_2_outlined,
                            label: 'Stok: ${alat.stock}',
                          ),
                          _SpecChip(
                            icon: Icons.category_outlined,
                            label: alat.namaKategori ?? 'Umum',
                          ),
                          if (alat.size != null && alat.size!.isNotEmpty)
                            _SpecChip(
                              icon: Icons.straighten_rounded,
                              label: 'Size: ${alat.size}',
                            ),
                          if (alat.capacity != null && alat.capacity! > 0)
                            _SpecChip(
                              icon: Icons.people_outline_rounded,
                              label: 'Kapasitas: ${alat.capacity} orang',
                            ),
                          if (alat.weightKg != null && alat.weightKg! > 0)
                            _SpecChip(
                              icon: Icons.fitness_center_rounded,
                              label: 'Berat: ${alat.weightKg!.toStringAsFixed(alat.weightKg! == alat.weightKg!.roundToDouble() ? 0 : 1)} kg',
                            ),
                          if (alat.isAvailable)
                            _SpecChip(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Tersedia',
                              isHighlight: true,
                            )
                          else
                            _SpecChip(
                              icon: Icons.cancel_outlined,
                              label: 'Tidak Tersedia',
                              isDanger: true,
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Ketersediaan card
                      _buildKetersediaanCard(alat),

                      const SizedBox(height: 14),

                      _buildRentalInfoCard(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom CTA
        _buildBottomCTA(alat),
      ],
    );
  }

  Widget _buildFotoHero(List<String> gambar) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Detail Peralatan',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: CartService().count,
                    builder: (builderContext, count, child) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutPage(),
                            ),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
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
            ),
          ),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (gambar.length <= 1) return;
              if (details.primaryVelocity! < 0) {
                setState(() => _fotoIndex = (_fotoIndex + 1) % gambar.length);
              } else {
                setState(
                  () => _fotoIndex =
                      (_fotoIndex - 1 + gambar.length) % gambar.length,
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 300,
              color: Colors.white,
              alignment: Alignment.center,
              child: NrImage(
                imageUrl: gambar.isNotEmpty ? gambar[_fotoIndex] : null,
                width: double.infinity,
                height: 300,
                fit: BoxFit.contain,
                placeholderColor: AppColors.primaryDark,
                placeholderIcon: Icons.inventory_2_outlined,
              ),
            ),
          ),
          if (gambar.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(gambar.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _fotoIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _fotoIndex
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector(Equipment alat) {
    final sizeMap = alat.sizeStockMap;
    if (sizeMap.isEmpty) return const SizedBox.shrink();

    // Jika hanya 1 size, tampilkan info saja tanpa pilihan
    if (sizeMap.length == 1) {
      final entry = sizeMap.entries.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UKURAN',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${entry.key}  •  ${entry.value} unit',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    // Multi-size: tampilkan pilihan chips dengan info stok
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PILIH UKURAN',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizeMap.entries.map((entry) {
            final size = entry.key;
            final stock = entry.value;
            final isSelected = _selectedSize == size;
            final isAvailable = stock > 0;
            return GestureDetector(
              onTap: isAvailable
                  ? () => setState(() => _selectedSize = size)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: !isAvailable
                      ? AppColors.surface.withValues(alpha: 0.5)
                      : isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: !isAvailable
                        ? AppColors.border.withValues(alpha: 0.5)
                        : isSelected
                            ? AppColors.primary
                            : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      size,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: !isAvailable
                            ? AppColors.textHint
                            : isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable ? '$stock unit' : 'Habis',
                      style: AppTextStyles.caption.copyWith(
                        color: !isAvailable
                            ? AppColors.textHint
                            : isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildKetersediaanCard(Equipment alat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alat.isAvailable && alat.stock > 0
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alat.isAvailable && alat.stock > 0
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            alat.isAvailable && alat.stock > 0
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: alat.isAvailable && alat.stock > 0
                ? AppColors.primary
                : AppColors.error,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat.isAvailable && alat.stock > 0
                      ? 'Tersedia Sekarang'
                      : 'Tidak Tersedia',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: alat.isAvailable && alat.stock > 0
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alat.stock > 0
                      ? '${alat.stock} unit tersedia di ${widget.rental.namaRental}'
                      : 'Stok sedang habis',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalInfoCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RentalDetailPage(rental: widget.rental),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipOval(
              child: NrImage(
                imageUrl: widget.rental.fotoProfil,
                width: 50,
                height: 50,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.rental.alamat ?? 'Alamat toko belum tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA(Equipment alat) {
    final bisa = alat.isAvailable && alat.stock > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: bisa
                ? () {
                    // Validasi: jika ada pilihan size tapi belum dipilih
                    final sizeMap = alat.sizeStockMap;
                    if (sizeMap.length > 1 && _selectedSize == null) {
                      NrToast.show(
                        context,
                        'Pilih ukuran terlebih dahulu',
                        type: NrToastType.info,
                      );
                      return;
                    }
                    final sizeToSend = sizeMap.length > 1
                        ? _selectedSize
                        : (sizeMap.length == 1 ? sizeMap.keys.first : null);
                    CartService().tambah(alat, widget.rental, selectedSize: sizeToSend);
                    NrToast.show(
                      context,
                      '${alat.nama} ditambahkan ke keranjang',
                      type: NrToastType.success,
                      duration: const Duration(seconds: 2),
                    );
                  }
                : null,
            icon: const Icon(Icons.shopping_basket_outlined, size: 20),
            label: Text(
              bisa ? 'Tambahkan ke Pesanan' : 'Stok Tidak Tersedia',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: bisa ? AppColors.primary : AppColors.textHint,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _muatDetail,
              child: Text(
                'Coba Lagi',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Alat tidak ditemukan.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  SPEC CHIP
// ──────────────────────────────────────────────────────────
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;
  final bool isDanger;

  const _SpecChip({
    required this.icon,
    required this.label,
    this.isHighlight = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? AppColors.error
        : isHighlight
        ? AppColors.primary
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
