import 'auth_service.dart';

// ─────────────────────────────────────────────
//  Model: RentalQrisInfo (deprecated — pakai GlobalQrisInfo)
// ─────────────────────────────────────────────
/// Info QRIS milik satu rental spesifik dari tabel rental_profiles.
/// @deprecated: Admin beralih ke satu QRIS global. Gunakan [GlobalQrisInfo].
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
//  Model: GlobalQrisInfo
// ─────────────────────────────────────────────
/// QRIS tunggal milik admin platform, berlaku untuk semua rental.
/// Di-fetch dari tabel platform_settings (key = 'global_qris').
class GlobalQrisInfo {
  final String? imageUrl;
  final String? merchantName;

  const GlobalQrisInfo({this.imageUrl, this.merchantName});

  bool get hasQris => imageUrl != null && imageUrl!.isNotEmpty;

  /// Default ketika admin belum mengatur QRIS.
  static const GlobalQrisInfo empty = GlobalQrisInfo();
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

  // ── Ambil QRIS global admin (satu QRIS untuk semua rental) ───────────────
  /// Fetch dari platform_settings dengan key = 'global_qris'.
  /// Value disimpan sebagai JSON string: {"merchant_name": "...", "image_url": "..."}.
  Future<GlobalQrisInfo> ambilGlobalQris() async {
    try {
      final data = await AuthService.client
          .from('platform_settings')
          .select('value')
          .eq('key', 'global_qris')
          .maybeSingle();

      if (data == null || data['value'] == null) return GlobalQrisInfo.empty;

      // value bisa berupa String JSON atau Map (tergantung tipe kolom Supabase)
      Map<String, dynamic> parsed;
      final raw = data['value'];
      if (raw is Map) {
        parsed = Map<String, dynamic>.from(raw);
      } else {
        // Parse string JSON
        // ignore: avoid_dynamic_calls
        parsed = <String, dynamic>{};
        // Minimal safe parse tanpa dart:convert di core
        final str = raw.toString();
        final merchantMatch = RegExp(r'"merchant_name":"([^"]*)"').firstMatch(str);
        final imageMatch = RegExp(r'"image_url":"([^"]*)"').firstMatch(str);
        parsed['merchant_name'] = merchantMatch?.group(1);
        parsed['image_url'] = imageMatch?.group(1);
      }

      return GlobalQrisInfo(
        merchantName: parsed['merchant_name'] as String?,
        imageUrl: parsed['image_url'] as String?,
      );
    } catch (_) {
      return GlobalQrisInfo.empty;
    }
  }

  // ── Ambil info QRIS untuk satu rental spesifik (deprecated) ─────────────
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
