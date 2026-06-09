import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naturerent/core/theme/app_theme.dart';
import 'package:naturerent/core/services/cart_service.dart';
import 'package:naturerent/core/services/order_activity_service.dart';
import 'package:naturerent/core/widgets/nr_image.dart';
import 'package:naturerent/features/user/widgets/user_shell.dart';
import 'return_detail_page.dart';

class PesananDetailPage extends StatefulWidget {
  final String namaRental;
  final double total;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final List<CartItem> items;
  final String? orderRefId;
  final String? nomorPesanan;
  final String? statusLabel;
  final String? statusKey;
  final String? paymentProofUrl;
  final Uint8List? paymentProofBytes;
  final String? cancellationReason;
  final String? cancellationNote;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationStatus;
  final String? refundProofUrl;
  final DateTime? refundUploadedAt;
  final String? refundStatus;

  const PesananDetailPage({
    super.key,
    required this.namaRental,
    required this.total,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.items,
    this.orderRefId,
    this.nomorPesanan,
    this.statusLabel,
    this.statusKey,
    this.paymentProofUrl,
    this.paymentProofBytes,
    this.cancellationReason,
    this.cancellationNote,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationStatus,
    this.refundProofUrl,
    this.refundUploadedAt,
    this.refundStatus,
  });

  @override
  State<PesananDetailPage> createState() => _PesananDetailPageState();
}

class _PesananDetailPageState extends State<PesananDetailPage> {
  late final String _nomorPesanan;
  String? _paymentProofUrl;
  Uint8List? _decodedProofBytes;
  String? _refundProofUrl;
  DateTime? _refundUploadedAt;
  String? _refundStatus;
  bool _loadingRefundProof = false;
  bool _loadingProof = false;
  bool _cancellingOrder = false;

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
    _paymentProofUrl = widget.paymentProofUrl;
    _refundProofUrl = widget.refundProofUrl;
    _refundUploadedAt = widget.refundUploadedAt;
    _refundStatus = widget.refundStatus;
    _loadPaymentProofIfNeeded();
    _loadRefundProofIfNeeded();
    if (widget.nomorPesanan != null) {
      _nomorPesanan = widget.nomorPesanan!;
      return;
    }
    // Generate nomor pesanan acak: e.g. #A7B2-XK
    final r = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final part1 = List.generate(
      4,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
    final part2 = List.generate(
      2,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
    _nomorPesanan = '$part1-$part2';
  }

  Future<void> _loadPaymentProofIfNeeded() async {
    if (widget.paymentProofBytes != null ||
        (_paymentProofUrl != null && _paymentProofUrl!.trim().isNotEmpty) ||
        widget.orderRefId == null) {
      return;
    }

    setState(() => _loadingProof = true);
    try {
      final proof = await OrderActivityService().ambilBuktiPembayaran(
        widget.orderRefId!,
      );
      if (!mounted) return;
      setState(() => _paymentProofUrl = proof);
    } catch (_) {
      // Bukti pembayaran bukan blocker untuk detail pesanan.
    } finally {
      if (mounted) setState(() => _loadingProof = false);
    }
  }

  Future<void> _loadRefundProofIfNeeded() async {
    if (widget.statusKey != 'cancelled' ||
        (_refundProofUrl != null && _refundProofUrl!.trim().isNotEmpty) ||
        widget.orderRefId == null) {
      return;
    }

    setState(() => _loadingRefundProof = true);
    try {
      final proof = await OrderActivityService().ambilBuktiRefund(
        widget.orderRefId!,
      );
      if (!mounted || proof == null) return;
      setState(() {
        _refundProofUrl = proof.proofUrl;
        _refundUploadedAt = proof.uploadedAt;
        _refundStatus = proof.status;
      });
    } catch (_) {
      // Bukti refund bukan blocker untuk membuka detail pesanan.
    } finally {
      if (mounted) setState(() => _loadingRefundProof = false);
    }
  }

  String _fmtTgl(DateTime dt) {
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

  String _fmtDateTime(DateTime dt) {
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${_fmtTgl(dt)} $time';
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
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Riwayat Pesanan',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
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
                  if (_isCancelledOrder) ...[
                    _buildCancellationInfoCard(),
                    const SizedBox(height: 24),
                  ],
                  if (_canCancelOrder) ...[
                    _buildCancelOrderCard(),
                    const SizedBox(height: 24),
                  ],
                  if (_canShowReturnOption) ...[
                    _buildReturnOptions(),
                    const SizedBox(height: 24),
                  ],

                  // ── Kembali ke Beranda button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (r) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Kembali ke Beranda',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
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
  bool get _canShowReturnOption => widget.statusKey == 'rented';

  bool get _isCancelledOrder => widget.statusKey == 'cancelled';

  bool get _canCancelOrder {
    if (widget.orderRefId == null) return false;
    return widget.statusKey == 'pending' ||
        widget.statusKey == 'confirmed' ||
        widget.statusKey == 'processing';
  }

  Widget _buildPaymentProofCard() {
    final hasBytes = widget.paymentProofBytes != null;
    final hasUrl =
        _paymentProofUrl != null && _paymentProofUrl!.trim().isNotEmpty;

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
              child: _loadingProof
                  ? _buildProofLoading()
                  : hasBytes
                  ? Image.memory(
                      widget.paymentProofBytes!,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                    )
                  : hasUrl
                  ? _buildProofImageFromUrl(_paymentProofUrl!)
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
          _decodedProofBytes ??= base64Decode(url.substring(comma + 1));
          return Image.memory(
            _decodedProofBytes!,
            fit: BoxFit.cover,
            cacheWidth: 900,
          );
        } catch (_) {
          return _buildProofPlaceholder();
        }
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 900,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildProofLoading();
      },
      errorBuilder: (_, _, _) => _buildProofPlaceholder(),
    );
  }

