import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/equipment.dart';
import '../../core/services/equipment_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_image.dart';

class OwnerInventoryPage extends StatefulWidget {
  const OwnerInventoryPage({super.key});

  @override
  State<OwnerInventoryPage> createState() => _OwnerInventoryPageState();
}

class _OwnerInventoryPageState extends State<OwnerInventoryPage> {
  final _rentalService = RentalService();
  final _equipmentService = EquipmentService();

  List<Equipment> _alat = [];
  bool _loading = true;
  String? _error;
  String? _rentalId;

  @override
  void initState() {
    super.initState();
    _muatAlat();
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
        _rentalId = rental?.id;
        _alat = alat;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data alat.';
        _loading = false;
      });
    }
  }

  void _comingSoon(String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fitur segera hadir.'),
        backgroundColor: AppColors.primaryDark,
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _muatAlat,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: _StateView(
                    icon: Icons.wifi_off_rounded,
                    title: _error!,
                    body: 'Tarik layar ke bawah untuk mencoba ulang.',
                  ),
                )
              else if (_rentalId == null)
                const SliverFillRemaining(
                  child: _StateView(
                    icon: Icons.storefront_rounded,
                    title: 'Profil rental belum dibuat',
                    body: 'Buat profil rental sebelum menambahkan alat.',
                  ),
                )
              else if (_alat.isEmpty)
                const SliverFillRemaining(
                  child: _StateView(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada alat',
                    body: 'Daftar alat yang kamu sewakan akan tampil di sini.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _InventoryCard(
                      alat: _alat[index],
                      onEdit: () => _comingSoon('Edit alat'),
                    ),
                    childCount: _alat.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _comingSoon('Tambah alat'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Alat'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventaris Alat',
                  style: AppTextStyles.headlineLarge.copyWith(fontSize: 20),
                ),
                Text(
                  '${_alat.length} alat terdaftar',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _muatAlat,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Equipment alat;
  final VoidCallback onEdit;

  const _InventoryCard({required this.alat, required this.onEdit});

  String _fmtRupiah(double value) {
    final s = value.toInt().toString();
    final buf = StringBuffer('Rp ');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = alat.isAvailable ? AppColors.primary : AppColors.error;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          NrImage(
            imageUrl: alat.gambarprimaryUrl,
            width: 74,
            height: 74,
            borderRadius: BorderRadius.circular(12),
            placeholderIcon: Icons.inventory_2_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat.namaKategori?.toUpperCase() ?? 'ALAT',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alat.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmtRupiah(alat.hargaPerHari)} / hari',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    _Badge(
                      label: 'STOK ${alat.stock}',
                      color: AppColors.primary,
                    ),
                    _Badge(
                      label: alat.isAvailable ? 'TAYANG' : 'DISEMBUNYIKAN',
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _StateView({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
