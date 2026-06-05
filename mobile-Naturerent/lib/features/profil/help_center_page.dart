import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnimCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  int? _expandedIndex;
  int _selectedCategory = 0;

  final List<_HelpCategory> _categories = [
    _HelpCategory(
      label: 'Peminjaman',
      icon: Icons.backpack_rounded,
      color: const Color(0xFF14532D),
    ),
    _HelpCategory(
      label: 'Pembayaran',
      icon: Icons.payment_rounded,
      color: const Color(0xFF1D4ED8),
    ),
    _HelpCategory(
      label: 'Akun',
      icon: Icons.person_rounded,
      color: const Color(0xFF9333EA),
    ),
    _HelpCategory(
      label: 'Lainnya',
      icon: Icons.more_horiz_rounded,
      color: const Color(0xFFB45309),
    ),
  ];

  final List<List<_FaqItem>> _faqByCategory = [
    // Peminjaman
    [
      _FaqItem(
        question: 'Bagaimana cara meminjam peralatan?',
        answer:
            'Pilih destinasi wisata di halaman Beranda, lalu pilih toko rental terdekat. Pilih alat yang ingin disewa, tentukan tanggal mulai dan selesai, lalu lanjut ke pembayaran.',
        icon: Icons.hiking_rounded,
      ),
      _FaqItem(
        question: 'Apakah bisa memilih pengiriman ke lokasi?',
        answer:
            'Ya! Saat memilih alat, kamu bisa memilih opsi "Delivery". Aplikasi akan menghitung jarak dari toko rental ke lokasimu dan menampilkan estimasi ongkos kirim.',
        icon: Icons.local_shipping_rounded,
      ),
      _FaqItem(
        question: 'Berapa lama durasi sewa minimum?',
        answer:
            'Durasi sewa minimum adalah 1 hari. Kamu bisa memilih tanggal mulai dan tanggal selesai sesuai kebutuhan petualanganmu.',
        icon: Icons.calendar_today_rounded,
      ),
      _FaqItem(
        question: 'Apa yang terjadi jika alat terlambat dikembalikan?',
        answer:
            'Keterlambatan pengembalian akan dikenakan biaya tambahan sesuai kebijakan toko rental. Hubungi pemilik rental jika ada kendala pengembalian.',
        icon: Icons.schedule_rounded,
      ),
    ],
    // Pembayaran
    [
      _FaqItem(
        question: 'Metode pembayaran apa yang tersedia?',
        answer:
            'NatureRent saat ini menggunakan QRIS sebagai metode pembayaran. Scan QR Code yang ditampilkan, lalu upload bukti pembayaran untuk konfirmasi.',
        icon: Icons.qr_code_rounded,
      ),
      _FaqItem(
        question: 'Bagaimana cara upload bukti pembayaran?',
        answer:
            'Setelah melakukan pembayaran via QRIS, kamu akan diarahkan ke halaman upload. Ambil foto struk atau screenshot konfirmasi pembayaran, lalu upload di halaman tersebut.',
        icon: Icons.upload_rounded,
      ),
      _FaqItem(
        question: 'Apakah pembayaran DP diperlukan?',
        answer:
            'Ya, sebagian besar toko rental memerlukan uang muka (DP) untuk mengkonfirmasi pesanan. Jumlah DP tergantung kebijakan masing-masing toko.',
        icon: Icons.account_balance_wallet_rounded,
      ),
      _FaqItem(
        question: 'Bagaimana jika pembayaran sudah dilakukan tapi belum dikonfirmasi?',
        answer:
            'Pesanan akan masuk ke status "Menunggu Verifikasi" setelah kamu upload bukti pembayaran. Pemilik rental akan memverifikasi dalam waktu 1x24 jam. Jika lebih dari itu, hubungi admin melalui WhatsApp.',
        icon: Icons.pending_rounded,
      ),
    ],
    // Akun
    [
      _FaqItem(
        question: 'Mengapa perlu verifikasi KTP?',
        answer:
            'Foto KTP diperlukan untuk memverifikasi identitas penyewa demi keamanan transaksi antara penyewa dan pemilik rental. Data ini dijaga kerahasiaannya.',
        icon: Icons.badge_rounded,
      ),
      _FaqItem(
        question: 'Bagaimana cara mengubah foto profil?',
        answer:
            'Buka halaman Profil → tekan "Edit Profil" → tekan area foto profil → pilih dari galeri atau ambil foto baru. Foto akan tersimpan otomatis setelah dikonfirmasi.',
        icon: Icons.camera_alt_rounded,
      ),
      _FaqItem(
        question: 'Bagaimana cara mendaftar sebagai Mitra Rental?',
        answer:
            'Daftar akun baru dan pilih opsi "Pemilik Rental" saat registrasi. Setelah masuk, lengkapi profil toko, tambahkan peralatan, dan atur lokasi GPS toko kamu.',
        icon: Icons.store_rounded,
      ),
      _FaqItem(
        question: 'Lupa password, bagaimana cara reset?',
        answer:
            'Di halaman Login, tekan "Lupa Password". Masukkan email akun kamu, lalu cek inbox email untuk link reset password yang dikirim dari Supabase.',
        icon: Icons.lock_reset_rounded,
      ),
    ],
    // Lainnya
    [
      _FaqItem(
        question: 'Bagaimana cara menghubungi admin?',
        answer:
            'Kamu bisa menghubungi admin NatureRent melalui WhatsApp resmi yang tercantum di aplikasi. Admin siap membantu kendala seputar pembayaran, pesanan, dan akun.',
        icon: Icons.support_agent_rounded,
      ),
      _FaqItem(
        question: 'Apakah ada program loyalitas atau diskon?',
        answer:
            'Program diskon dan loyalitas sedang dalam pengembangan. Pantau terus update terbaru NatureRent untuk promo menarik yang akan segera hadir!',
        icon: Icons.card_giftcard_rounded,
      ),
      _FaqItem(
        question: 'Apakah data saya aman?',
        answer:
            'Seluruh data disimpan secara aman menggunakan Supabase dengan enkripsi dan kebijakan Row-Level Security (RLS). Data kamu hanya bisa diakses oleh kamu sendiri dan admin yang berwenang.',
        icon: Icons.security_rounded,
      ),
    ],
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final faqs = _faqByCategory[_selectedCategory];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          // ── Header hero
          _buildHeroHeader(context),

          // ── Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                const SizedBox(height: 24),
                _buildCategoryChips(),
                const SizedBox(height: 20),
                _buildSectionTitle('Pertanyaan Umum'),
                const SizedBox(height: 12),

                // FAQ list dengan animasi per item
                ...faqs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _AnimatedFaqCard(
                    item: item,
                    index: index,
                    isExpanded: _expandedIndex == (_selectedCategory * 100 + index),
                    onToggle: () {
                      setState(() {
                        final key = _selectedCategory * 100 + index;
                        _expandedIndex = _expandedIndex == key ? null : key;
                      });
                    },
                    categoryColor: _categories[_selectedCategory].color,
                  );
                }),

                const SizedBox(height: 24),
                _buildContactBanner(),
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
          colors: [Color(0xFF14532D), Color(0xFF166534)],
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
              // Back button
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

              // Title with animation
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
                              Icons.help_outline_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'PUSAT BANTUAN',
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
                        'Ada yang bisa\nkami bantu?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temukan jawaban untuk pertanyaan\nseputar NatureRent di bawah ini.',
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

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = i == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = i;
              _expandedIndex = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? cat.color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? cat.color : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cat.color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1C1C1B),
      ),
    );
  }

  Widget _buildContactBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masih butuh bantuan?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Hubungi tim NatureRent via WhatsApp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xCCFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Chat',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF14532D),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  ANIMATED FAQ CARD
