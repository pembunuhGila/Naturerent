import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/cart_service.dart';
import '../../core/widgets/nr_image.dart';
import '../shell/main_shell.dart';

class PesananDetailPage extends StatefulWidget {
  final String namaRental;
  final double total;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final List<CartItem> items;
  final String? nomorPesanan;
  final String? statusLabel;
  final String? statusKey;
  final String? paymentProofUrl;
  final Uint8List? paymentProofBytes;

  const PesananDetailPage({
    super.key,
    required this.namaRental,
    required this.total,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.items,
    this.nomorPesanan,
    this.statusLabel,
    this.statusKey,
    this.paymentProofUrl,
    this.paymentProofBytes,
  });

  @override
  State<PesananDetailPage> createState() => _PesananDetailPageState();
}

class _PesananDetailPageState extends State<PesananDetailPage> {
  late final String _nomorPesanan;

  List<CartRentalGroup> get _groups {
    final map = <String, List<CartItem>>{};
    final firstItems = <String, CartItem>{};

    for (final item in widget.items) {
      final key = item.rental.id;
      firstItems[key] = item;
      map.putIfAbsent(key, () => []).add(item);
    }

    final groups = map.entries
        .map(
          (entry) => CartRentalGroup(
            rental: firstItems[entry.key]!.rental,
            items: List.unmodifiable(entry.value),
          ),
        )
        .toList();
    groups.sort((a, b) => a.rental.namaRental.compareTo(b.rental.namaRental));
    return groups;
  }

  @override
  void initState() {
    super.initState();
    if (widget.nomorPesanan != null) {
      _nomorPesanan = widget.nomorPesanan!;
      return;
    }
    // Generate nomor pesanan acak: e.g. #A7B2-XK
    final r = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final part1 =
        List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    final part2 =
        List.generate(2, (_) => chars[r.nextInt(chars.length)]).join();
    _nomorPesanan = '$part1-$part2';
  }

