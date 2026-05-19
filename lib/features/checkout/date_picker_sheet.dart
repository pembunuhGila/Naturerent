import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet untuk memilih rentang tanggal sewa.
/// Return: Map {'mulai': DateTime, 'selesai': DateTime} atau null jika dibatalkan.
Future<Map<String, DateTime>?> showDatePickerSheet(
  BuildContext context, {
  DateTime? awal,
  DateTime? akhir,
}) {
  return showModalBottomSheet<Map<String, DateTime>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DatePickerSheet(awal: awal, akhir: akhir),
  );
}

class _DatePickerSheet extends StatefulWidget {
  final DateTime? awal;
  final DateTime? akhir;
  const _DatePickerSheet({this.awal, this.akhir});

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _bulan;   // bulan yang sedang ditampilkan
  DateTime? _mulai;
  DateTime? _selesai;

  @override
  void initState() {
    super.initState();
    _mulai = widget.awal;
    _selesai = widget.akhir;
    _bulan = DateTime(_mulai?.year ?? DateTime.now().year,
        _mulai?.month ?? DateTime.now().month);
  }

  // ── Format helpers
  String _fmtTanggal(DateTime? dt) {
    if (dt == null) return '-';
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  String _fmtBulanTahun(DateTime dt) {
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${bulan[dt.month]} ${dt.year}';
  }

  // ── Navigasi bulan
  void _prevBulan() =>
      setState(() => _bulan = DateTime(_bulan.year, _bulan.month - 1));
  void _nextBulan() =>
      setState(() => _bulan = DateTime(_bulan.year, _bulan.month + 1));

  // ── Tap pada tanggal
  void _onTapTanggal(DateTime tgl) {
    setState(() {
      if (_mulai == null || (_mulai != null && _selesai != null)) {
        // Mulai pilihan baru
        _mulai = tgl;
        _selesai = null;
      } else {
        // Sudah ada mulai, set selesai
        if (tgl.isBefore(_mulai!)) {
          _selesai = _mulai;
          _mulai = tgl;
        } else {
          _selesai = tgl;
        }
      }
    });
  }

  bool _isInRange(DateTime tgl) {
    if (_mulai == null || _selesai == null) return false;
    return tgl.isAfter(_mulai!) && tgl.isBefore(_selesai!);
  }

  bool _isMulai(DateTime tgl) =>
      _mulai != null && _isSameDay(tgl, _mulai!);
  bool _isSelesai(DateTime tgl) =>
      _selesai != null && _isSameDay(tgl, _selesai!);
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Build kalender
  List<DateTime?> _getDays() {
    final firstDay = DateTime(_bulan.year, _bulan.month, 1);
    final lastDay = DateTime(_bulan.year, _bulan.month + 1, 0);
    // Offset (Minggu=0)
    final offset = firstDay.weekday % 7;
    final days = <DateTime?>[];
    // Padding awal
    for (int i = 0; i < offset; i++) {
      final prev = firstDay.subtract(Duration(days: offset - i));
      days.add(prev);
    }
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(_bulan.year, _bulan.month, d));
    }
    // Padding akhir sampai 6 baris
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDays();
    bool isCurrentMonth(d) => d != null && d.month == _bulan.month;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          // X button + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Pilih Tanggal Rental',
                    style: AppTextStyles.headlineLarge
                        .copyWith(color: AppColors.textPrimary, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Headline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tentukan Waktu\nPetualanganmu.',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 26, height: 1.2,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 6),
                Text('Ayo pilih rentang tanggal sewa untuk melihat\nperlengkapan yang tersedia',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tanggal boxes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _TanggalBox(
                  label: 'TANGGAL PENYEWAAN',
                  value: _fmtTanggal(_mulai),
                )),
                const SizedBox(width: 12),
                Expanded(child: _TanggalBox(
                  label: 'TANGGAL PENGEMBALIAN',
                  value: _fmtTanggal(_selesai),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Header bulan
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _prevBulan,
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 24),
                ),
                Text(_fmtBulanTahun(_bulan),
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: Colors.white)),
                GestureDetector(
                  onTap: _nextBulan,
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              )),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisExtent: 44),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final tgl = days[i];
                if (tgl == null) return const SizedBox();
                final inCurrent = isCurrentMonth(tgl);
                final isMulai = _isMulai(tgl);
                final isSelesai = _isSelesai(tgl);
                final inRange = _isInRange(tgl);

                return GestureDetector(
                  onTap: inCurrent ? () => _onTapTanggal(tgl) : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 2, horizontal: 1),
                    decoration: BoxDecoration(
                      color: (isMulai || isSelesai)
                          ? AppColors.primaryDark
                          : inRange
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        '${tgl.day}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: (isMulai || isSelesai)
                              ? Colors.white
                              : inCurrent
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                          fontWeight: (isMulai || isSelesai || inRange)
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_mulai != null && _selesai != null)
                    ? () => Navigator.pop(context, {
                          'mulai': _mulai!,
                          'selesai': _selesai!,
                        })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  disabledBackgroundColor:
                      AppColors.primaryDark.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const SizedBox(),
                label: Text(
                  'Konfirmasi Tanggal →',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TanggalBox extends StatelessWidget {
  final String label;
  final String value;
  const _TanggalBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                fontSize: 9,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              )),
        ],
      ),
    );
  }
}
