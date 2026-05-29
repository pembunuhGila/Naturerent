import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/admin_order.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/owner_header_widget.dart';

class OwnerOrdersPage extends StatefulWidget {
  const OwnerOrdersPage({super.key});

  @override
  State<OwnerOrdersPage> createState() => _OwnerOrdersPageState();
}

class _OwnerOrdersPageState extends State<OwnerOrdersPage> {
  final RentalService _rentalService = RentalService();
  late Future<List<AdminOrder>> _futureOrders;
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _futureOrders = _loadOrders();
  }

  Future<List<AdminOrder>> _loadOrders() async {
    final rental = await RentalService().ambilRentalSaya();
    if (rental == null) return [];

    final data = await AuthService.client
        .from('bookings')
        .select('''
          id,
          booking_code,
          tgl_mulai,
          tgl_selesai,
          total_bayar,
          status,
          payment_status,
          payment_proof_url,
          created_at,
          users(nama_lengkap, email),
          rental_profiles(nama_rental),
          booking_items(
            nama_equipment,
            nama_rental,
            jumlah,
            total_harga,
            equipment(
              image_url,
              equipment_images(image_url, is_primary, sort_order)
            )
          )
        ''')
        .eq('rental_id', rental.id)
        .inFilter('status', [
          'confirmed',
          'processing',
          'rented',
          'returned',
          'completed',
        ])
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => AdminOrder.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  void _reload() {
    setState(() {
      _futureOrders = _loadOrders();
    });
  }

  List<AdminOrder> _activeOrders(List<AdminOrder> orders) {
    return orders
        .where((order) =>
            order.status == 'confirmed' ||
            order.status == 'processing' ||
            order.status == 'rented')
        .toList(growable: false);
  }

  List<AdminOrder> _historyOrders(List<AdminOrder> orders) {
    return orders
        .where((order) =>
            order.status == 'returned' || order.status == 'completed')
        .toList(growable: false);
  }

  Future<void> _confirmOrder(AdminOrder order) async {
    if (_processingId != null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Transaksi'),
        content: Text(
          'Konfirmasi bahwa transaksi ${order.bookingCode ?? order.id} sudah dilakukan oleh penyewa. Status pesanan akan diproses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    setState(() => _processingId = order.id);
    try {
      await _rentalService.konfirmasiPesananPemilik(order.id);
      if (!mounted) return;
      _showMessage('Transaksi berhasil dikonfirmasi. Pesanan diproses.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengonfirmasi transaksi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _confirmReturn(AdminOrder order) async {
    if (_processingId != null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pengembalian'),
        content: Text(
          'Konfirmasi bahwa pesanan ${order.bookingCode ?? order.id} sudah dikembalikan oleh penyewa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    setState(() => _processingId = order.id);
    try {
      await _rentalService.konfirmasiPengembalianPesananPemilik(order.id);
      if (!mounted) return;
      _showMessage('Pengembalian berhasil dikonfirmasi. Pesanan kini dikembalikan.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengonfirmasi pengembalian: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _confirmPickup(AdminOrder order) async {
    if (_processingId != null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Diambil'),
        content: Text(
          'Konfirmasi bahwa peralatan untuk pesanan ${order.bookingCode ?? order.id} sudah diambil oleh penyewa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    setState(() => _processingId = order.id);
    try {
      await _rentalService.konfirmasiPengambilanPesananPemilik(order.id);
      if (!mounted) return;
      _showMessage('Pengambilan berhasil dikonfirmasi.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengonfirmasi pengambilan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _openOrderDetail(AdminOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OwnerOrderDetailPage(order: order),
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
      backgroundColor: const Color(0xFFF8F8F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OwnerHeaderWidget(),
            Expanded(
              child: FutureBuilder<List<AdminOrder>>(
                future: _futureOrders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
                      children: [
                        _TitleRow(onReload: _reload),
                        const SizedBox(height: 18),
                        _StateBox(
                          icon: Icons.error_outline_rounded,
                          title: 'Pesanan gagal dimuat',
                          message: '${snapshot.error}',
                        ),
                      ],
                    );
                  }

                  final orders = snapshot.data ?? const <AdminOrder>[];
                  final activeOrders = _activeOrders(orders);
                  final historyOrders = _historyOrders(orders);

                  return DefaultTabController(
                    length: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                          child: _TitleRow(onReload: _reload),
                        ),
                        const SizedBox(height: 12),
                        const _OwnerOrdersTabBar(),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _OrdersTab(
                                orders: activeOrders,
                                processingId: _processingId,
                                onRefresh: () async => _reload(),
                                onOpenDetail: _openOrderDetail,
                                onConfirm: _confirmOrder,
                                onConfirmPickup: _confirmPickup,
                                onConfirmReturn: _confirmReturn,
                              ),
                              _HistoryTab(
                                orders: historyOrders,
                                onRefresh: () async => _reload(),
                                onOpenDetail: _openOrderDetail,
                              ),
                              _IncomeTab(
                                orders: historyOrders,
                                onRefresh: () async => _reload(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerOrdersTabBar extends StatelessWidget {
  const _OwnerOrdersTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F8F5),
      child: TabBar(
        labelColor: const Color(0xFF18743A),
        unselectedLabelColor: const Color(0xFF626A60),
        indicatorColor: const Color(0xFF18743A),
        indicatorWeight: 3,
        labelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
        unselectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Pesanan'),
          Tab(text: 'Riwayat'),
          Tab(text: 'Pendapatan'),
        ],
      ),
    );
  }

}

class _OrdersTab extends StatelessWidget {
  final List<AdminOrder> orders;
  final String? processingId;
  final Future<void> Function() onRefresh;
  final ValueChanged<AdminOrder> onOpenDetail;
  final Future<void> Function(AdminOrder) onConfirm;
  final Future<void> Function(AdminOrder) onConfirmPickup;
  final Future<void> Function(AdminOrder) onConfirmReturn;

  const _OrdersTab({
    required this.orders,
    required this.processingId,
    required this.onRefresh,
    required this.onOpenDetail,
    required this.onConfirm,
    required this.onConfirmPickup,
    required this.onConfirmReturn,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 118),
        children: [
          if (orders.isEmpty)
            const _StateBox(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pesanan aktif',
              message: 'Pesanan yang butuh aksi pemilik akan tampil di sini.',
            )
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _OwnerOrderCard(
                  order: order,
                  processing: processingId == order.id,
                  onConfirm: () => onConfirm(order),
                  onConfirmPickup: () => onConfirmPickup(order),
                  onConfirmReturn: () => onConfirmReturn(order),
                  onTap: () => onOpenDetail(order),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<AdminOrder> orders;
  final Future<void> Function() onRefresh;
  final ValueChanged<AdminOrder> onOpenDetail;

  const _HistoryTab({
    required this.orders,
    required this.onRefresh,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 118),
        children: [
          if (orders.isEmpty)
            const _StateBox(
              icon: Icons.history_rounded,
              title: 'Belum ada riwayat transaksi',
              message: 'Pesanan selesai akan masuk ke riwayat transaksi.',
            )
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _HistoryOrderCard(
                  order: order,
                  onTap: () => onOpenDetail(order),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IncomeTab extends StatelessWidget {
  final List<AdminOrder> orders;
  final Future<void> Function() onRefresh;

  const _IncomeTab({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final monthOrders = orders.where(_isCurrentMonth).toList(growable: false);
    final gross = monthOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalBayar,
    );
    final commission = gross * 0.1;
    final net = gross - commission;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 118),
        children: [
          _IncomeSummaryCard(total: net),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rincian Pendapatan',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: const Color(0xFF202321),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Urutkan: Terbaru',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF7D847D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (monthOrders.isEmpty)
            const _StateBox(
              icon: Icons.payments_outlined,
              title: 'Belum ada pendapatan bulan ini',
              message: 'Transaksi selesai bulan berjalan akan dihitung di sini.',
            )
          else
            ...monthOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _IncomeDetailCard(order: order),
              ),
            ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final VoidCallback onReload;

  const _TitleRow({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesanan Rental',
                style: AppTextStyles.headlineLarge.copyWith(fontSize: 20),
              ),
              Text(
                'Pesanan yang sudah disetujui admin',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF496171),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onReload,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE0E5DE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<AdminOrder> orders;

  const _SummaryStrip({required this.orders});

  @override
  Widget build(BuildContext context) {
    final waiting = orders.where((o) => o.status == 'confirmed').length;
    final processing = orders
        .where((o) => o.status == 'processing' || o.status == 'rented')
        .length;
    final finished = orders
        .where((o) => o.status == 'returned' || o.status == 'completed')
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5DE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.pending_actions_rounded,
              label: 'Baru',
              value: '$waiting',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              icon: Icons.inventory_rounded,
              label: 'Diproses',
              value: '$processing',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              icon: Icons.task_alt_rounded,
              label: 'Selesai',
              value: '$finished',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF18743A), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headlineLarge.copyWith(
            color: const Color(0xFF18743A),
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF496171),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _OwnerOrderCard extends StatelessWidget {
  final AdminOrder order;
  final bool processing;
  final VoidCallback onConfirm;
  final VoidCallback onConfirmPickup;
  final VoidCallback onConfirmReturn;
  final VoidCallback onTap;

  const _OwnerOrderCard({
    required this.order,
    required this.processing,
    required this.onConfirm,
    required this.onConfirmPickup,
    required this.onConfirmReturn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = order.items.isNotEmpty ? order.items.first : null;
    final status = _activeStatusText(order.status);
    final action = _activeActionText(order.status);
    final onAction = switch (order.status) {
      'confirmed' => onConfirm,
      'processing' => onConfirmPickup,
      'rented' => onConfirmReturn,
      _ => null,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDDE8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9D2850),
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${_shortCode(order)}',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF626A60),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _EquipmentThumb(imageUrl: item?.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF202321),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.namaUser,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF202321),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item?.namaEquipment ?? order.ringkasanAlat,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF202321),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF626A60),
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                '${_formatDate(order.tanggalMulai)} - ${_formatDate(order.tanggalSelesai)}',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF626A60),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (processing)
            const LinearProgressIndicator(color: AppColors.primary)
          else if (onAction != null)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087022),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  action,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  final AdminOrder order;
  final VoidCallback onTap;

  const _HistoryOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final item = order.items.isNotEmpty ? order.items.first : null;
    final net = _netIncome(order.totalBayar);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E5DE)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shortCode(order),
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF626A60),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.namaUser,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF202321),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const _SuccessBadge(label: 'SELESAI'),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE0E5DE)),
          Row(
            children: [
              _EquipmentThumb(imageUrl: item?.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item?.namaEquipment ?? order.ringkasanAlat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF202321),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Qty: ${item?.jumlah ?? 1} Unit',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF626A60),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE0E5DE)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF626A60),
                size: 16,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${_formatDate(order.tanggalMulai)} - ${_formatDate(order.tanggalSelesai)}',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF626A60),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Pendapatan Bersih',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF626A60),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatCurrency(net),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: const Color(0xFF087022),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _OwnerOrderDetailPage extends StatelessWidget {
  final AdminOrder order;

  const _OwnerOrderDetailPage({required this.order});

  @override
  Widget build(BuildContext context) {
    final item = order.items.isNotEmpty ? order.items.first : null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F5),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF18743A),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Detail Pesanan',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: const Color(0xFF202321),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E5DE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _shortCode(order),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF202321),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _OrderStatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _EquipmentThumb(imageUrl: item?.imageUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.namaUser,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF202321),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item?.namaEquipment ?? order.ringkasanAlat,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF626A60),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: Color(0xFFE0E5DE)),
                  _DetailInfoRow(
                    icon: Icons.calendar_month_outlined,
                    label:
                        '${_formatDate(order.tanggalMulai)} - ${_formatDate(order.tanggalSelesai)}',
                  ),
                  const SizedBox(height: 10),
                  _DetailInfoRow(
                    icon: Icons.payments_outlined,
                    label: _formatCurrency(order.totalBayar),
                  ),
                  const SizedBox(height: 10),
                  _DetailInfoRow(
                    icon: Icons.verified_outlined,
                    label: order.statusPembayaranLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _OwnerRentalTimeline(order: order),
          ],
        ),
      ),
    );
  }
}

class _OwnerRentalTimeline extends StatelessWidget {
  final AdminOrder order;

  const _OwnerRentalTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _timelineSteps(order);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proses Rental',
            style: AppTextStyles.headlineMedium.copyWith(
              color: const Color(0xFF202321),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            return _OwnerTimelineItem(
              step: entry.value,
              isLast: entry.key == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _OwnerTimelineItem extends StatelessWidget {
  final _OwnerTimelineStep step;
  final bool isLast;

  const _OwnerTimelineItem({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final dotColor = step.isDone
        ? const Color(0xFF315C3B)
        : const Color(0xFFE0E5DE);
    final lineColor = step.isDone
        ? const Color(0xFF315C3B)
        : const Color(0xFFE0E5DE);
    final titleColor = step.isDone
        ? const Color(0xFF202321)
        : const Color(0xFF8A9189);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              child: Icon(
                step.icon,
                size: 14,
                color: step.isDone ? Colors.white : const Color(0xFF9BA19A),
              ),
            ),
            if (!isLast) Container(width: 2, height: 64, color: lineColor),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.time,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF8A9189),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: AppTextStyles.caption.copyWith(
                    color: step.isDone
                        ? const Color(0xFF202321)
                        : const Color(0xFF8A9189),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerTimelineStep {
  final IconData icon;
  final String title;
  final String time;
  final String description;
  final bool isDone;

  const _OwnerTimelineStep({
    required this.icon,
    required this.title,
    required this.time,
    required this.description,
    required this.isDone,
  });
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF626A60), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF202321),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F8E1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _detailStatusLabel(status),
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF18743A),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IncomeSummaryCard extends StatelessWidget {
  final double total;

  const _IncomeSummaryCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8435),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PENDAPATAN BERSIH',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _formatCurrency(total),
            style: AppTextStyles.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '+12% dari bulan lalu',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeDetailCard extends StatelessWidget {
  final AdminOrder order;

  const _IncomeDetailCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final commission = order.totalBayar * 0.1;
    final net = _netIncome(order.totalBayar);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Transaksi',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF626A60),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _trxCode(order),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF202321),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const _SuccessBadge(label: 'Berhasil'),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE0E5DE)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Potongan Komisi (10%)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF7D847D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '-${_formatCurrency(commission)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Diterima',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF202321),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _formatCurrency(net),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF087022),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _formatDateTime(order.createdAt),
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFFB5BBAF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  final String label;

  const _SuccessBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F8E1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF18743A),
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _EquipmentThumb extends StatelessWidget {
  final String? imageUrl;

  const _EquipmentThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 52,
        height: 52,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8EFE7),
      child: const Icon(
        Icons.hiking_rounded,
        color: Color(0xFF18743A),
        size: 24,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF496171)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5DE)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7B8794), size: 54),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF496171),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatDateTime(DateTime value) {
  final date = _formatDate(value);
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$date • $hour:$minute WIB';
}

String _shortCode(AdminOrder order) {
  final code = order.bookingCode;
  if (code != null && code.isNotEmpty) return code;
  final suffix = order.id.length <= 4
      ? order.id.toUpperCase()
      : order.id.substring(order.id.length - 4).toUpperCase();
  return '#RENT-$suffix';
}

String _trxCode(AdminOrder order) {
  final suffix = order.id.length <= 5
      ? order.id.toUpperCase()
      : order.id.substring(order.id.length - 5).toUpperCase();
  return '#TRX-$suffix';
}

String _activeStatusText(String status) {
  return switch (status) {
    'confirmed' => 'MENUNGGU KONFIRMASI',
    'processing' => 'MENUNGGU DIAMBIL',
    'rented' => 'SEDANG DISEWA',
    _ => status.toUpperCase(),
  };
}

String _activeActionText(String status) {
  return switch (status) {
    'confirmed' => 'Konfirmasi Pesanan',
    'processing' => 'Konfirmasi Diambil',
    'rented' => 'Peralatan Dikembalikan',
    _ => 'Konfirmasi',
  };
}

bool _isCurrentMonth(AdminOrder order) {
  final now = DateTime.now();
  return order.createdAt.year == now.year && order.createdAt.month == now.month;
}

double _netIncome(double gross) => gross * 0.9;

List<_OwnerTimelineStep> _timelineSteps(AdminOrder order) {
  final rank = _statusRank(order.status);
  return [
    _OwnerTimelineStep(
      icon: Icons.check_rounded,
      title: 'Menunggu Konfirmasi',
      time: _formatDateTime(order.createdAt),
      description:
          'Permintaan rental telah diterima. Pemilik rental perlu mengonfirmasi pesanan ini.',
      isDone: rank >= 0,
    ),
    _OwnerTimelineStep(
      icon: Icons.sync_rounded,
      title: 'Proses',
      time: rank >= 1 ? 'Terkonfirmasi pemilik' : 'Menunggu konfirmasi',
      description:
          'Peralatan sedang disiapkan dan dicek sebelum tanggal pengambilan.',
      isDone: rank >= 1,
    ),
    _OwnerTimelineStep(
      icon: Icons.schedule_rounded,
      title: 'Pesanan telah diambil',
      time: rank >= 2 ? _formatDate(order.tanggalMulai) : 'Estimasi: ${_formatDate(order.tanggalMulai)}',
      description: 'Perlengkapan sudah berada di tangan penyewa.',
      isDone: rank >= 2,
    ),
    _OwnerTimelineStep(
      icon: Icons.inventory_2_outlined,
      title: 'Selesai',
      time: rank >= 3 ? _formatDate(order.tanggalSelesai) : _formatDate(order.tanggalSelesai),
      description: 'Peralatan dikembalikan dan diperiksa.',
      isDone: rank >= 3,
    ),
  ];
}

int _statusRank(String status) {
  return switch (status) {
    'confirmed' => 0,
    'processing' => 1,
    'rented' => 2,
    'returned' || 'completed' => 3,
    _ => 0,
  };
}

String _detailStatusLabel(String status) {
  return switch (status) {
    'confirmed' => 'MENUNGGU',
    'processing' => 'DIPROSES',
    'rented' => 'DISEWA',
    'returned' || 'completed' => 'SELESAI',
    _ => status.toUpperCase(),
  };
}

String _formatCurrency(double value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return 'Rp $buffer';
}
