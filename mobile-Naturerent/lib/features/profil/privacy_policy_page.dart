import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnimCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  final Set<int> _expandedSections = {};

  final List<_PrivacySection> _sections = [
    _PrivacySection(
      title: 'Data yang Kami Kumpulkan',
      icon: Icons.folder_open_rounded,
      color: Color(0xFF2563EB),
      items: [
        _PrivacyPoint(
          icon: Icons.person_rounded,
          title: 'Data Profil',
          description:
              'Nama lengkap, alamat email, nomor WhatsApp, dan foto profil yang kamu isi saat registrasi atau edit profil.',
        ),
        _PrivacyPoint(
          icon: Icons.badge_rounded,
          title: 'Foto KTP',
          description:
              'Foto KTP digunakan untuk verifikasi identitas penyewa demi keamanan transaksi. Data ini tidak digunakan untuk keperluan pemasaran.',
        ),
        _PrivacyPoint(
          icon: Icons.receipt_long_rounded,
          title: 'Data Transaksi',
          description:
              'Riwayat pesanan, data alat yang disewa, tanggal sewa, dan bukti pembayaran yang kamu upload.',
        ),
        _PrivacyPoint(
          icon: Icons.location_on_rounded,
          title: 'Data Lokasi',
          description:
              'Koordinat GPS digunakan untuk menghitung jarak rental terdekat dan estimasi biaya delivery. Lokasi hanya diakses saat kamu menggunakannya.',
        ),
      ],
    ),
    _PrivacySection(
      title: 'Bagaimana Kami Menggunakan Data',
      icon: Icons.settings_rounded,
      color: Color(0xFF14532D),
      items: [
        _PrivacyPoint(
          icon: Icons.login_rounded,
          title: 'Autentikasi & Keamanan',
          description:
              'Data email dan password digunakan untuk proses login yang aman menggunakan layanan Supabase Auth.',
        ),
        _PrivacyPoint(
          icon: Icons.verified_user_rounded,
          title: 'Verifikasi Identitas',
          description:
              'Foto KTP dipakai untuk memverifikasi identitas penyewa sebelum transaksi pertama dilakukan.',
        ),
        _PrivacyPoint(
          icon: Icons.notifications_rounded,
          title: 'Notifikasi',
          description:
              'Informasi pesanan, konfirmasi pembayaran, dan status pengiriman dikirim melalui notifikasi dalam aplikasi.',
        ),
        _PrivacyPoint(
          icon: Icons.analytics_rounded,
          title: 'Peningkatan Layanan',
          description:
              'Data digunakan secara anonim untuk memahami pola penggunaan dan meningkatkan kualitas aplikasi.',
        ),
      ],
    ),
    _PrivacySection(
      title: 'Keamanan Data',
      icon: Icons.security_rounded,
      color: Color(0xFF7C3AED),
      items: [
        _PrivacyPoint(
          icon: Icons.lock_rounded,
          title: 'Enkripsi',
          description:
              'Seluruh data disimpan dengan enkripsi menggunakan infrastruktur Supabase yang telah memenuhi standar keamanan industri.',
        ),
        _PrivacyPoint(
          icon: Icons.policy_rounded,
          title: 'Row-Level Security (RLS)',
          description:
              'Setiap pengguna hanya bisa mengakses data miliknya sendiri. Kebijakan RLS diterapkan di semua tabel database.',
        ),
        _PrivacyPoint(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Akses Admin',
          description:
              'Admin hanya mengakses data yang diperlukan untuk operasional, seperti verifikasi pembayaran dan penanganan kendala.',
        ),
      ],
    ),
    _PrivacySection(
      title: 'Hak Pengguna',
      icon: Icons.gavel_rounded,
      color: Color(0xFFD97706),
      items: [
        _PrivacyPoint(
          icon: Icons.visibility_rounded,
          title: 'Akses Data',
          description:
              'Kamu berhak melihat data pribadi yang kami simpan melalui halaman Profil di aplikasi.',
        ),
        _PrivacyPoint(
          icon: Icons.edit_rounded,
          title: 'Ubah Data',
          description:
              'Kamu bisa mengubah informasi profil kapan saja melalui fitur "Edit Profil".',
        ),
        _PrivacyPoint(
          icon: Icons.delete_rounded,
          title: 'Hapus Akun',
          description:
              'Untuk menghapus akun beserta seluruh data, hubungi admin NatureRent melalui WhatsApp resmi.',
        ),
      ],
    ),
    _PrivacySection(
      title: 'Pihak Ketiga',
      icon: Icons.handshake_rounded,
      color: Color(0xFF0891B2),
      items: [
        _PrivacyPoint(
          icon: Icons.cloud_rounded,
          title: 'Supabase',
          description:
              'Platform database dan autentikasi yang digunakan NatureRent. Supabase mematuhi standar privasi GDPR dan SOC 2.',
        ),
        _PrivacyPoint(
          icon: Icons.map_rounded,
          title: 'OpenStreetMap',
          description:
              'Layanan peta yang digunakan untuk menampilkan lokasi destinasi dan toko rental. Tidak ada data pengguna yang dibagikan.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeOutCubic,
    ));
    _headerAnimCtrl.forward();
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleSection(int index) {
    setState(() {
      if (_expandedSections.contains(index)) {
        _expandedSections.remove(index);
      } else {
        _expandedSections.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                const SizedBox(height: 20),
                _buildLastUpdated(),
                const SizedBox(height: 16),
                _buildIntroCard(),
                const SizedBox(height: 20),
                ..._sections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final section = entry.value;
                  return _PrivacySectionCard(
                    section: section,
                    index: index,
                    isExpanded: _expandedSections.contains(index),
                    onToggle: () => _toggleSection(index),
                  );
                }),
                const SizedBox(height: 8),
                _buildFooterNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.privacy_tip_outlined,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'KEBIJAKAN PRIVASI',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Privasi kamu\nadalah prioritas kami.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transparansi penuh tentang bagaimana\nNatureRent mengelola data kamu.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Row(
      children: [
        const Icon(
          Icons.update_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        const SizedBox(width: 6),
        Text(
          'Terakhir diperbarui: Juni 2025',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF4F46E5),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dengan menggunakan NatureRent, kamu menyetujui kebijakan privasi ini. Kami berkomitmen untuk melindungi data pribadimu.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF3730A3),
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pertanyaan tentang privasi?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hubungi kami melalui WhatsApp atau email resmi NatureRent. Tim kami akan merespons dalam 1x24 jam kerja.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  PRIVACY SECTION CARD (Expandable)
// ────────────────────────────────────────────────
class _PrivacySectionCard extends StatefulWidget {
  final _PrivacySection section;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _PrivacySectionCard({
    required this.section,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_PrivacySectionCard> createState() => _PrivacySectionCardState();
}

class _PrivacySectionCardState extends State<_PrivacySectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 70),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isExpanded
                  ? widget.section.color.withValues(alpha: 0.3)
                  : const Color(0xFFE5E7EB),
              width: widget.isExpanded ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
                splashColor:
                    widget.section.color.withValues(alpha: 0.05),
                highlightColor:
                    widget.section.color.withValues(alpha: 0.03),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: widget.section.color
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.section.icon,
                              size: 20,
                              color: widget.section.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.section.title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: widget.isExpanded
                                    ? widget.section.color
                                    : const Color(0xFF1C1C1B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: widget.isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: widget.isExpanded
                                  ? widget.section.color
                                  : const Color(0xFF9CA3AF),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expanded content
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: widget.isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          Divider(
                            height: 1,
                            color: widget.section.color.withValues(alpha: 0.15),
                          ),
                          ...widget.section.items.asMap().entries.map(
                                (entry) => _PrivacyPointTile(
                                  point: entry.value,
                                  sectionColor: widget.section.color,
                                  isLast: entry.key ==
                                      widget.section.items.length - 1,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyPointTile extends StatelessWidget {
  final _PrivacyPoint point;
  final Color sectionColor;
  final bool isLast;

  const _PrivacyPointTile({
    required this.point,
    required this.sectionColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  point.icon,
                  size: 15,
                  color: sectionColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 60,
            color: sectionColor.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────
//  DATA MODELS
// ────────────────────────────────────────────────
class _PrivacySection {
  final String title;
  final IconData icon;
  final Color color;
  final List<_PrivacyPoint> items;

  const _PrivacySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class _PrivacyPoint {
  final IconData icon;
  final String title;
  final String description;

  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.description,
  });
}
