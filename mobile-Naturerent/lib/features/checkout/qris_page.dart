import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/order_activity_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nr_toast.dart';
import '../home/aktivitas_page.dart';

class QrisPage extends StatefulWidget {
  final double total;
  final String namaRental;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final List<CartItem> items;
  final bool isDelivery;
  final double deliveryFee;
  final double? deliveryDistanceKm;
  final Map<String, double>? deliveryFeesByRentalId;

  /// Map dari rentalId ke RentalQrisInfo — sudah di-fetch oleh CheckoutPage
  /// sebelum navigasi ke sini, agar QRIS masing-masing rental tampil.
  final Map<String, RentalQrisInfo> rentalQrisMap;

  const QrisPage({
    super.key,
    required this.total,
    required this.namaRental,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.items,
    this.isDelivery = false,
    this.deliveryFee = 0,
    this.deliveryDistanceKm,
    this.deliveryFeesByRentalId,
    this.rentalQrisMap = const {},
  });

  @override
  State<QrisPage> createState() => _QrisPageState();
}

class _QrisPageState extends State<QrisPage> {
  // Countdown 15 menit
  static const _durasi = Duration(minutes: 15);
  final _picker = ImagePicker();
  late int _sisaDetik;
  Timer? _timer;
  bool _isMenyimpanBooking = false;
  PlatformSettings? _settings;
  bool _loadingSettings = true;

  // Index QRIS yang sedang ditampilkan (untuk multi-rental)
  int _selectedQrisIndex = 0;

  // ── Daftar rental unik dari cart items
  List<CartItem> get _uniqueRentalItems {
    final seen = <String>{};
    return widget.items.where((i) => seen.add(i.rental.id)).toList();
  }

  // ── QRIS yang sedang aktif ditampilkan
  RentalQrisInfo? get _activeQris {
    final rentals = _uniqueRentalItems;
    if (rentals.isEmpty) return null;
    if (_selectedQrisIndex >= rentals.length) return null;
    final rentalId = rentals[_selectedQrisIndex].rental.id;
    return widget.rentalQrisMap[rentalId];
  }

  // ── Kalkulasi harga ─────────────────────────────────────────────────────
  double get _biayaLayanan => (_settings?.biayaLayanan ?? 2000).toDouble();
  double get _subtotalSewa => widget.total;
  double get _totalAkhir => _subtotalSewa + _biayaLayanan + widget.deliveryFee;

  @override
  void initState() {
    super.initState();
    _sisaDetik = _durasi.inSeconds;
    _mulaiTimer();
    _muatPlatformSettings();
  }

  Future<void> _muatPlatformSettings() async {
    try {
      final s = await PaymentService().ambilPlatformSettings();
      if (mounted) setState(() { _settings = s; _loadingSettings = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSettings = false);
    }
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
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw Exception('File bukti pembayaran kosong.');

      _timer?.cancel();
      await _bukaDetailPesanan(
        paymentProofBytes: bytes,
        paymentProofExtension: _extensionFromName(picked.name),
        paymentProofContentType: _contentTypeFromName(picked.name),
      );
    } catch (e) {
      if (!mounted) return;
      NrToast.show(
        context,
        'Bukti pembayaran gagal dipilih. Coba upload ulang.',
        type: NrToastType.error,
      );
      return;
    }
  }

