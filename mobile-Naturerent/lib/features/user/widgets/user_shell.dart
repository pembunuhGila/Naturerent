import 'package:flutter/material.dart';
import 'package:naturerent/core/theme/app_theme.dart';
import 'package:naturerent/features/user/home/user_home_page.dart';
import 'package:naturerent/features/user/rental/rental_selection_page.dart';
import 'package:naturerent/features/user/activity/user_activity_page.dart';
import 'package:naturerent/features/user/profile/user_profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _activityInitialTab = 0;
  int _activityPageVersion = 0;

  void _openActivityTab(int index) {
    setState(() {
      _activityInitialTab = index;
      _activityPageVersion++;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BerandaPage(onOpenNotifications: () => _openActivityTab(0)),
      const RentalPage(),
      AktivitasPage(
        key: ValueKey('activity-$_activityPageVersion-$_activityInitialTab'),
        initialTab: _activityInitialTab,
      ),
      const ProfilPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      extendBody: true,
      bottomNavigationBar: _NrBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Nav Bar
class _NrBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NrBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.storefront_rounded, label: 'Rental'),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'Aktifitas'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          border: Border(
            top: BorderSide(color: const Color(0xFFE5E7EB)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final isActive = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 58,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 24,
                        color: isActive
                            ? const Color(0xFF14532D)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        items[i].label,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive
                              ? const Color(0xFF14532D)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0,
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
