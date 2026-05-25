import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/cart_service.dart';
import '../../core/widgets/nr_image.dart';
import '../../core/widgets/nr_toast.dart';
import 'date_picker_sheet.dart';
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

  // ─── Durasi (hari)
  int get _durasi {
    if (_tanggalMulai == null || _tanggalSelesai == null) return 0;
    final hari = _tanggalSelesai!.difference(_tanggalMulai!).inDays;
    return hari <= 0 ? 1 : hari;
  }

  // ─── Format helpers
  String _fmtTgl(DateTime? dt) {
    if (dt == null) return 'Belum dipilih';
    const b = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
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
  void _bayar() {
    if (_cart.items.isEmpty) {
      _snack('Keranjang kosong. Tambah alat terlebih dahulu.');
      return;
    }
    if (_tanggalMulai == null || _tanggalSelesai == null) {
      _snack('Pilih rentang tanggal sewa terlebih dahulu.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrisPage(
          total: _cart.totalBayar(_durasi),
          namaRental: _cart.groupedByRental.length == 1
              ? _cart.groupedByRental.first.rental.namaRental
              : '${_cart.groupedByRental.length} Toko Rental',
          tanggalMulai: _tanggalMulai!,
          tanggalSelesai: _tanggalSelesai!,
          items: List<CartItem>.from(_cart.items),
        ),
      ),
    );
  }

  void _snack(String msg) {
    NrToast.show(context, msg, type: NrToastType.info);
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
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Checkout',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: AppColors.textPrimary, fontSize: 20)),
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
                    header: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Item Sewa',
                            style: AppTextStyles.headlineMedium.copyWith(
                                fontWeight: FontWeight.w700)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(children: [
                            const Icon(Icons.add_circle_rounded,
                                color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text('TAMBAH PESANAN',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10)),
                          ]),
                        ),
                      ],
                    ),
                    child: _cart.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('Keranjang kosong',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textHint)),
                            ))
                        : Column(
                            children: _cart.groupedByRental
                                .map(
                                  (group) => _RentalCartGroupView(
                                    group: group,
                                    onHapus: (item) => setState(
                                      () => _cart.hapusItem(item),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ── Rentang Waktu Sewa
                  _buildSection(
                    header: Text('Rentang Waktu Sewa',
                        style: AppTextStyles.headlineMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    child: Column(
                      children: [
                        _buildTanggalRow(
                          label: 'TANGGAL PINJAM',
                          value: _fmtTgl(_tanggalMulai),
                          icon: Icons.calendar_today_rounded,
                          onTap: _pilihTanggal,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _buildTanggalRow(
                          label: 'TANGGAL KEMBALI',
                          value: _fmtTgl(_tanggalSelesai),
                          icon: Icons.event_available_rounded,
                          onTap: _pilihTanggal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Metode Pengambilan
                  _buildSection(
                    header: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Metode Pengambilan',
                            style: AppTextStyles.headlineMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        GestureDetector(
                          onTap: _pilihTanggal,
                          child: Text('PILIH OPSI',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _MetodeRow(
                          isSelected: _metodeAmbil == 0,
                          icon: Icons.store_rounded,
                          judul: 'Self Pickup',
                          subjudul: 'Ambil langsung di basecamp',
                          onTap: () =>
                              setState(() => _metodeAmbil = 0),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _MetodeRow(
                          isSelected: _metodeAmbil == 1,
                          icon: Icons.delivery_dining_rounded,
                          judul: 'Delivery',
                          subjudul: 'Kirim ke lokasi Anda',
                          onTap: () =>
                              setState(() => _metodeAmbil = 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Metode Pembayaran
                  _buildSection(
                    header: Text('Metode\nPembayaran',
                        style: AppTextStyles.headlineMedium
                            .copyWith(fontWeight: FontWeight.w700)),
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
                    header: Row(children: [
                      const Icon(Icons.receipt_long_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Rincian Biaya Sewa',
                          style: AppTextStyles.headlineMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    child: Column(
                      children: [
                        // Durasi
                        _BiayaRow(
                          label: 'Durasi Sewa',
                          value: _durasi > 0 ? '$_durasi Hari' : '-',
                          isHighlight: false,
                        ),
                        const SizedBox(height: 8),
                        // Item breakdown
                        ..._cart.groupedByRental.expand(
                          (group) => [
                            _BiayaRow(
                              label: group.rental.namaRental,
                              value: _durasi > 0
                                  ? _fmtRupiah(
                                      group.subtotalPerHari * _durasi)
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
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL PEMBAYARAN',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                            Text(
                              _durasi > 0
                                  ? _fmtRupiah(
                                      _cart.totalBayar(_durasi))
                                  : _fmtRupiah(
                                      _cart.totalPerHari),
                              style: AppTextStyles.displayLarge.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ],
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
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border:
              const Border(top: BorderSide(color: AppColors.border, width: 1)),
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
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('BAYAR SEKARANG',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    )),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded,
                    size: 11, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text('Transaksi Terenkripsi & Aman',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint, fontSize: 11)),
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
                    child: const Icon(Icons.chat_rounded,
                        size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text('Butuh Bantuan? Hubungi tim kurator kami di WhatsApp',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary, fontSize: 11)),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 14),
          child,
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                        fontSize: 10,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
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

  const _RentalCartGroupView({required this.group, required this.onHapus});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
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
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...group.items.map(
            (item) => _ItemSewaRow(item: item, onHapus: () => onHapus(item)),
          ),
        ],
      ),
    );
  }
}

class _ItemSewaRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onHapus;
  const _ItemSewaRow({required this.item, required this.onHapus});

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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: NrImage(
              imageUrl: item.equipment.gambarprimaryUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.equipment.namaKategori?.toUpperCase() ??
                      'TENTS',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 2),
                Text(item.equipment.nama,
                    style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  _fmtRupiah(item.equipment.hargaPerHari),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textHint, size: 20),
          ),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.border,
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
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (subjudul != null)
                  Text(subjudul!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
              ],
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
  const _BiayaRow(
      {required this.label, required this.value, required this.isHighlight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary)),
          ),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  color: isHighlight
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}