  Future<void> _bukaDetailPesanan({
    required Uint8List paymentProofBytes,
    required String paymentProofExtension,
    required String paymentProofContentType,
  }) async {
    setState(() => _isMenyimpanBooking = true);

    try {
      await OrderActivityService().buatBookingDariKeranjang(
        namaRental: widget.namaRental,
        total: _totalAkhir,
        tanggalMulai: widget.tanggalMulai,
        tanggalSelesai: widget.tanggalSelesai,
        items: List<CartItem>.from(widget.items),
        biayaLayanan: _biayaLayanan,
        taxRate: 0,
        paymentProofBytes: paymentProofBytes,
        paymentProofExtension: paymentProofExtension,
        paymentProofContentType: paymentProofContentType,
        isDelivery: widget.isDelivery,
        deliveryFee: widget.deliveryFee,
        deliveryFeesByRentalId: widget.deliveryFeesByRentalId,
        deliveryDistanceKm: widget.deliveryDistanceKm,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMenyimpanBooking = false);
      NrToast.show(
        context,
        'Pesanan gagal tersimpan ke database: $e',
        type: NrToastType.error,
      );
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

  String _extensionFromName(String name) {
    final lower = name.toLowerCase();
    final ext = lower.contains('.') ? lower.split('.').last : 'jpg';
    return switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      'jpeg' => 'jpg',
      'jpg' => 'jpg',
      _ => 'jpg',
    };
  }

  String _contentTypeFromName(String name) {
    return switch (_extensionFromName(name)) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final rentalList = _uniqueRentalItems;
    final isMultiRental = rentalList.length > 1;

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

              // ── Tab pilih rental jika multi-rental
              if (isMultiRental) ...[
                _buildRentalTabs(rentalList),
                const SizedBox(height: 16),
              ],

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
                              Text(
                                _activeQris?.qrisMerchantName?.isNotEmpty == true
                                    ? _activeQris!.qrisMerchantName!
                                    : widget.namaRental,
                                style: AppTextStyles.headlineLarge.copyWith(
                                    color: Colors.white, fontSize: 16),
                              ),
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
                          // QR Code
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
                                Text('TOTAL PEMBAYARAN',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textHint,
                                        letterSpacing: 0.8,
                                        fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  _loadingSettings
                                      ? '...'
                                      : _fmtRupiah(_totalAkhir),
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
                            '3. Scan QR dan bayar ${_fmtRupiah(_totalAkhir)}',
                            '4. Screenshot atau simpan bukti pembayaran',
                            '5. Upload foto bukti lewat tombol di bawah',
                            '6. Pesanan masuk Riwayat menunggu verifikasi admin',
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
                      : Text('Upload Bukti Pembayaran',
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

  /// Tab selector jika ada beberapa rental di keranjang
  Widget _buildRentalTabs(List<CartItem> rentalItems) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rentalItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final rental = rentalItems[idx].rental;
          final qrisInfo = widget.rentalQrisMap[rental.id];
          final isActive = _selectedQrisIndex == idx;
          return GestureDetector(
            onTap: () => setState(() => _selectedQrisIndex = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryDark
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.primaryDark : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    qrisInfo?.hasQris == true
                        ? Icons.qr_code_2_rounded
                        : Icons.warning_amber_rounded,
                    size: 13,
                    color: isActive
                        ? Colors.white
                        : (qrisInfo?.hasQris == true
                            ? AppColors.primary
                            : Colors.orange),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rental.namaRental,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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

  Widget _buildQrisImage() {
    final activeQris = _activeQris;
    final qrisUrl = activeQris?.qrisImageUrl;
    final hasRentalQris = qrisUrl != null && qrisUrl.isNotEmpty;

    // Gunakan QRIS milik rental jika tersedia;
    // fallback ke QR code dummy jika QRIS belum dikonfigurasi.
    final url = hasRentalQris
        ? qrisUrl
        : 'https://api.qrserver.com/v1/create-qr-code/'
            '?size=200x200'
            '&data=NatureRent-${widget.namaRental}-${_totalAkhir.toInt()}'
            '&color=1B3A2D'
            '&bgcolor=FFFFFF';

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Image.network(
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
        ),
        // Badge "QRIS Belum Diatur" jika belum ada QRIS rental
        if (!hasRentalQris)
          Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Demo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
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
          _InfoRow(label: 'Total Harga Sewa', value: _fmtRupiah(_subtotalSewa)),
          _InfoRow(
            label: 'Biaya layanan',
            value: _loadingSettings ? '...' : _fmtRupiah(_biayaLayanan),
          ),
          if (widget.isDelivery)
            _InfoRow(
              label: widget.deliveryDistanceKm == null
                  ? 'Biaya delivery'
                  : 'Biaya delivery (${widget.deliveryDistanceKm!.toStringAsFixed(1)} km)',
              value: _fmtRupiah(widget.deliveryFee),
            ),
          const Divider(height: 14, color: AppColors.border),
          _InfoRow(
            label: 'Total Pembayaran',
            value: _loadingSettings ? '...' : _fmtRupiah(_totalAkhir),
            isStrong: true,
          ),
          const Divider(height: 14, color: AppColors.border),
          _InfoRow(
            label: 'Status pembayaran',
            value: 'Belum Dibayar',
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
