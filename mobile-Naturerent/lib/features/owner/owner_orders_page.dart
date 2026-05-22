import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/owner_header_widget.dart';

class OwnerOrdersPage extends StatelessWidget {
  const OwnerOrdersPage({super.key});

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesanan Rental',
                              style: AppTextStyles.headlineLarge.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Kelola permintaan sewa masuk',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF496171),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E5DE)),
                        ),
                        child: const Icon(
                          Icons.filter_list_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SummaryStrip(),
                  const SizedBox(height: 18),
                  _EmptyOrders(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5DE)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _SummaryItem(
              icon: Icons.pending_actions_rounded,
              label: 'Menunggu',
              value: '0',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              icon: Icons.inventory_rounded,
              label: 'Disiapkan',
              value: '0',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              icon: Icons.task_alt_rounded,
              label: 'Selesai',
              value: '0',
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

class _EmptyOrders extends StatelessWidget {
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
          const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFF7B8794),
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada pesanan masuk',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pesanan dari penyewa akan tampil setelah checkout tersimpan ke database.',
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
