import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/equipment.dart';
import '../../core/models/rental_profile.dart';
import '../../core/services/equipment_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_image.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  final _rentalService = RentalService();
  final _equipmentService = EquipmentService();

  RentalProfile? _rental;
  List<Equipment> _alat = [];
  bool _loading = true;
  String? _error;

  int get _alatAktif => _alat.where((e) => e.isAvailable).length;
  int get _totalStok => _alat.fold(0, (sum, e) => sum + e.stock);

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
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
        _rental = rental;
        _alat = alat;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat dashboard pemilik.';
        _loading = false;
      });
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
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _muatData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                _buildStateCard(
                  icon: Icons.wifi_off_rounded,
                  title: _error!,
                  body: 'Tarik layar ke bawah untuk mencoba ulang.',
                )
              else if (_rental == null)
                _buildStateCard(
                  icon: Icons.storefront_rounded,
                  title: 'Profil rental belum dibuat',
                  body:
                      'Lengkapi profil usaha agar alat rental bisa tampil untuk penyewa.',
                )
              else ...[
                _buildRentalCard(_rental!),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.inventory_2_rounded,
                        label: 'Alat Aktif',
                        value: '$_alatAktif',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.warehouse_rounded,
                        label: 'Total Stok',
                        value: '$_totalStok',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pending_actions_rounded,
                        label: 'Pesanan Baru',
                        value: '0',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_rounded,
                        label: 'Omzet Hari Ini',
                        value: 'Rp0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildSectionTitle('Alat Terbaru'),
                const SizedBox(height: 10),
                if (_alat.isEmpty)
                  _buildStateCard(
                    icon: Icons.add_box_outlined,
                    title: 'Belum ada alat',
                    body: 'Tambahkan data alat dari tab Alat.',
                  )
                else
                  ..._alat
                      .take(3)
                      .map((alat) => _EquipmentMiniCard(alat: alat)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Pemilik',
                style: AppTextStyles.headlineLarge.copyWith(fontSize: 20),
              ),
              Text(
                'Pantau rental dan stok alatmu',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildRentalCard(RentalProfile rental) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          NrImage(
            imageUrl: rental.fotoBanner,
            width: 72,
            height: 72,
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
                  rental.namaRental,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rental.alamat ?? 'Alamat belum diisi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusBadge(
                  label: rental.isActive ? 'AKTIF' : 'NONAKTIF',
                  color: rental.isActive ? AppColors.primary : AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.textHint),
          const SizedBox(height: 10),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentMiniCard extends StatelessWidget {
  final Equipment alat;
  const _EquipmentMiniCard({required this.alat});

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          NrImage(
            imageUrl: alat.gambarprimaryUrl,
            width: 58,
            height: 58,
            borderRadius: BorderRadius.circular(10),
            placeholderIcon: Icons.inventory_2_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_fmtRupiah(alat.hargaPerHari)} / hari',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(
            label: 'STOK ${alat.stock}',
            color: alat.stock > 0 ? AppColors.primary : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
