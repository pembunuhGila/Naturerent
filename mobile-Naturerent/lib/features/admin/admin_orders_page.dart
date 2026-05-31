import 'package:flutter/material.dart';

import '../../core/models/admin_order.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _adminService = AdminService();
  late Future<List<AdminOrder>> _futureOrders;
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _futureOrders = _adminService.ambilPesananMasuk();
  }

  void _reload() {
    setState(() => _futureOrders = _adminService.ambilPesananMasuk());
  }

  Future<void> _accOrder(AdminOrder order) async {
    setState(() => _processingId = order.id);
    try {
      await _adminService.accPesanan(order.id);
      if (!mounted) return;
      _showMessage('Pesanan sudah diteruskan ke pemilik rental.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal ACC pesanan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _cancelOrder(AdminOrder order) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text(
          'Pesanan ${order.bookingCode ?? order.id} tidak akan diteruskan ke pemilik rental.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    setState(() => _processingId = order.id);
    try {
      await _adminService.batalkanPesanan(order.id);
      if (!mounted) return;
      _showMessage('Pesanan dibatalkan oleh admin.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal membatalkan pesanan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  void _showPaymentProof(AdminOrder order) {
    final proofUrl = order.paymentProofUrl;
    if (proofUrl == null || proofUrl.isEmpty) {
      _showMessage('Bukti pembayaran belum tersedia.', isError: true);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bukti Pembayaran',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: proofUrl.startsWith('data:image')
                    ? Image.memory(
                        UriData.parse(proofUrl).contentAsBytes(),
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        proofUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Gambar bukti pembayaran gagal dimuat.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                order.bookingCode ?? order.id,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(letterSpacing: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.adminPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.adminPrimary,
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<AdminOrder>>(
            future: _futureOrders,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? const <AdminOrder>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                children: [
                  _Header(totalPending: orders.where((o) => o.menungguAdmin).length),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.adminPrimary,
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
                          'Pesanan user akan tampil di sini sebelum diteruskan ke pemilik rental.',
                    )
                  else
                    ...orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OrderCard(
                          order: order,
                          processing: _processingId == order.id,
                          onViewProof: () => _showPaymentProof(order),
                          onAcc: () => _accOrder(order),
                          onCancel: () => _cancelOrder(order),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int totalPending;

  const _Header({required this.totalPending});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konfirmasi Pesanan',
                style: AppTextStyles.headlineLarge.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalPending pesanan menunggu keputusan admin',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.adminPrimaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.adminPrimary,
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AdminOrder order;
  final bool processing;
  final VoidCallback onViewProof;
  final VoidCallback onAcc;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.processing,
    required this.onViewProof,
    required this.onAcc,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canProcess = order.menungguAdmin && !processing;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminBorder),
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
              _StatusBadge(order: order),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(icon: Icons.person_rounded, label: order.namaUser),
          _InfoLine(icon: Icons.hiking_rounded, label: order.ringkasanAlat),
          _InfoLine(icon: Icons.store_rounded, label: order.namaRental),
          _InfoLine(
            icon: Icons.calendar_month_rounded,
            label:
                '${_formatDate(order.tanggalMulai)} - ${_formatDate(order.tanggalSelesai)}',
          ),
          _InfoLine(
            icon: Icons.payments_rounded,
            label: _formatCurrency(order.totalBayar),
          ),
          _InfoLine(
            icon: Icons.verified_rounded,
            label: order.statusPembayaranLabel,
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: onViewProof,
            icon: const Icon(Icons.image_rounded, size: 18),
            label: Text(
              order.paymentProofUrl == null || order.paymentProofUrl!.isEmpty
                  ? 'Bukti Belum Ada'
                  : 'Lihat Bukti Pembayaran',
            ),
          ),
          const SizedBox(height: 14),
          if (processing)
            const LinearProgressIndicator(color: AppColors.adminPrimary)
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      disabledBackgroundColor: AppColors.adminBorder,
                    ),
                    onPressed: canProcess ? onAcc : null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('ACC Pesanan'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      disabledBackgroundColor: AppColors.adminBorder,
                    ),
                    onPressed: canProcess ? onCancel : null,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Batalkan'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AdminOrder order;

  const _StatusBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = order.dibatalkanAdmin
        ? AppColors.error
        : order.menungguAdmin
            ? const Color(0xFFF59E0B)
            : AppColors.adminPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        order.statusLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: color,
          letterSpacing: 0,
          fontWeight: FontWeight.w800,
        ),
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
          Icon(icon, size: 18, color: AppColors.textSecondary),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 52),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
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
