import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/equipment.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/equipment_service.dart';
import '../../core/widgets/nr_image.dart';
import '../../core/widgets/nr_toast.dart';

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

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _equipmentService.ambilDetailAlat(widget.equipmentId);
      if (!mounted) return;
      setState(() { _alat = data; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Gagal memuat detail alat.'; _isLoading = false; });
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textHint),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Deskripsi (jika ada)
                      if (alat.deskripsi != null && alat.deskripsi!.isNotEmpty) ...[
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
    return Stack(
      children: [
        // ── Foto utama
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (gambar.length <= 1) return;
            if (details.primaryVelocity! < 0) {
              setState(() => _fotoIndex = (_fotoIndex + 1) % gambar.length);
            } else {
              setState(() => _fotoIndex = (_fotoIndex - 1 + gambar.length) % gambar.length);
            }
          },
          child: NrImage(
            imageUrl: gambar.isNotEmpty ? gambar[_fotoIndex] : null,
            width: double.infinity,
            height: 300,
            placeholderColor: AppColors.primaryDark,
            placeholderIcon: Icons.inventory_2_outlined,
          ),
        ),

        // ── Gradient bawah
        Positioned(
          bottom: 0, left: 0, right: 0, height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.background.withValues(alpha: 0.95)],
              ),
            ),
          ),
        ),

        // ── Back button
        Positioned(
          top: 44, left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),

        // ── Notif button
        // ── Foto indicator dots (jika lebih dari 1)
        if (gambar.length > 1)
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(gambar.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _fotoIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _fotoIndex ? AppColors.primary : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

        // ── Title di header
        Positioned(
          top: 44, left: 0, right: 0,
          child: Center(
            child: Text(
              'Detail Peralatan',
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 8),
                ],
              ),
            ),
          ),
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
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
            blurRadius: 12, offset: const Offset(0, -3),
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
                    CartService().tambah(alat, widget.rental);
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
                  borderRadius: BorderRadius.circular(14)),
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
            Icon(Icons.error_outline_rounded, size: 52, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _muatDetail,
              child: Text('Coba Lagi', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
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
        child: Text('Alat tidak ditemukan.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
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
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color, fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
