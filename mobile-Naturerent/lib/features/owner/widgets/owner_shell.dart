import 'package:flutter/material.dart';
import 'package:naturerent/core/theme/app_theme.dart';
import 'package:naturerent/features/owner/profile/owner_profile_page.dart';
import 'package:naturerent/features/owner/dashboard/owner_dashboard_page.dart';
import 'package:naturerent/features/owner/inventory/owner_inventory_page.dart';
import 'package:naturerent/features/owner/orders/owner_orders_page.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;
  int _inventoryInitialTab = 0;
  int _profileRefreshToken = 0;
  int _dashboardResetToken = 0;

  void _setTab(int index, {int? inventoryTab}) {
    setState(() {
      if (_currentIndex == 0 && index != 0) _dashboardResetToken++;
      _currentIndex = index;
      if (inventoryTab != null) _inventoryInitialTab = inventoryTab;
      if (index == 3) _profileRefreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      OwnerDashboardPage(resetToken: _dashboardResetToken),
      const OwnerOrdersPage(),
      OwnerInventoryPage(initialTabIndex: _inventoryInitialTab),
      ProfilPage(
        forceMitra: true,
        refreshToken: _profileRefreshToken,
        onOwnerNavTap: (index) =>
            _setTab(index, inventoryTab: index == 2 ? 1 : null),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.ownerPageBackground,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _OwnerBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => _setTab(i),
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
      _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'Pesanan'),
      _NavItem(icon: Icons.edit_note_rounded, label: 'Kelola'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.ownerCardBackground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      width: isActive ? 92 : null,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.ownerPrimaryGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].icon,
                            size: 21,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF817B72),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF817B72),
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
