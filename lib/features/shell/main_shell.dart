import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/beranda_page.dart';
import '../home/rental_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BerandaPage(),
    RentalPage(),
    _PlaceholderPage(label: 'Aktivitas'),
    _PlaceholderPage(label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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
      _NavItem(icon: Icons.home_rounded, label: 'BERANDA'),
      _NavItem(icon: Icons.storefront_rounded, label: 'RENTAL'),
      _NavItem(icon: Icons.explore_rounded, label: 'AKTIVITAS'),
      _NavItem(icon: Icons.person_rounded, label: 'PROFIL'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Active indicator dot for RENTAL (triangle icon)
                        if (i == 1 && isActive)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              items[i].icon,
                              size: 22,
                              color: AppColors.white,
                            ),
                          )
                        else
                          Icon(
                            items[i].icon,
                            size: 22,
                            color: isActive ? AppColors.primary : AppColors.textHint,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: AppTextStyles.caption.copyWith(
                            color: isActive ? AppColors.primary : AppColors.textHint,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
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
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Placeholder for pages not yet built
class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('Halaman $label\nSegera Hadir', textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}
