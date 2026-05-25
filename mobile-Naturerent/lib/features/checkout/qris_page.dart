import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/order_activity_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';
import '../home/aktivitas_page.dart';

class QrisPage extends StatefulWidget {
  final double total;
  final String namaRental;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final List<CartItem> items;

  const QrisPage({
    super.key,
    required this.total,
    required this.namaRental,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.items,
  });

  @override
  State<QrisPage> createState() => _QrisPageState();
}

class _QrisPageState extends State<QrisPage> {
  // Countdown 15 menit
  static const _durasi = Duration(minutes: 15);
  static const _nomorWaAdmin = '6285334772234';
  static const _qrisImageUrl = '';
  static const _tarifLayanan = 5000.0;
  static const _tarifPajak = 0.10;
  static const _tarifDp = 0.3;
  late int _sisaDetik;
  Timer? _timer;
  bool _isMenyimpanBooking = false;

  double get _subtotalSewa => widget.total;
  double get _dp => _subtotalSewa * _tarifDp;
  double get _sisaSewa => _subtotalSewa * (1 - _tarifDp);
  double get _pajak => _subtotalSewa * _tarifPajak;
  double get _biayaAplikasi => _tarifLayanan + _pajak;
  double get _pelunasan => _sisaSewa + _tarifLayanan + _pajak;
  double get _totalAkhir => _subtotalSewa + _tarifLayanan + _pajak;
  int get _dpPercent => (_tarifDp * 100).round();
  int get _sisaPercent => 100 - _dpPercent;
  int get _taxPercent => (_tarifPajak * 100).round();

  @override
  void initState() {
    super.initState();
    _sisaDetik = _durasi.inSeconds;
    _mulaiTimer();
  }

