import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/order_activity_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_image.dart';
import '../checkout/pesanan_detail_page.dart';

class AktivitasPage extends StatefulWidget {
  /// 0 = Notifikasi, 1 = Pesanan Aktif, 2 = Riwayat
  final int initialTab;

  const AktivitasPage({super.key, this.initialTab = 0});

  @override
  State<AktivitasPage> createState() => _AktivitasPageState();
}

class _AktivitasPageState extends State<AktivitasPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    OrderActivityService().muatDariDatabase();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  Text(
                    'Aktivitas Saya',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _tabCtrl.animateTo(0),
                    child: Container(
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle:
                    AppTextStyles.bodySmall.copyWith(fontSize: 12),
                indicator: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Notifikasi'),
                  Tab(text: 'Pesanan Aktif'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _TabNotifikasi(),
                  _TabPesananAktif(),
                  _TabRiwayat(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabNotifikasi extends StatelessWidget {
  const _TabNotifikasi();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityOrder>>(
      valueListenable: OrderActivityService().orders,
      builder: (context, orders, _) {
        if (orders.isEmpty) {
          return const _EmptyTab(
            icon: Icons.notifications_none_rounded,
            judul: 'Belum ada notifikasi',
            pesan: 'Notifikasi pesanan dan update aktivitas\nakan muncul di sini.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _NotificationCard(order: orders[index]),
        );
      },
    );
  }
}

class _TabPesananAktif extends StatelessWidget {
  const _TabPesananAktif();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityOrder>>(
      valueListenable: OrderActivityService().orders,
      builder: (context, orders, _) {
        final aktif = orders
            .where(_isActiveOrder)
            .toList(growable: false);

        if (aktif.isEmpty) {
          return const _EmptyTab(
            icon: Icons.shopping_bag_outlined,
            judul: 'Tidak ada pesanan aktif',
            pesan: 'Setelah pemilik rental ACC,\npesanan akan pindah ke sini.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          itemCount: aktif.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OrderCard(order: aktif[index]),
        );
      },
    );
  }
}

class _TabRiwayat extends StatelessWidget {
  const _TabRiwayat();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityOrder>>(
      valueListenable: OrderActivityService().orders,
      builder: (context, orders, _) {
        if (orders.isEmpty) {
          return const _EmptyTab(
            icon: Icons.history_rounded,
            judul: 'Belum ada riwayat',
            pesan: 'Pesanan dari pembayaran QRIS\nakan tampil di sini.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final ActivityOrder order;

  const _NotificationCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final waiting = order.status == ActivityOrderStatus.pending;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openOrderDetail(context, order),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (waiting ? AppColors.primary : AppColors.success)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                waiting
                    ? Icons.hourglass_top_rounded
                    : Icons.check_circle_outline_rounded,
                color: waiting ? AppColors.primaryDark : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waiting ? 'Menunggu Verifikasi' : _statusDetailLabel(order.status),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pesanan #${order.nomorPesanan}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    waiting
                        ? 'Bukti DP sudah dikirim. Admin akan cek pembayaran, lalu pemilik rental mengonfirmasi alat.'
                        : _statusDescription(order.status),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${order.namaRental} - ${_fmtRupiah(order.total)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ActivityOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final item = order.items.isNotEmpty ? order.items.first : null;
    final rentalCount = _rentalCount(order);
    final title = rentalCount > 1 ? '$rentalCount Toko Rental' : order.namaRental;
    final subtitle = '${_itemCount(order)} item disewa';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openOrderDetail(context, order),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: item == null || rentalCount > 1
                  ? Container(
                      width: 92,
                      height: 92,
                      color: AppColors.primary,
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    )
                  : NrImage(
                      imageUrl: item.equipment.gambarprimaryUrl,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_fmtTgl(order.tanggalMulai)} - ${_fmtTgl(order.tanggalSelesai)} - ${_durasi(order)} Hari',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fmtRupiah(order.total),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'Lihat',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ActivityOrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ActivityOrderStatus.pending => 'PENDING',
      ActivityOrderStatus.confirmed => 'ACC',
      ActivityOrderStatus.processing => 'PROSES',
      ActivityOrderStatus.rented => 'AKTIF',
      ActivityOrderStatus.returned => 'KEMBALI',
      ActivityOrderStatus.completed => 'SELESAI',
      ActivityOrderStatus.cancelled => 'BATAL',
    };
    final color = switch (status) {
      ActivityOrderStatus.pending => const Color(0xFFF59E0B),
      ActivityOrderStatus.confirmed => AppColors.primary,
      ActivityOrderStatus.processing => AppColors.primary,
      ActivityOrderStatus.rented => AppColors.primary,
      ActivityOrderStatus.returned => AppColors.textSecondary,
      ActivityOrderStatus.completed => AppColors.success,
      ActivityOrderStatus.cancelled => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String pesan;

  const _EmptyTab({
    required this.icon,
    required this.judul,
    required this.pesan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              judul,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _rentalCount(ActivityOrder order) {
  return order.items.map((item) => item.rental.id).toSet().length;
}

int _itemCount(ActivityOrder order) {
  return order.items.fold<int>(0, (sum, item) => sum + item.qty);
}

void _openOrderDetail(BuildContext context, ActivityOrder order) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PesananDetailPage(
        namaRental: order.namaRental,
        total: order.total,
        tanggalMulai: order.tanggalMulai,
        tanggalSelesai: order.tanggalSelesai,
        items: order.items,
        nomorPesanan: order.nomorPesanan,
        statusLabel: _statusDetailLabel(order.status),
      ),
    ),
  );
}

String _statusDetailLabel(ActivityOrderStatus status) {
  return switch (status) {
    ActivityOrderStatus.pending => 'MENUNGGU ADMIN',
    ActivityOrderStatus.confirmed => 'SUDAH ACC',
    ActivityOrderStatus.processing => 'DIPROSES',
    ActivityOrderStatus.rented => 'PESANAN AKTIF',
    ActivityOrderStatus.returned => 'DIKEMBALIKAN',
    ActivityOrderStatus.completed => 'SELESAI',
    ActivityOrderStatus.cancelled => 'BATAL',
  };
}

String _statusDescription(ActivityOrderStatus status) {
  return switch (status) {
    ActivityOrderStatus.pending =>
      'Admin akan cek pembayaran, lalu pemilik rental mengonfirmasi alat.',
    ActivityOrderStatus.confirmed =>
      'Pemilik rental sudah ACC. Pesanan siap diproses.',
    ActivityOrderStatus.processing =>
      'Peralatan sedang disiapkan oleh pemilik rental.',
    ActivityOrderStatus.rented =>
      'Pesanan sedang aktif. Jangan lupa pelunasan saat pengembalian.',
    ActivityOrderStatus.returned =>
      'Alat sudah dikembalikan dan menunggu penyelesaian.',
    ActivityOrderStatus.completed => 'Pesanan selesai.',
    ActivityOrderStatus.cancelled => 'Pesanan dibatalkan.',
  };
}

bool _isActiveOrder(ActivityOrder order) {
  return switch (order.status) {
    ActivityOrderStatus.confirmed ||
    ActivityOrderStatus.processing ||
    ActivityOrderStatus.rented => true,
    _ => false,
  };
}

int _durasi(ActivityOrder order) {
  final days = order.tanggalSelesai.difference(order.tanggalMulai).inDays;
  return days <= 0 ? 1 : days;
}

String _fmtTgl(DateTime dt) {
  const b = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${dt.day} ${b[dt.month]} ${dt.year}';
}

String _fmtRupiah(double v) {
  final s = v.toInt().toString();
  final buf = StringBuffer('Rp ');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}