// ────────────────────────────────────────────────
class _AnimatedFaqCard extends StatefulWidget {
  final _FaqItem item;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color categoryColor;

  const _AnimatedFaqCard({
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
    required this.categoryColor,
  });

  @override
  State<_AnimatedFaqCard> createState() => _AnimatedFaqCardState();
}

class _AnimatedFaqCardState extends State<_AnimatedFaqCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 60),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
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
                  ? widget.categoryColor.withValues(alpha: 0.4)
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
                splashColor: widget.categoryColor.withValues(alpha: 0.05),
                highlightColor: widget.categoryColor.withValues(alpha: 0.03),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: widget.categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.item.icon,
                              size: 18,
                              color: widget.categoryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.item.question,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: widget.isExpanded
                                    ? widget.categoryColor
                                    : const Color(0xFF1C1C1B),
                                height: 1.35,
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
                                  ? widget.categoryColor
                                  : const Color(0xFF9CA3AF),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 280),
                        crossFadeState: widget.isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 14, left: 48),
                          child: Text(
                            widget.item.answer,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//  DATA MODELS
// ────────────────────────────────────────────────
class _HelpCategory {
  final String label;
  final IconData icon;
  final Color color;
  const _HelpCategory({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _FaqItem {
  final String question;
  final String answer;
  final IconData icon;
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.icon,
  });
}
