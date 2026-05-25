import 'auth_service.dart';

// ─────────────────────────────────────────────
//  Model: PlatformSettings
// ─────────────────────────────────────────────
class PlatformSettings {
  final int biayaLayanan;      // flat fee, Rp
  final double komisiPersen;   // % komisi platform dari subtotal rental
  final String? qrisImageUrl;  // URL gambar QRIS admin (null = belum diset)

  const PlatformSettings({
    required this.biayaLayanan,
    required this.komisiPersen,
    this.qrisImageUrl,
  });

  /// Default lokal — dipakai saat DB belum dikonfigurasi admin.
  static const PlatformSettings defaultSettings = PlatformSettings(
    biayaLayanan: 2000,
    komisiPersen: 10.0,
    qrisImageUrl: null,
  );
}

// ─────────────────────────────────────────────
//  PaymentService
// ─────────────────────────────────────────────
/// Service tunggal untuk mengambil konfigurasi pembayaran platform.
/// Hasilnya di-cache agar tidak perlu fetch berulang dalam satu sesi.
class PaymentService {
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;
  PaymentService._();

  PlatformSettings? _cached;

  // ── Ambil konfigurasi platform (cache + fallback lokal) ──────────────────
  Future<PlatformSettings> ambilPlatformSettings({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null) return _cached!;

    try {
      // 1. Biaya layanan + QRIS URL dari platform_settings
      final biayaData = await AuthService.client
          .from('platform_settings')
          .select('biaya_layanan, qris_image_url')
          .eq('id', 1)
          .maybeSingle();

      // 2. Komisi persen dari commission_settings (ambil yg terbaru)
      final komisiData = await AuthService.client
          .from('commission_settings')
          .select('percentage')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      _cached = PlatformSettings(
        biayaLayanan: (biayaData?['biaya_layanan'] as num?)?.toInt() ??
            PlatformSettings.defaultSettings.biayaLayanan,
        komisiPersen: (komisiData?['percentage'] as num?)?.toDouble() ??
            PlatformSettings.defaultSettings.komisiPersen,
        qrisImageUrl: biayaData?['qris_image_url'] as String?,
      );

      return _cached!;
    } catch (_) {
      // DB tidak tersedia / belum dikonfigurasi → pakai default lokal
      return PlatformSettings.defaultSettings;
    }
  }

  // ── Update biaya_layanan (dipanggil dari admin dashboard) ─────────────────
  Future<void> updateBiayaLayanan(int biayaBaru) async {
    await AuthService.client
        .from('platform_settings')
        .update({
          'biaya_layanan': biayaBaru,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 1);
    invalidateCache();
  }

  // ── Update QRIS image URL ─────────────────────────────────────────────────
  Future<void> updateQrisUrl(String url) async {
    await AuthService.client
        .from('platform_settings')
        .update({
          'qris_image_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 1);
    invalidateCache();
  }

  // ── Update komisi persen ──────────────────────────────────────────────────
  Future<void> updateKomisi(double persen) async {
    await AuthService.client.from('commission_settings').insert({
      'percentage': persen,
      'updated_by': AuthService().penggunaSaatIni?.id,
      'updated_at': DateTime.now().toIso8601String(),
    });
    invalidateCache();
  }

  /// Hapus cache agar fetch ulang dari DB di request berikutnya.
  void invalidateCache() => _cached = null;
}
