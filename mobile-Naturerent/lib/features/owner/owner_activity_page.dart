import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/owner_header_widget.dart';

/// Halaman aktivitas khusus untuk Pemilik Rental (Owner).
/// Berbeda dari AktivitasPage milik customer — konten berfokus pada
/// notifikasi pesanan masuk, transaksi aktif, dan riwayat pemilik.
class OwnerActivityPage extends StatefulWidget {
  const OwnerActivityPage({super.key});

  @override
  State<OwnerActivityPage> createState() => _OwnerActivityPageState();
}

class _OwnerActivityPageState extends State<OwnerActivityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
      backgroundColor: const Color(0xFFF8F8F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header Mitra NatureRent
            const OwnerHeaderWidget(showBackButton: true),
            const SizedBox(height: 20),

            // ── Judul halaman
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas Saya',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF202321),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pantau pesanan dan riwayat transaksi rental Anda.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF496171),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E5DE)),
              ),
              child: TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFF18743A),
                unselectedLabelColor: const Color(0xFF496171),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                ),
                indicator: BoxDecoration(
                  color: const Color(0xFFE4EFE7),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFF18743A), width: 2),
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
                children: const [
                  _TabNotifikasiOwner(),
                  _TabPesananAktifOwner(),
                  _TabRiwayatOwner(),
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
//  EMPTY STATE SHARED
// ═══════════════════════════════════════════════════════
class _OwnerEmptyTab extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String pesan;

  const _OwnerEmptyTab({
    required this.icon,
    required this.judul,
    required this.pesan,
  });

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
                color: const Color(0xFFE4EFE7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF18743A)),
            ),
            const SizedBox(height: 16),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF7B8794),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 1 — NOTIFIKASI OWNER
// ═══════════════════════════════════════════════════════
class _TabNotifikasiOwner extends StatelessWidget {
  const _TabNotifikasiOwner();

  @override
  Widget build(BuildContext context) {
    return const _OwnerEmptyTab(
      icon: Icons.notifications_none_rounded,
      judul: 'Belum ada notifikasi',
      pesan:
          'Notifikasi pesanan masuk dan\npembaruan status sewa akan muncul di sini.',
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 2 — PESANAN AKTIF OWNER
// ═══════════════════════════════════════════════════════
class _TabPesananAktifOwner extends StatelessWidget {
  const _TabPesananAktifOwner();

  @override
  Widget build(BuildContext context) {
    return const _OwnerEmptyTab(
      icon: Icons.assignment_outlined,
      judul: 'Tidak ada pesanan aktif',
      pesan:
          'Pesanan yang sedang diproses oleh\npenyewa akan tampil di sini.',
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 3 — RIWAYAT OWNER
// ═══════════════════════════════════════════════════════
class _TabRiwayatOwner extends StatelessWidget {
  const _TabRiwayatOwner();

  @override
  Widget build(BuildContext context) {
    return const _OwnerEmptyTab(
      icon: Icons.receipt_long_outlined,
      judul: 'Belum ada riwayat transaksi',
      pesan:
          'Semua transaksi sewa yang sudah\nselesai akan tercatat di sini.',
    );
  }
}
