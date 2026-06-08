import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/widgets/nr_image.dart';
import '../../core/widgets/nr_toast.dart';
import '../profil/edit_profil_page.dart';
import 'date_picker_sheet.dart';
import 'delivery_location_page.dart';
import 'qris_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cart = CartService();

  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  int _metodeAmbil = 0; // 0 = Self Pickup, 1 = Delivery
  int _biayaLayanan = 2000; // default lokal, diupdate dari DB
  DeliveryLocationResult? _deliveryResult;

  // ─── Durasi (hari)
  int get _durasi {
    if (_tanggalMulai == null || _tanggalSelesai == null) return 0;
    final hari = _tanggalSelesai!.difference(_tanggalMulai!).inDays;
    return hari <= 0 ? 1 : hari;
  }

  double get _biayaDelivery =>
      _metodeAmbil == 1 ? (_deliveryResult?.totalFee ?? 0) : 0;

  double get _totalCheckout {
    final subtotal = _durasi > 0
        ? _cart.totalBayar(_durasi)
        : _cart.totalPerHari;
    return subtotal + _biayaLayanan + _biayaDelivery;
  }

  @override
  void initState() {
    super.initState();
    _muatBiayaLayanan();
  }

  Future<void> _muatBiayaLayanan() async {
    try {
      final s = await PaymentService().ambilPlatformSettings();
      if (mounted) setState(() => _biayaLayanan = s.biayaLayanan);
    } catch (_) {}
  }

  // ─── Format helpers
  String _fmtTgl(DateTime? dt) {
    if (dt == null) return 'Belum dipilih';
    const b = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${b[dt.month]} ${dt.year}';
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

  // ─── Pilih tanggal
  Future<void> _pilihTanggal() async {
    final result = await showDatePickerSheet(
      context,
      awal: _tanggalMulai,
      akhir: _tanggalSelesai,
    );
    if (result != null && mounted) {
      setState(() {
        _tanggalMulai = result['mulai'];
        _tanggalSelesai = result['selesai'];
      });
    }
  }

  // ─── Bayar
  Future<void> _bayar() async {
    if (_cart.items.isEmpty) {
      _snack('Keranjang kosong. Tambah alat terlebih dahulu.');
      return;
    }
    if (_tanggalMulai == null || _tanggalSelesai == null) {
      _snack('Pilih rentang tanggal sewa terlebih dahulu.');
      return;
    }

    final ktpOk = await _pastikanKtpTerisi();
    if (!ktpOk) return;
    if (!mounted) return;

    DeliveryLocationResult? deliveryResult;
    if (_metodeAmbil == 1) {
      deliveryResult = await Navigator.push<DeliveryLocationResult>(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryLocationPage(groups: _cart.groupedByRental),
        ),
      );
      if (deliveryResult == null) return;
      if (!mounted) return;
      setState(() => _deliveryResult = deliveryResult);
    }

    if (!mounted) return;

    // Fetch QRIS global admin dari Supabase platform_settings
    final globalQris = await PaymentService().ambilGlobalQris();

    if (!mounted) return;
    _bukaQris(deliveryResult ?? _deliveryResult, globalQris);
  }

  Future<bool> _pastikanKtpTerisi() async {
    final auth = AuthService();
    final user = auth.penggunaSaatIni;
    if (user == null) {
      _snack('Silakan login ulang sebelum melakukan peminjaman.');
      return false;
    }

    try {
      final data = await AuthService.client
          .from('users')
          .select('nama_lengkap, email, avatar_url, ktp_url')
          .eq('id', user.id)
          .maybeSingle();

      final ktpUrl = (data?['ktp_url'] as String?)?.trim();
      if (ktpUrl != null && ktpUrl.isNotEmpty) return true;

      if (!mounted) return false;
      final bukaEditProfil = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Lengkapi Foto KTP',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Upload foto KTP terlebih dahulu sebelum melakukan peminjaman alat.',
            style: TextStyle(height: 1.45, color: AppColors.textSecondary),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Edit Profil'),
            ),
          ],
        ),
      );

      if (bukaEditProfil != true || !mounted) return false;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfilPage(
            namaAwal:
                (data?['nama_lengkap'] as String?) ?? user.email ?? 'Pengguna',
            email: (data?['email'] as String?) ?? user.email ?? '-',
            avatarUrlAwal: data?['avatar_url'] as String?,
          ),
        ),
      );

      if (!mounted) return false;
      final refreshed = await AuthService.client
          .from('users')
          .select('ktp_url')
          .eq('id', user.id)
          .maybeSingle();
      final refreshedKtp = (refreshed?['ktp_url'] as String?)?.trim();
      if (refreshedKtp != null && refreshedKtp.isNotEmpty) return true;

      _snack('Foto KTP belum tersimpan. Upload KTP dulu ya.');
      return false;
    } catch (_) {
      if (mounted) {
        _snack('Data KTP belum bisa dicek. Coba lagi sebentar.');
      }
      return false;
    }
  }

  void _bukaQris(
    DeliveryLocationResult? deliveryResult,
    GlobalQrisInfo globalQris,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrisPage(
          // Kirim subtotal saja; QrisPage akan tambahkan biaya_layanan via PaymentService
          total: _cart.totalBayar(_durasi),
          namaRental: _cart.groupedByRental.length == 1
              ? _cart.groupedByRental.first.rental.namaRental
              : '${_cart.groupedByRental.length} Toko Rental',
          tanggalMulai: _tanggalMulai!,
          tanggalSelesai: _tanggalSelesai!,
          items: List<CartItem>.from(_cart.items),
          isDelivery: _metodeAmbil == 1,
          deliveryFee: _metodeAmbil == 1 ? (deliveryResult?.totalFee ?? 0) : 0,
          deliveryDistanceKm: _metodeAmbil == 1
              ? deliveryResult?.totalDistanceKm
              : null,
          deliveryFeesByRentalId: _metodeAmbil == 1
              ? deliveryResult?.feesByRentalId
              : null,
          globalQris: globalQris,
        ),
      ),
    );
  }

  void _snack(String msg) {
    NrToast.show(context, msg, type: NrToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

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
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Checkout',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  // ── Item Sewa
                  _buildSection(
                    header: _buildSectionHeader(
                      title: 'Item Sewa',
                      trailing: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: AppColors.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tambah',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: _cart.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Keranjang kosong',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: _cart.groupedByRental
                                .map(
                                  (group) => _RentalCartGroupView(
                                    group: group,
                                    onHapus: (item) => setState(
                                      () => _cart.hapusItem(item),
                                    ),
                                    onTambah: (item) => setState(
                                      () => _cart.tambahQty(item),
                                    ),
                                    onKurang: (item) => setState(
                                      () => _cart.kurangQty(item),
                                    ),
                                    durasiLabel: _durasi > 0
                                        ? '$_durasi Hari Sewa'
                                        : 'Pilih tanggal sewa',
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ── Rentang Waktu Sewa
                  _buildSection(
                    header: _buildSectionHeader(
                      title: 'Rentang Waktu Sewa',
                    ),
                    child: Column(
                      children: [
                        _buildTanggalRow(
                          label: 'Tanggal Mulai',
                          value: _fmtTgl(_tanggalMulai),
                          icon: Icons.calendar_today_rounded,
                          onTap: _pilihTanggal,
                        ),
                        const SizedBox(height: 10),
                        _buildTanggalRow(
                          label: 'Tanggal Selesai',
                          value: _fmtTgl(_tanggalSelesai),
                          icon: Icons.event_available_rounded,
                          onTap: _pilihTanggal,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timelapse_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Durasi Sewa',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _durasi > 0 ? '$_durasi Hari' : '-',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Metode Pengambilan
                  _buildSection(
                    header: _buildSectionHeader(
                      title: 'Metode Pengambilan',
                    ),
                    child: Column(
                      children: [
                        _MetodeRow(
                          isSelected: _metodeAmbil == 0,
                          icon: Icons.store_rounded,
                          judul: 'Self Pickup',
                          subjudul: 'Ambil langsung di basecamp',
                          onTap: () => setState(() {
                            _metodeAmbil = 0;
                            _deliveryResult = null;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _MetodeRow(
                          isSelected: _metodeAmbil == 1,
                          icon: Icons.delivery_dining_rounded,
                          judul: 'Delivery',
                          subjudul:
                              'Kirim ke lokasi Anda, ongkir Rp 2.000/km setelah 5 km',
                          onTap: () => setState(() => _metodeAmbil = 1),
                        ),
                        if (_metodeAmbil == 1 && _deliveryResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8F5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Jarak dicek: ${_deliveryResult!.totalDistanceKm.toStringAsFixed(1)} km',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  _fmtRupiah(_deliveryResult!.totalFee),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Metode Pembayaran
                  _buildSection(
                    header: _buildSectionHeader(
                      title: 'Metode Pembayaran',
                    ),
                    child: _MetodeRow(
                      isSelected: true,
                      icon: Icons.qr_code_2_rounded,
                      judul: 'QRIS',
                      subjudul: null,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Rincian Biaya
                  _buildSection(
                    header: _buildSectionHeader(
                      title: 'Rincian Biaya Sewa',
                      icon: Icons.receipt_long_rounded,
                    ),
                    child: Column(
                      children: [
                        // Durasi
                        _BiayaRow(
                          label: 'Durasi Sewa',
                          value: _durasi > 0 ? '$_durasi Hari' : '-',
                          isHighlight: false,
                        ),
                        const SizedBox(height: 8),
                        // Item breakdown per rental
                        ..._cart.groupedByRental.expand(
                          (group) => [
                            _BiayaRow(
                              label: group.rental.namaRental,
                              value: _durasi > 0
                                  ? _fmtRupiah(group.subtotalPerHari * _durasi)
                                  : _fmtRupiah(group.subtotalPerHari),
                              isHighlight: true,
                            ),
                            ...group.items.map(
                              (item) => _BiayaRow(
                                label:
                                    '${item.equipment.nama} (${_fmtRupiah(item.equipment.hargaPerHari)}x${item.qty}${_durasi > 0 ? 'x$_durasi' : ''})',
                                value: _durasi > 0
                                    ? _fmtRupiah(item.subtotal * _durasi)
                                    : _fmtRupiah(item.subtotal),
                                isHighlight: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Biaya layanan (dari platform_settings)
                        _BiayaRow(
                          label: 'Biaya layanan',
                          value: _fmtRupiah(_biayaLayanan.toDouble()),
                          isHighlight: false,
                        ),
                        if (_metodeAmbil == 1)
                          _BiayaRow(
                            label: _deliveryResult == null
                                ? 'Delivery (cek lokasi saat pembayaran)'
                                : 'Delivery (${_deliveryResult!.totalDistanceKm.toStringAsFixed(1)} km)',
                            value: _deliveryResult == null
                                ? 'Cek lokasi'
                                : _fmtRupiah(_biayaDelivery),
                            isHighlight: false,
                          ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Pembayaran',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _fmtRupiah(_totalCheckout),
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Action
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _bayar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'BAYAR SEKARANG',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 11,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Transaksi Terenkripsi & Aman',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Butuh Bantuan? Hubungi tim kurator kami di WhatsApp',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper builders
  Widget _buildSection({required Widget header, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, const SizedBox(height: 14), child],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    Widget? trailing,
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildTanggalRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  WIDGETS
// ═══════════════════════════════════════════════════════

class _RentalCartGroupView extends StatelessWidget {
  final CartRentalGroup group;
  final ValueChanged<CartItem> onHapus;
  final ValueChanged<CartItem> onTambah;
  final ValueChanged<CartItem> onKurang;
  final String durasiLabel;

  const _RentalCartGroupView({
    required this.group,
    required this.onHapus,
    required this.onTambah,
    required this.onKurang,
    required this.durasiLabel,
  });

  String _fmtRupiah(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer('Rp');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.rental.namaRental,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmtRupiah(group.subtotalPerHari),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...group.items.asMap().entries.map((entry) {
              final isLast = entry.key == group.items.length - 1;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: _ItemSewaRow(
                  item: item,
                  onHapus: () => onHapus(item),
                  onTambah: () => onTambah(item),
                  onKurang: () => onKurang(item),
                  durasiLabel: durasiLabel,
                  showDivider: !isLast,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ItemSewaRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onHapus;
  final VoidCallback onTambah;
  final VoidCallback onKurang;
  final String durasiLabel;
  final bool showDivider;

  const _ItemSewaRow({
    required this.item,
    required this.onHapus,
    required this.onTambah,
    required this.onKurang,
    required this.durasiLabel,
    this.showDivider = false,
  });

  String _fmtRupiah(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer('Rp');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Tampilkan selectedSize jika ada, fallback ke equipment.size
  String? _displaySize(CartItem cartItem) {
    if (cartItem.selectedSize != null && cartItem.selectedSize!.trim().isNotEmpty) {
      return cartItem.selectedSize!.trim();
    }
    final eqSize = cartItem.equipment.size;
    if (eqSize != null && eqSize.trim().isNotEmpty && !eqSize.contains(',') && !eqSize.contains(';')) {
      return eqSize.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: NrImage(
                imageUrl: item.equipment.gambarprimaryUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.equipment.nama,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              durasiLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onHapus,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_displaySize(item) != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Size ${_displaySize(item)!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _fmtRupiah(item.equipment.hargaPerHari),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      _QtyButton(
                        icon: Icons.remove_rounded,
                        onTap: onKurang,
                      ),
                      Container(
                        width: 34,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.qty}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add_rounded,
                        onTap: onTambah,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }
}

class _MetodeRow extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String judul;
  final String? subjudul;
  final VoidCallback onTap;
  const _MetodeRow({
    required this.isSelected,
    required this.icon,
    required this.judul,
    this.subjudul,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subjudul != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subjudul!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BiayaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  const _BiayaRow({
    required this.label,
    required this.value,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: isHighlight
                  ? AppColors.primaryDark
                  : AppColors.textPrimary,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryDark : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}
