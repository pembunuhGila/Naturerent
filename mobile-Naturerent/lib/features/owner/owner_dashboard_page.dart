import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/admin_order.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/owner_header_widget.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  late final Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<_DashboardData> _loadDashboardData() async {
    final rental = await RentalService().ambilRentalSaya();
    if (rental == null) return _DashboardData.empty();

    final data = await AuthService.client
        .from('bookings')
        .select('''
          id,
          booking_code,
          tgl_mulai,
          tgl_selesai,
          total_bayar,
          commission_amount,
          net_to_owner,
          status,
          payment_status,
          created_at,
          users(nama_lengkap, email),
          rental_profiles(nama_rental),
          booking_items(
            nama_equipment,
            nama_rental,
            jumlah,
            total_harga,
            equipment(image_url)
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

    final allOrders = (data as List)
        .map((row) => AdminOrder.fromMap(row as Map<String, dynamic>))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final orders = allOrders
        .where(_isRecognizedIncomeOrder)
        .toList(growable: false);

    final currentMonthOrders =
        orders.where(_isCurrentMonth).toList(growable: false);
    final previousMonthOrders =
        orders.where(_isPreviousMonth).toList(growable: false);
    final currentTotal = _sumNetIncome(currentMonthOrders);
    final previousTotal = _sumNetIncome(previousMonthOrders);
    final recentOrders = [...allOrders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _DashboardData(
      incomeSummary: _MonthlyIncomeSummary(
        amount: _formatCurrency(currentTotal),
        subtext: _growthText(
          current: currentTotal,
          previous: previousTotal,
          periodLabel: 'bulan lalu',
        ),
      ),
      recentOrders: recentOrders.take(5).toList(growable: false),
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
      backgroundColor: AppColors.ownerPageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OwnerHeaderWidget(
              padding: EdgeInsets.fromLTRB(32, 16, 24, 0),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  FutureBuilder<_DashboardData>(
                    future: _dashboardFuture,
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? _DashboardData.empty();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IncomeHighlightCard(
                            label: 'Pendapatan Bulan Ini',
                            amount: data.incomeSummary.amount,
                            subtext: data.incomeSummary.subtext,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaksi Terakhir',
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: const Color(0xFF202321),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'LIHAT SEMUA',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.ownerPrimaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (data.recentOrders.isEmpty)
                            const _EmptyTransactionsCard()
                          else
                            ...data.recentOrders.map(
                              (order) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _TransactionCard(order: order),
                              ),
                            ),
                        ],
                      );
                    },
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


class _DashboardData {
  final _MonthlyIncomeSummary incomeSummary;
  final List<AdminOrder> recentOrders;

  const _DashboardData({
    required this.incomeSummary,
    required this.recentOrders,
  });

  factory _DashboardData.empty() {
    return _DashboardData(
      incomeSummary: _MonthlyIncomeSummary.empty(),
      recentOrders: const [],
    );
  }
}

class _MonthlyIncomeSummary {
  final String amount;
  final String subtext;

  const _MonthlyIncomeSummary({
    required this.amount,
    required this.subtext,
  });

  factory _MonthlyIncomeSummary.empty() {
    return const _MonthlyIncomeSummary(
      amount: 'Rp 0',
      subtext: 'Data bulan lalu belum tersedia',
    );
  }
}

bool _isRecognizedIncomeOrder(AdminOrder order) {
  final finished = order.status == 'returned' || order.status == 'completed';
  final paymentStatus = order.paymentStatus?.toLowerCase().trim();
  final paid = order.pembayaranLunas ||
      paymentStatus == 'dp_confirmed' ||
      paymentStatus == 'paid' ||
      paymentStatus == 'lunas';
  return finished && paid;
}

bool _isCurrentMonth(AdminOrder order) {
  final now = DateTime.now();
  final transactionDate = order.createdAt.toLocal();
  return transactionDate.year == now.year && transactionDate.month == now.month;
}

bool _isPreviousMonth(AdminOrder order) {
  final now = DateTime.now();
  final previousMonth = now.month == 1 ? 12 : now.month - 1;
  final previousYear = now.month == 1 ? now.year - 1 : now.year;
  final transactionDate = order.createdAt.toLocal();
  return transactionDate.year == previousYear &&
      transactionDate.month == previousMonth;
}

double _sumCompletedPayments(Iterable<AdminOrder> orders) {
  return orders.fold<double>(0, (sum, order) => sum + order.totalBayar);
}

double _sumNetIncome(Iterable<AdminOrder> orders) {
  return orders.fold<double>(0, (sum, order) {
    if (order.netToOwner > 0) return sum + order.netToOwner;
    if (order.commissionAmount > 0) {
      return sum + (order.totalBayar - order.commissionAmount);
    }
    return sum + (order.totalBayar * 0.9);
  });
}

String _growthText({
  required double current,
  required double previous,
  required String periodLabel,
}) {
  if (previous <= 0) return 'Data $periodLabel belum tersedia';
  final percent = ((current - previous) / previous * 100).round();
  if (percent >= 0) return '▲ $percent% dari $periodLabel';
  return '▼ ${percent.abs()}% dari $periodLabel';
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

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _shortCode(AdminOrder order) {
  final code = order.bookingCode;
  if (code != null && code.isNotEmpty) return code;
  final suffix = order.id.length <= 4
      ? order.id.toUpperCase()
      : order.id.substring(order.id.length - 4).toUpperCase();
  return '#RENT-$suffix';
}

String _dashboardStatusLabel(String status) {
  return switch (status) {
    'confirmed' => 'MENUNGGU',
    'processing' => 'DIPROSES',
    'rented' => 'DISEWA',
    'returned' || 'completed' => 'BERHASIL',
    _ => status.toUpperCase(),
  };
}


class _IncomeHighlightCard extends StatelessWidget {
  final String label;
  final String amount;
  final String subtext;

  const _IncomeHighlightCard({
    required this.label,
    required this.amount,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.ownerPrimaryGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: AppTextStyles.headlineLarge.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  const _EmptyTransactionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
      ),
      child: Text(
        'Belum ada transaksi terakhir',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: const Color(0xFF496171),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final AdminOrder order;
  const _TransactionCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final item = order.items.isNotEmpty ? order.items.first : null;
    final income = _sumCompletedPayments([order]);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: AppColors.ownerPrimaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.namaUser,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: const Color(0xFF202321),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item?.namaEquipment ?? order.ringkasanAlat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF496171),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_shortCode(order)} • ${_formatDate(order.createdAt.toLocal())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF7D847D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_formatCurrency(income)}',
                textAlign: TextAlign.right,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.ownerPrimaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dashboardStatusLabel(order.status),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.ownerPrimaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