  void _mulaiTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_sisaDetik <= 0) {
        _timer?.cancel();
        _showExpired();
      } else {
        setState(() => _sisaDetik--);
      }
    });
  }

  void _showExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Waktu Habis',
            style: AppTextStyles.headlineLarge
                .copyWith(color: AppColors.textPrimary)),
        content: Text(
            'Kode QRIS sudah kadaluarsa. Silakan buat pesanan baru.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Kembali',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _kirimBuktiPembayaran() async {
    _timer?.cancel();

    final ringkasanItem = widget.items
        .map((item) => '- ${item.rental.namaRental}: ${item.equipment.nama} x${item.qty}')
        .join('\n');
    final pesan = Uri.encodeComponent(
      'Halo Admin NatureRent, saya sudah membayar DP $_dpPercent% via QRIS.\n\n'
      'Rental: ${widget.namaRental}\n'
      'Periode: ${_fmtTgl(widget.tanggalMulai)} - ${_fmtTgl(widget.tanggalSelesai)}\n'
      'Item:\n$ringkasanItem\n\n'
      'Subtotal sewa: ${_fmtRupiah(_subtotalSewa)}\n'
      'DP $_dpPercent% dibayar: ${_fmtRupiah(_dp)}\n'
      'Sisa $_sisaPercent%: ${_fmtRupiah(_sisaSewa)}\n'
      'Biaya aplikasi: ${_fmtRupiah(_biayaAplikasi)}\n'
      'Pelunasan saat pengembalian: ${_fmtRupiah(_pelunasan)}\n'
      'Total akhir: ${_fmtRupiah(_totalAkhir)}\n\n'
      'Saya akan kirim bukti pembayaran di chat ini.',
    );
    final uri = Uri.parse('https://wa.me/$_nomorWaAdmin?text=$pesan');

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('WhatsApp tidak bisa dibuka.');
    } catch (_) {
      if (!mounted) return;
      NrToast.show(
        context,
        'WhatsApp gagal dibuka. Hubungi admin: $_nomorWaAdmin',
        type: NrToastType.error,
      );
      return;
    }

    if (!mounted) return;
    await _bukaDetailPesanan();
  }

  Future<void> _bukaDetailPesanan() async {
    setState(() => _isMenyimpanBooking = true);

    try {
      await OrderActivityService().buatBookingDariKeranjang(
        namaRental: widget.namaRental,
        total: _totalAkhir,
        tanggalMulai: widget.tanggalMulai,
        tanggalSelesai: widget.tanggalSelesai,
        items: List<CartItem>.from(widget.items),
        biayaLayanan: _tarifLayanan,
        taxRate: _taxPercent.toDouble(),
        dpPercent: _dpPercent.toDouble(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMenyimpanBooking = false);
      _showTopMessage('Booking gagal disimpan. Cek policy Supabase bookings.');
      return;
    }

    CartService().bersihkan();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AktivitasPage(initialTab: 2),
      ),
      (route) => route.isFirst,
    );
  }

  void _showTopMessage(String message) {
    NrToast.show(context, message, type: NrToastType.error);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _fmtTimer {
    final m = _sisaDetik ~/ 60;
    final s = _sisaDetik % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtRupiah(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _fmtTgl(DateTime dt) {
    const b = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${b[dt.month]} ${dt.year}';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            children: [
              // ── App Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Pembayaran QRIS',
                      style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.textPrimary, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 28),

              // ── QR Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NatureRent',
                                  style: AppTextStyles.headlineLarge.copyWith(
                                      color: Colors.white, fontSize: 16)),
                              Text('Scan & Bayar',
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white70)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(_fmtTimer,
                                    style: AppTextStyles.headlineMedium
                                        .copyWith(
                                            color: Colors.white,
                                            fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // QR Code area
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // QR Code (generated from free API)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: _buildQrisImage(),
                          ),
                          const SizedBox(height: 16),

                          // Merchant info
                          Text(widget.namaRental,
                              style: AppTextStyles.headlineMedium.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${_fmtTgl(widget.tanggalMulai)} – ${_fmtTgl(widget.tanggalSelesai)}',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 12),

                          // Total
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text('DP DIBAYAR SEKARANG',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textHint,
                                        letterSpacing: 0.8,
                                        fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  _fmtRupiah(_dp),
                                  style: AppTextStyles.displayLarge.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildPaymentInfo(),
                        ],
                      ),
                    ),

                    // Panduan
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 10),
                          Text('Cara Membayar',
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          ...[
                            '1. Buka aplikasi e-wallet atau m-banking',
                            '2. Pilih menu Scan QR / QRIS',
                            '3. Bayar DP $_dpPercent% sebesar ${_fmtRupiah(_dp)}',
                            '4. Screenshot atau simpan bukti pembayaran',
                            '5. Kirim bukti ke admin lewat WhatsApp',
                            '6. Tunggu admin verifikasi dan pemilik rental mengonfirmasi alat',
                          ].map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 5, color: AppColors.textHint),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(s,
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isMenyimpanBooking ? null : _kirimBuktiPembayaran,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isMenyimpanBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Kirim Bukti via WhatsApp',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
                ),
              ),
              const SizedBox(height: 12),

              // Keamanan
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('Transaksi Terenkripsi & Aman',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrisImage() {
    const imageUrl = _qrisImageUrl;
    final url = imageUrl.isEmpty
        ? 'https://api.qrserver.com/v1/create-qr-code/'
            '?size=200x200'
            '&data=NatureRent-DP-${widget.namaRental}-${_dp.toInt()}'
            '&color=1B3A2D'
            '&bgcolor=FFFFFF'
        : imageUrl;

    return Image.network(
      url,
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) => Container(
        width: 200,
        height: 200,
        color: AppColors.background,
        child: const Center(
          child: Icon(
            Icons.qr_code_2_rounded,
            size: 100,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Subtotal sewa', value: _fmtRupiah(_subtotalSewa)),
          _InfoRow(label: 'DP $_dpPercent%', value: _fmtRupiah(_dp), isStrong: true),
          _InfoRow(label: 'Sisa $_sisaPercent%', value: _fmtRupiah(_sisaSewa)),
          const Divider(height: 18, color: AppColors.border),
          _InfoRow(
            label: 'Biaya aplikasi',
            value: _fmtRupiah(_biayaAplikasi),
          ),
          const Divider(height: 18, color: AppColors.border),
          _InfoRow(
            label: 'Dibayar saat pengembalian',
            value: _fmtRupiah(_pelunasan),
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStrong;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: isStrong ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: isStrong ? AppColors.primaryDark : AppColors.textPrimary,
              fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
