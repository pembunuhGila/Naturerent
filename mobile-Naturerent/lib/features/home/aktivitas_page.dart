import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class AktivitasPage extends StatefulWidget {
  /// Jika [initialTab] diset, langsung buka tab tersebut.
  /// 0 = Notifikasi, 1 = Pesanan Aktif, 2 = Riwayat
  final int initialTab;
  const AktivitasPage({super.key, this.initialTab = 0});

  @override
  State<AktivitasPage> createState() => _AktivitasPageState();
}

class _AktivitasPageState extends State<AktivitasPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                  ),
                  Text('Aktivitas Saya',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: AppColors.textPrimary, fontSize: 20)),
                  GestureDetector(
                    onTap: () => _tabCtrl.animateTo(0),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.notifications_none_rounded,
                          color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                unselectedLabelStyle:
                    AppTextStyles.bodySmall.copyWith(fontSize: 12),
                indicator: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    bottom: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Notifikasi'),
                  Tab(text: 'Pesanan Aktif'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _TabNotifikasi(),
                  _TabPesananAktif(),
                  _TabRiwayat(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 1 — NOTIFIKASI
// ═══════════════════════════════════════════════════════
class _TabNotifikasi extends StatelessWidget {
  const _TabNotifikasi();

  @override
  Widget build(BuildContext context) {
    return _EmptyTab(
      icon: Icons.notifications_none_rounded,
      judul: 'Belum ada notifikasi',
      pesan: 'Notifikasi pesanan dan update aktivitas\nakan muncul di sini.',
    );
  }
}

// ═══════════════════════════════════════════════════════
//  EMPTY STATE SHARED
// ═══════════════════════════════════════════════════════
class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String pesan;
  const _EmptyTab({required this.icon, required this.judul, required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(judul,
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(pesan,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 2 — PESANAN AKTIF
// ═══════════════════════════════════════════════════════
class _TabPesananAktif extends StatelessWidget {
  const _TabPesananAktif();

  @override
  Widget build(BuildContext context) {
    return const _EmptyTab(
      icon: Icons.shopping_bag_outlined,
      judul: 'Tidak ada pesanan aktif',
      pesan: 'Pesanan yang sedang berjalan\nakan tampil di sini.',
    );
  }
}


// ═══════════════════════════════════════════════════════
//  TAB 3 — RIWAYAT
// ═══════════════════════════════════════════════════════
class _TabRiwayat extends StatelessWidget {
  const _TabRiwayat();

  @override
  Widget build(BuildContext context) {
    return const _EmptyTab(
      icon: Icons.history_rounded,
      judul: 'Belum ada riwayat',
      pesan: 'Riwayat sewa yang sudah selesai\nakan tampil di sini.',
    );
  }
}

