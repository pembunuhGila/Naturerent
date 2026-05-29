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
          rental_profiles(nama_rental),
          booking_items(nama_equipment, nama_rental, jumlah, total_harga)
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

  Future<void> _confirmOrder(AdminOrder order) async {
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

  Future<void> _markReady(AdminOrder order) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai Pesanan Siap'),
        content: Text(
          'Tandai bahwa pesanan ${order.bookingCode ?? order.id} telah selesai diproses dan siap diambil atau dikirim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tandai Siap'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    setState(() => _processingId = order.id);
    try {
      await _rentalService.tandaiPesananSiap(order.id);
      if (!mounted) return;
      _showMessage('Notifikasi dikirim ke penyewa: pesanan siap diambil/dikirim.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menandai siap: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
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
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => _reload(),
                child: FutureBuilder<List<AdminOrder>>(
                  future: _futureOrders,
                  builder: (context, snapshot) {
                    final orders = snapshot.data ?? const <AdminOrder>[];
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                      children: [
                        _TitleRow(onReload: _reload),
                        const SizedBox(height: 18),
                        _SummaryStrip(orders: orders),
                        const SizedBox(height: 18),
                        if (snapshot.connectionState != ConnectionState.done)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (snapshot.hasError)
                          _StateBox(
                            icon: Icons.error_outline_rounded,
                            title: 'Pesanan gagal dimuat',
                            message: '${snapshot.error}',
                          )
                        else if (orders.isEmpty)
                          const _StateBox(
                            icon: Icons.receipt_long_outlined,
                            title: 'Belum ada pesanan masuk',
                            message:
                                'Pesanan akan tampil setelah admin melakukan ACC.',
                          )
                        else
                          ...orders.map(
                            (order) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OwnerOrderCard(
                                order: order,
                                processing: _processingId == order.id,
                                onConfirm: () => _confirmOrder(order),
                                onMarkReady: () => _markReady(order),
                                onConfirmReturn: () => _confirmReturn(order),
                              ),
                            ),
                          ),
                      ],
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
  final VoidCallback onMarkReady;
  final VoidCallback onConfirmReturn;

  const _OwnerOrderCard({
    required this.order,
    required this.processing,
    required this.onConfirm,
    required this.onMarkReady,
    required this.onConfirmReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.bookingCode ?? order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.statusLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(icon: Icons.hiking_rounded, label: order.ringkasanAlat),
          _InfoLine(
            icon: Icons.calendar_month_rounded,
            label:
                '${_formatDate(order.tanggalMulai)} - ${_formatDate(order.tanggalSelesai)}',
          ),
          _InfoLine(
            icon: Icons.payments_rounded,
            label: _formatCurrency(order.totalBayar),
          ),
          const SizedBox(height: 14),
          if (order.status == 'confirmed')
            processing
                ? const LinearProgressIndicator(color: AppColors.primary)
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Konfirmasi Transaksi'),
                  )
          else if (order.status == 'processing')
            processing
                ? const LinearProgressIndicator(color: AppColors.primary)
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: onMarkReady,
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: const Text('Tandai Siap Ambil/Kirim'),
                  )
          else if (order.status == 'rented')
            processing
                ? const LinearProgressIndicator(color: AppColors.primary)
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: onConfirmReturn,
                    icon: const Icon(Icons.arrow_circle_down_rounded, size: 18),
                    label: const Text('Konfirmasi Pengembalian'),
                  ),
        ],
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