  String _fmtTgl(DateTime dt) {
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (r) => false,
                      );
                    },
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Riwayat Pesanan',
                      style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.textPrimary, fontSize: 20)),
                ],
              ),
            ),

            // ── Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  // ── Order card
                  _buildOrderCard(),
                  const SizedBox(height: 16),
                  _buildPaymentProofCard(),
                  const SizedBox(height: 16),

                  // ── Timeline
                  _buildTimeline(),
                  const SizedBox(height: 24),

                  // ── Kembali ke Beranda button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const MainShell()),
                        (r) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('Kembali ke Beranda',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
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

  // ─── Order card
  Widget _buildPaymentProofCard() {
    final hasBytes = widget.paymentProofBytes != null;
    final hasUrl = widget.paymentProofUrl != null &&
        widget.paymentProofUrl!.trim().isNotEmpty;

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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bukti Pembayaran QRIS',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 180, maxHeight: 360),
              color: AppColors.surfaceVariant,
              child: hasBytes
                  ? Image.memory(
                      widget.paymentProofBytes!,
                      fit: BoxFit.cover,
                    )
                  : hasUrl
                      ? _buildProofImageFromUrl(widget.paymentProofUrl!)
                      : _buildProofPlaceholder(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bukti ini akan dicek admin sebelum pemilik rental mengonfirmasi alat.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImageFromUrl(String url) {
    if (url.startsWith('data:image/')) {
      final comma = url.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(url.substring(comma + 1));
          return Image.memory(bytes, fit: BoxFit.cover);
        } catch (_) {
          return _buildProofPlaceholder();
        }
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildProofPlaceholder(),
    );
  }

  Widget _buildProofPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textHint,
              size: 34,
            ),
            const SizedBox(height: 8),
            Text(
              'Bukti pembayaran belum tersedia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
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
          // Header: nomor pesanan + badge status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PESANAN #$_nomorPesanan',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(widget.statusLabel ?? 'MENUNGGU ADMIN',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ..._groups.map((group) => _buildRentalGroup(group)),

          const Divider(height: 24, color: AppColors.border),

          // Total & tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Akhir',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                  const SizedBox(height: 2),
                  Text(_fmtRupiah(widget.total),
                      style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Periode Sewa',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtTgl(widget.tanggalMulai)} – ${_fmtTgl(widget.tanggalSelesai)}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalGroup(CartRentalGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
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
            ],
          ),
          const SizedBox(height: 10),
          ...group.items.map(_buildItemRow),
        ],
      ),
    );
  }

  Widget _buildItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: NrImage(
              imageUrl: item.equipment.gambarprimaryUrl,
              width: 72, height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori badge
                if (item.equipment.namaKategori != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.equipment.namaKategori!.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ),
                Text(item.equipment.nama,
                    style: AppTextStyles.headlineMedium
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(
                    _fmtRupiah(item.equipment.hargaPerHari),
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(' / Hari',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('${item.qty} Item',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline progress rental
  Widget _buildTimeline() {
    final rank = _statusRank(widget.statusKey);
    final steps = [
      _TimelineStep(
        icon: Icons.check_rounded,
        title: 'Bukti DP diupload',
        subtitle: 'Admin NatureRent memeriksa foto bukti pembayaran DP 30% yang kamu upload.',
        isDone: true,
        isActive: rank == 0,
      ),
      _TimelineStep(
        icon: Icons.verified_rounded,
        title: 'Menunggu ACC admin',
        subtitle: 'Setelah admin validasi pembayaran, pesanan diteruskan ke pemilik rental.',
        isDone: rank >= 1,
        isActive: rank == 1,
      ),
      _TimelineStep(
        icon: Icons.inventory_2_outlined,
        title: 'Alat diproses',
        subtitle: 'Peralatan disiapkan, dicek, dan siap diambil pada ${_fmtTgl(widget.tanggalMulai)}.',
        isDone: rank >= 2,
        isActive: rank == 2,
      ),
      _TimelineStep(
        icon: Icons.shopping_bag_rounded,
        title: 'Pesanan sedang disewa',
        subtitle: 'Peralatan sudah berada di tanganmu sampai ${_fmtTgl(widget.tanggalSelesai)}.',
        isDone: rank >= 3,
        isActive: rank == 3,
      ),
      _TimelineStep(
        icon: Icons.assignment_return_rounded,
        title: 'Peralatan dikembalikan',
        subtitle: 'Peralatan sudah dikembalikan ke pemilik rental dan sedang diperiksa.',
        isDone: rank >= 4,
        isActive: rank == 4,
      ),
      _TimelineStep(
        icon: Icons.payments_rounded,
        title: 'Selesai',
        subtitle: 'Pesanan selesai. Terima kasih sudah menggunakan NatureRent.',
        isDone: rank >= 5,
        isActive: rank >= 5,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proses Rental',
              style: AppTextStyles.headlineMedium
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((e) {
            final isLast = e.key == steps.length - 1;
            return _buildTimelineItem(e.value, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineStep step, bool isLast) {
    final Color dotColor = step.isDone
        ? AppColors.primaryDark
        : AppColors.border;
    final Color textColor =
        step.isDone ? AppColors.textPrimary : AppColors.textHint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Dot + Line column
        Column(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon,
                  size: 16,
                  color: step.isDone ? Colors.white : AppColors.textHint),
            ),
            if (!isLast)
              Container(
                width: 2, height: 56,
                color: step.isDone ? AppColors.primaryDark : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // ── Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: step.isActive
                            ? AppColors.primaryDark
                            : textColor)),
                const SizedBox(height: 4),
                Text(step.subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

int _statusRank(String? status) {
  return switch (status) {
    'confirmed' => 1,
    'processing' => 2,
    'rented' => 3,
    'returned' => 5,
    'completed' => 5,
    'cancelled' => 0,
    _ => 0,
  };
}

class _TimelineStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
  });
}
