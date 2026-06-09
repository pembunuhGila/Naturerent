import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'package:naturerent/features/user/profile/user_profile_page.dart';
import 'admin_destinations_page.dart';
import 'admin_orders_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      AdminOrdersPage(),
      AdminDestinationsPage(),
      ProfilPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AdminBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminNavItem(icon: Icons.receipt_long_rounded, label: 'Pesanan'),
      _AdminNavItem(icon: Icons.landscape_rounded, label: 'Destinasi'),
      _AdminNavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 60,
        child: Row(
          children: List.generate(items.length, (index) {
            final active = index == currentIndex;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  decoration: BoxDecoration(
                    color: active ? AppColors.adminPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index].icon,
                        size: 21,
                        color: active ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[index].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color:
                              active ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AdminNavItem {
  final IconData icon;
  final String label;

  const _AdminNavItem({required this.icon, required this.label});
}