  Widget _buildProofLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
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

  Widget _buildCancelOrderCard() {
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.error,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pembatalan Pesanan',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pesanan masih bisa dibatalkan sebelum peralatan diambil.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _cancellingOrder ? null : _showCancelOrderDialog,
              icon: _cancellingOrder
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close_rounded, size: 18),
              label: Text(
                _cancellingOrder ? 'Membatalkan...' : 'Batalkan Pesanan',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationInfoCard() {
    final status = widget.cancellationStatus ??
        (widget.cancelledBy == 'user'
            ? 'Dibatalkan Penyewa'
            : 'Dibatalkan Admin');
    final reason = widget.cancellationReason?.trim();
    final note = widget.cancellationNote?.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CancellationLine(
            label: 'Alasan',
            value: reason == null || reason.isEmpty
                ? 'Alasan pembatalan belum tersedia'
                : reason,
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CancellationLine(label: 'Catatan', value: note),
          ],
          if (widget.cancelledAt != null) ...[
            const SizedBox(height: 8),
            _CancellationLine(
              label: 'Dibatalkan pada',
              value: _fmtDateTime(widget.cancelledAt!),
            ),
          ],
          const SizedBox(height: 12),
          _CancellationLine(
            label: 'Refund',
            value: _loadingRefundProof
                ? 'Memuat bukti transfer...'
                : _refundStatus?.trim().isNotEmpty == true
                ? _refundStatus!
                : 'Bukti transfer belum tersedia',
          ),
          if (_refundProofUrl?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _refundProofUrl!.startsWith('data:image')
                  ? Image.memory(
                      UriData.parse(_refundProofUrl!).contentAsBytes(),
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _refundProofUrl!,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 140,
                        alignment: Alignment.center,
                        color: AppColors.surfaceVariant,
                        child: Text(
                          'Bukti transfer gagal dimuat.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
            if (_refundUploadedAt != null) ...[
              const SizedBox(height: 8),
              _CancellationLine(
                label: 'Bukti diupload pada',
                value: _fmtDateTime(_refundUploadedAt!),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _showCancelOrderDialog() async {
    final formKey = GlobalKey<FormState>();
    final noteController = TextEditingController();
    final pageContext = context;
    String? selectedReason;
    const reasons = [
      'Jadwal berubah',
      'Salah memilih tanggal',
      'Salah memilih alat',
      'Menemukan rental lain',
      'Tidak jadi menyewa',
      'Alasan lainnya',
    ];

    final cancelled = await showDialog<bool>(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final confirmed = await showDialog<bool>(
                context: pageContext,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Pembatalan'),
                  content: const Text(
                    'Apakah Anda yakin ingin membatalkan pesanan ini?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Kembali'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Ya, Batalkan'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || widget.orderRefId == null) return;

              var success = false;
              setState(() => _cancellingOrder = true);
              setDialogState(() {});
              try {
                await OrderActivityService().batalkanPesananPenyewa(
                  orderRefId: widget.orderRefId!,
                  reason: selectedReason!,
                  note: noteController.text,
                );
                if (!mounted) return;
                success = true;
                setState(() => _cancellingOrder = false);
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan berhasil dibatalkan'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
                Navigator.pop(dialogContext, true);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membatalkan pesanan: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } finally {
                if (mounted && !success) {
                  setState(() => _cancellingOrder = false);
                  setDialogState(() {});
                }
              }
            }

            return AlertDialog(
              title: const Text('Batalkan Pesanan'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Silakan pilih atau tuliskan alasan pembatalan pesanan.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedReason,
                        items: reasons
                            .map(
                              (reason) => DropdownMenuItem(
                                value: reason,
                                child: Text(reason),
                              ),
                            )
                            .toList(),
                        onChanged: _cancellingOrder
                            ? null
                            : (value) => setDialogState(
                                () => selectedReason = value,
                              ),
                        decoration: const InputDecoration(
                          labelText: 'Alasan pembatalan',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Pilih alasan pembatalan terlebih dahulu'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        enabled: !_cancellingOrder,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Alasan tambahan',
                          hintText: 'Tulis catatan pembatalan jika diperlukan',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final note = value?.trim() ?? '';
                          if (selectedReason == 'Alasan lainnya' &&
                              note.isEmpty) {
                            return 'Tuliskan alasan pembatalan';
                          }
                          if (note.isNotEmpty && note.length < 10) {
                            return 'Alasan pembatalan minimal 10 karakter';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _cancellingOrder
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                  ),
                  onPressed: _cancellingOrder ? null : submit,
                  child: Text(
                    _cancellingOrder ? 'Mengirim...' : 'Kirim Pembatalan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();
    if (cancelled == true && mounted) {
      await Future<void>.delayed(Duration.zero);
      if (mounted && Navigator.canPop(pageContext)) {
        Navigator.pop(pageContext, true);
      }
    }
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
              Text(
                'PESANAN #$_nomorPesanan',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.statusLabel ?? 'MENUNGGU ADMIN',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
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
                  Text(
                    'Total Pembayaran',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtRupiah(widget.total),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Periode Sewa',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtTgl(widget.tanggalMulai)} – ${_fmtTgl(widget.tanggalSelesai)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Status Pembayaran: Lunas',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
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
              const Icon(
                Icons.storefront_rounded,
                size: 16,
                color: AppColors.primary,
              ),
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
                // Kategori badge
                if (item.equipment.namaKategori != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
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
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Text(
                  item.equipment.nama,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _fmtRupiah(item.equipment.hargaPerHari),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' / Hari',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.qty} Item',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
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

  // ─── Timeline progress rental
  Widget _buildReturnOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReturnOptionCard(
                rentalName: group.rental.namaRental,
                itemCount: group.items.fold<int>(
                  0,
                  (sum, item) => sum + item.qty,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReturnDetailPage(
                      rental: group.rental,
                      items: group.items,
                      returnDate: widget.tanggalSelesai,
                      statusLabel:
                          widget.statusLabel ?? 'Menunggu Pengembalian',
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTimeline() {
    final rank = _statusRank(widget.statusKey);
    final steps = [
      _TimelineStep(
        icon: Icons.check_rounded,
        title: 'Bukti pembayaran diupload',
        subtitle:
            'Admin NatureRent memeriksa foto bukti pembayaran yang kamu upload.',
        isDone: true,
        isActive: rank == 0,
      ),
      _TimelineStep(
        icon: Icons.verified_rounded,
        title: 'Menunggu ACC admin',
        subtitle:
            'Setelah admin validasi pembayaran, pesanan diteruskan ke pemilik rental.',
        isDone: rank >= 1,
        isActive: rank == 1,
      ),
      _TimelineStep(
        icon: Icons.inventory_2_outlined,
        title: 'Alat diproses',
        subtitle:
            'Peralatan disiapkan, dicek, dan siap diambil pada ${_fmtTgl(widget.tanggalMulai)}.',
        isDone: rank >= 2,
        isActive: rank == 2,
      ),
      _TimelineStep(
        icon: Icons.shopping_bag_rounded,
        title: 'Pesanan sedang disewa',
        subtitle:
            'Peralatan sudah berada di tanganmu sampai ${_fmtTgl(widget.tanggalSelesai)}.',
        isDone: rank >= 3,
        isActive: rank == 3,
      ),
      _TimelineStep(
        icon: Icons.assignment_return_rounded,
        title: 'Peralatan dikembalikan',
        subtitle:
            'Peralatan sudah dikembalikan ke pemilik rental dan sedang diperiksa.',
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
          Text(
            'Proses Rental',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
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
    final Color textColor = step.isDone
        ? AppColors.textPrimary
        : AppColors.textHint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Dot + Line column
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                size: 16,
                color: step.isDone ? Colors.white : AppColors.textHint,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 56,
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
                Text(
                  step.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: step.isActive ? AppColors.primaryDark : textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CancellationLine extends StatelessWidget {
  final String label;
  final String value;

  const _CancellationLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReturnOptionCard extends StatelessWidget {
  final String rentalName;
  final int itemCount;
  final VoidCallback onTap;

  const _ReturnOptionCard({
    required this.rentalName,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_return_rounded,
                  color: AppColors.primaryDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengembalian Barang',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$itemCount item dari $rentalName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kembalikan peralatan ke lokasi toko rental sesuai titik yang tertera.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: const Text('Lihat Lokasi Pengembalian'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
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
