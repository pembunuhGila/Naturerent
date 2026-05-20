import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 28, 24, 120),
          children: [
            const _MitraBrand(),
            const SizedBox(height: 48),
            Text(
              'Total Pendapatan Bulan Ini',
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF454E45),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp 12.450.000',
              style: AppTextStyles.displayLarge.copyWith(
                color: const Color(0xFF2B4E33),
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF6D6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF147A25),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '12% DARI BULAN LALU',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF147A25),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _RevenueChartCard(),
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
                    color: const Color(0xFF2B4E33),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._transactions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TransactionCard(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _transactions = [
  _TransactionItem(
    icon: Icons.terrain_rounded,
    imageColor: Color(0xFFDDEB9B),
    title: 'Tenda Dome 4P\nAlpine',
    subtitle: 'Sewa 3 Hari • 24 Okt',
    amount: '+Rp\n270.000',
    note: 'Net Profit (90%)',
  ),
  _TransactionItem(
    icon: Icons.hiking_rounded,
    imageColor: Color(0xFF29302B),
    title: 'Sepatu Trekking\nEiger',
    subtitle: 'Sewa 2 Hari • 23 Okt',
    amount: '+Rp\n135.000',
    note: 'Net Profit (90%)',
  ),
  _TransactionItem(
    icon: Icons.soup_kitchen_rounded,
    imageColor: Color(0xFFF47A22),
    title: 'Paket Memasak\nUltralight',
    subtitle: 'Sewa 1 Hari • 22 Okt',
    amount: '+Rp\n45.000',
    note: 'Net Profit (90%)',
  ),
  _TransactionItem(
    icon: Icons.cabin_rounded,
    imageColor: Color(0xFFB59B61),
    title: 'Penyewaan Tenda\nDome 4P',
    subtitle: 'Sewa 2 hari • 25 Okt',
    amount: '+Rp\n450.000',
    note: 'BERHASIL',
    isSuccess: true,
  ),
  _TransactionItem(
    icon: Icons.bedtime_rounded,
    imageColor: Color(0xFFCFB617),
    title: 'Paket Hiking Sleeping\nBag (2x)',
    subtitle: 'Sewa 2 hari • 25 Okt',
    amount: '+Rp\n140.000',
    note: 'BERHASIL',
    isSuccess: true,
  ),
  _TransactionItem(
    icon: Icons.local_fire_department_rounded,
    imageColor: Color(0xFF3C4A40),
    title: 'Alat Masak Portabel\n& Gas',
    subtitle: 'Sewa 2 hari • 25 Okt',
    amount: '+Rp\n85.000',
    note: 'BERHASIL',
    isSuccess: true,
  ),
];

class _MitraBrand extends StatelessWidget {
  const _MitraBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.park_rounded, color: Color(0xFF116229), size: 24),
        const SizedBox(width: 7),
        Text(
          'Mitra NatureRent',
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFF116229),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard();

  @override
  Widget build(BuildContext context) {
    final bars = [
      _BarData('M1', 58, false, '1-7'),
      _BarData('M2', 86, false, '8-14'),
      _BarData('M3', 118, true, '15-21'),
      _BarData('M4', 78, false, '22-28'),
      _BarData('M5', 46, false, '29-31'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Penghasilan Mingguan',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF202321),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Bulan ini',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF626A60),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 158,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: bars.map((bar) => _ChartBar(data: bar)).toList(),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Pendapatan tertinggi pada Minggu ke-3',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF404940),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final _BarData data;
  const _ChartBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          SizedBox(
            height: 118,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 45,
                height: data.height,
                decoration: BoxDecoration(
                  color: data.isDark
                      ? const Color(0xFF2B4E33)
                      : const Color(0xFFE6E7E3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.label,
            style: AppTextStyles.caption.copyWith(
              color: data.isDark
                  ? const Color(0xFF116229)
                  : const Color(0xFF626A60),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.range,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF90968D),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final _TransactionItem item;
  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
              color: item.imageColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
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
                  item.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF5D655D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                item.amount,
                textAlign: TextAlign.right,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: const Color(0xFF2B4E33),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.note,
                style: AppTextStyles.caption.copyWith(
                  color: item.isSuccess
                      ? const Color(0xFF00A927)
                      : const Color(0xFF5D655D),
                  fontSize: item.isSuccess ? 10 : 11,
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

class _BarData {
  final String label;
  final double height;
  final bool isDark;
  final String range;

  const _BarData(this.label, this.height, this.isDark, this.range);
}

class _TransactionItem {
  final IconData icon;
  final Color imageColor;
  final String title;
  final String subtitle;
  final String amount;
  final String note;
  final bool isSuccess;

  const _TransactionItem({
    required this.icon,
    required this.imageColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.note,
    this.isSuccess = false,
  });
}
