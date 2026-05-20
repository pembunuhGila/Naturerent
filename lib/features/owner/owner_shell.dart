import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../profil/profil_page.dart';
import 'owner_dashboard_page.dart';
import 'owner_inventory_page.dart';
import 'owner_orders_page.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    OwnerDashboardPage(),
    OwnerInventoryPage(),
    OwnerOrdersPage(),
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _OwnerBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _OwnerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _OwnerBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD'),
      _NavItem(icon: Icons.inventory_2_rounded, label: 'ALAT'),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'PESANAN'),
      _NavItem(icon: Icons.person_rounded, label: 'PROFIL'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryDark
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          items[i].icon,
                          size: 22,
                          color: isActive ? Colors.white : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive
                              ? AppColors.primaryDark
                              : AppColors.textHint,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
