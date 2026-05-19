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
                  Container(
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
  // Data dummy — nanti diganti dengan data dari Supabase
  final _notifs = const [
    _NotifData(
      status: 'READY TO PICKUP',
      statusColor: Color(0xFF2E7D32),
      icon: Icons.inventory_2_rounded,
      judul: 'Pesanan #QT-8829',
      isi: 'Tenda Arpenaz 4.1 & Matras sudah siap diambil di Basecamp Semeru.',
      kutipan: '"Siapkan fisik untuk pendakian esok."',
      waktu: '12m ago',
    ),
    _NotifData(
      status: 'WAITING FOR CONFIRMATION',
      statusColor: Color(0xFFF57C00),
      icon: Icons.hourglass_top_rounded,
      judul: 'Penyewaan Alat Masak',
      isi: 'Admin sedang memverifikasi ketersediaan kompor ultralight untuk tanggal 24 Okt.',
      waktu: '3h ago',
    ),
    _NotifData(
      status: 'IN PROCESS',
      statusColor: Color(0xFF1565C0),
      icon: Icons.cleaning_services_rounded,
      judul: 'Pembersihan Berkala',
      isi: 'Jaket down yang Anda sewa sedang dalam tahap sterilisasi profesional.',
      waktu: 'Kemarin',
    ),
  ];

  const _TabNotifikasi();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: _notifs.length,
      itemBuilder: (_, i) => _NotifCard(data: _notifs[i]),
    );
  }
}

class _NotifData {
  final String status;
  final Color statusColor;
  final IconData icon;
  final String judul;
  final String isi;
  final String? kutipan;
  final String waktu;
  const _NotifData({
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.judul,
    required this.isi,
    this.kutipan,
    required this.waktu,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifData data;
  const _NotifCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: data.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.status,
                  style: AppTextStyles.caption.copyWith(
                    color: data.statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(data.waktu,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          // Icon + teks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(data.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.judul,
                        style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(data.isi,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    if (data.kutipan != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(data.kutipan!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            )),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _PesananAktifCard(
          items: const [
            _ItemPesanan(
              imageUrl:
                  'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=200&q=80',
              nama: 'Summit Heaven 4P',
              rental: 'WILDERNESS BASECAMP',
              tanggal: '12 Apr - 16 Apr 2026',
              durasi: '4 Malam',
            ),
            _ItemPesanan(
              imageUrl:
                  'https://images.unsplash.com/photo-1510312305653-8ed496efae75?w=200&q=80',
              nama: 'Portable Stove Pro',
              rental: 'WILDERNESS BASECAMP',
              tanggal: '12 Apr - 16 Apr 2026',
              durasi: '4 Malam',
            ),
          ],
          total: 'Rp 700.000',
        ),
        const SizedBox(height: 10),
        _buildEmptyHint(),
      ],
    );
  }

  Widget _buildEmptyHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 36, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text('Tidak ada pesanan aktif lainnya',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _ItemPesanan {
  final String imageUrl;
  final String nama;
  final String rental;
  final String tanggal;
  final String durasi;
  const _ItemPesanan({
    required this.imageUrl,
    required this.nama,
    required this.rental,
    required this.tanggal,
    required this.durasi,
  });
}

class _PesananAktifCard extends StatelessWidget {
  final List<_ItemPesanan> items;
  final String total;
  const _PesananAktifCard({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ...items.map((item) => _ItemRow(item: item)),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                Text(total,
                    style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _ItemPesanan item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(item.imageUrl,
                width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.nama,
                          style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('AKTIF',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 11, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(item.rental,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary, fontSize: 10)),
                ]),
                const SizedBox(height: 4),
                Text('${item.tanggal} • ${item.durasi}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  TAB 3 — RIWAYAT
// ═══════════════════════════════════════════════════════
class _TabRiwayat extends StatelessWidget {
  final _riwayat = const [
    _RiwayatData(
      imageUrl:
          'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=200&q=80',
      nama: 'Premium Expedition Tent',
      tanggal: '12 - 15 Okt 2023',
      durasi: '3 Malam',
      total: 'Rp 450.000',
    ),
    _RiwayatData(
      imageUrl:
          'https://images.unsplash.com/photo-1501555088652-021faa106b9b?w=200&q=80',
      nama: 'Osprey Atmos AG 65',
      tanggal: '02 - 05 Sep 2023',
      durasi: '3 Malam',
      total: 'Rp 225.000',
    ),
    _RiwayatData(
      imageUrl:
          'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?w=200&q=80',
      nama: 'Summit Series Sleeping Bag',
      tanggal: '20 - 22 Agu 2023',
      durasi: '2 Malam',
      total: 'Rp 180.000',
    ),
  ];

  const _TabRiwayat();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ...(_riwayat.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RiwayatCard(data: r),
            ))),
        const SizedBox(height: 16),
        // Quote
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '"Alam tidak pernah terburu-buru,\nnamun semuanya terselesaikan."',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text('— Lao Tzu',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RiwayatData {
  final String imageUrl;
  final String nama;
  final String tanggal;
  final String durasi;
  final String total;
  const _RiwayatData({
    required this.imageUrl,
    required this.nama,
    required this.tanggal,
    required this.durasi,
    required this.total,
  });
}

class _RiwayatCard extends StatelessWidget {
  final _RiwayatData data;
  const _RiwayatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(data.imageUrl,
                width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(data.nama,
                          style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('SELESAI',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${data.tanggal} • ${data.durasi}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL PEMBAYARAN',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                                fontSize: 9,
                                letterSpacing: 0.5)),
                        Text(data.total,
                            style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Ulas',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
