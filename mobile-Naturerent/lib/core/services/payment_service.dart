import 'auth_service.dart';

// ─────────────────────────────────────────────
//  Model: RentalQrisInfo
// ─────────────────────────────────────────────
/// Info QRIS milik satu rental spesifik dari tabel rental_profiles.
class RentalQrisInfo {
  final String rentalId;
  final String namaRental;
  final String? qrisImageUrl;
  final String? qrisMerchantName;

  const RentalQrisInfo({
    required this.rentalId,
    required this.namaRental,
    this.qrisImageUrl,
    this.qrisMerchantName,
  });

  bool get hasQris =>
      qrisImageUrl != null && qrisImageUrl!.isNotEmpty;
}

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
    final userId = AuthService().penggunaSaatIni?.id;
    await AuthService.client
        .from('platform_settings')
        .update({
          'biaya_layanan': biayaBaru,
          'updated_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 1);
    invalidateCache();
  }

  // ── Update QRIS image URL ─────────────────────────────────────────────────
  Future<void> updateQrisUrl(String url) async {
    final userId = AuthService().penggunaSaatIni?.id;
    await AuthService.client
        .from('platform_settings')
        .update({
          'qris_image_url': url,
          'updated_by': userId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 1);
    invalidateCache();
  }

  // ── Update komisi persen ──────────────────────────────────────────
  Future<void> updateKomisi(double persen) async {
    await AuthService.client.from('commission_settings').insert({
      'percentage': persen,
      'updated_by': AuthService().penggunaSaatIni?.id,
      'updated_at': DateTime.now().toIso8601String(),
    });
    invalidateCache();
  }

  // ── Ambil info QRIS untuk satu rental spesifik ──────────────────────
  /// Fetch `qris_image_url` dan `qris_merchant_name` langsung dari
  /// tabel `rental_profiles` untuk rental tertentu.
  Future<RentalQrisInfo?> ambilQrisRental(String rentalId) async {
    try {
      final data = await AuthService.client
          .from('rental_profiles')
          .select('id, nama_rental, qris_image_url, qris_merchant_name')
          .eq('id', rentalId)
          .maybeSingle();

      if (data == null) return null;
      return RentalQrisInfo(
        rentalId: data['id'] as String,
        namaRental: data['nama_rental'] as String,
        qrisImageUrl: data['qris_image_url'] as String?,
        qrisMerchantName: data['qris_merchant_name'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Ambil info QRIS untuk banyak rental sekaligus ─────────────────
  /// Fetch QRIS untuk list rentalId (misal: multi-rental checkout).
  Future<Map<String, RentalQrisInfo>> ambilQrisMultipleRental(
    List<String> rentalIds,
  ) async {
    if (rentalIds.isEmpty) return {};
    try {
      final data = await AuthService.client
          .from('rental_profiles')
          .select('id, nama_rental, qris_image_url, qris_merchant_name')
          .inFilter('id', rentalIds);

      final result = <String, RentalQrisInfo>{};
      for (final row in (data as List)) {
        final info = RentalQrisInfo(
          rentalId: row['id'] as String,
          namaRental: row['nama_rental'] as String,
          qrisImageUrl: row['qris_image_url'] as String?,
          qrisMerchantName: row['qris_merchant_name'] as String?,
        );
        result[info.rentalId] = info;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Hapus cache agar fetch ulang dari DB di request berikutnya.
  void invalidateCache() => _cached = null;
}
