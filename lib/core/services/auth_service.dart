import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../../features/auth/onboarding_page.dart';

/// Satu-satunya pintu masuk ke Supabase Auth & data Users.
/// Nama method disesuaikan dengan Class Diagram (Bahasa Indonesia).
class AuthService {
  // Singleton ringan
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Akses cepat ke Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  // ──────────────────────────────────────────────────────────
  //  DAFTAR — signUp (Users.daftar)
  // ──────────────────────────────────────────────────────────
  /// Mendaftarkan user baru ke Supabase Auth.
  /// Trigger `handle_new_user` di DB akan otomatis membuat baris
  /// di `public.users` dengan role default 'customer'.
  /// Setelah itu kita update no_wa & role.
  Future<AuthResponse> daftar({
    required String email,
    required String password,
    required String namaLengkap,
    required String noWa,
    required UserRole role,
  }) async {
    // 1. Daftarkan ke Supabase Auth
    //    Sertakan no_wa & role di metadata agar trigger bisa membacanya.
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': namaLengkap,
        'no_wa': noWa,
        'role': _petaRole(role),
      },
    );

    // 2. Coba update public.users (hanya berhasil jika email confirmation OFF
    //    atau user sudah login — jika gagal karena RLS tidak apa-apa,
    //    data sudah tersimpan di metadata dan akan di-sync saat login pertama).
    if (response.user != null) {
      try {
        await client
            .from('users')
            .update({
              'no_wa': noWa,
              'role': _petaRole(role),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', response.user!.id);
      } catch (_) {
        // RLS memblokir update saat email belum dikonfirmasi — normal.
        // Data akan di-sync via syncProfilSetelahLogin() saat pertama login.
      }
    }

    return response;
  }

  // ──────────────────────────────────────────────────────────
  //  SYNC PROFIL setelah login pertama (panggil dari main/AuthGate)
  // ──────────────────────────────────────────────────────────
  /// Setelah user konfirmasi email & login, sync no_wa & role dari metadata.
  Future<void> syncProfilSetelahLogin() async {
    final user = penggunaSaatIni;
    if (user == null) return;

    final meta = user.userMetadata;
    if (meta == null) return;

    final noWa = meta['no_wa'] as String?;
    final role = meta['role'] as String?;
    if (noWa == null && role == null) return;

    try {
      await client.from('users').update({
        if (noWa != null) 'no_wa': noWa,
        if (role != null) 'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (_) {
      // Abaikan — akan dicoba ulang di sesi berikutnya
    }
  }

  // ──────────────────────────────────────────────────────────
  //  MASUK — signIn (Users.masuk)
  // ──────────────────────────────────────────────────────────
  Future<AuthResponse> masuk({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ──────────────────────────────────────────────────────────
  //  KELUAR — signOut
  // ──────────────────────────────────────────────────────────
  Future<void> keluar() async {
    await client.auth.signOut();
  }

  // ──────────────────────────────────────────────────────────
  //  PERBARUI PROFIL (Users.perbaruiProfil)
  // ──────────────────────────────────────────────────────────
  /// Update nama_lengkap, no_wa, dan/atau avatar_url di public.users.
  Future<void> perbaruiProfil({
    String? namaLengkap,
    String? noWa,
    String? avatarUrl,
  }) async {
    if (penggunaSaatIni == null) return;

    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (namaLengkap != null) data['nama_lengkap'] = namaLengkap;
    if (noWa != null) data['no_wa'] = noWa;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    await client
        .from('users')
        .update(data)
        .eq('id', penggunaSaatIni!.id);
  }

  // ──────────────────────────────────────────────────────────
  //  GANTI PASSWORD (Users.gantiPassword)
  // ──────────────────────────────────────────────────────────
  /// Mengganti password user yang sedang login.
  /// [passwordLama] digunakan untuk re-auth sebelum update.
  Future<void> gantiPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    if (penggunaSaatIni == null) throw Exception('Belum masuk.');

    // Re-authenticate dulu dengan password lama
    await masuk(
      email: penggunaSaatIni!.email!,
      password: passwordLama,
    );

    // Update ke password baru
    await client.auth.updateUser(
      UserAttributes(password: passwordBaru),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  AMBIL NOTIFIKASI (Users.ambilNotifikasi)
  // ──────────────────────────────────────────────────────────
  /// Mengambil semua notifikasi milik user yang sedang login,
  /// diurutkan dari yang terbaru.
  Future<List<Map<String, dynamic>>> ambilNotifikasi() async {
    if (penggunaSaatIni == null) return [];

    final data = await client
        .from('notifications')
        .select()
        .eq('user_id', penggunaSaatIni!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ──────────────────────────────────────────────────────────
  //  AMBIL RIWAYAT BOOKING (Users.ambilRiwayatBooking)
  // ──────────────────────────────────────────────────────────
  /// Mengambil semua booking milik customer yang sedang login,
  /// beserta item-item di dalamnya, diurutkan terbaru dulu.
  Future<List<Map<String, dynamic>>> ambilRiwayatBooking() async {
    if (penggunaSaatIni == null) return [];

    final data = await client
        .from('bookings')
        .select('*, booking_items(*)')
        .eq('customer_id', penggunaSaatIni!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ──────────────────────────────────────────────────────────
  //  CURRENT USER — getter
  // ──────────────────────────────────────────────────────────
  User? get penggunaSaatIni => client.auth.currentUser;
  bool get sudahMasuk => penggunaSaatIni != null;

  // ──────────────────────────────────────────────────────────
  //  STREAM AUTH STATE (untuk routing di main.dart)
  // ──────────────────────────────────────────────────────────
  Stream<AuthState> get perubahanStatusAuth =>
      client.auth.onAuthStateChange;

  // ──────────────────────────────────────────────────────────
  //  AMBIL ROLE dari DB
  // ──────────────────────────────────────────────────────────
  /// Ambil role user yang sedang login dari `public.users`.
  Future<String?> ambilRolePengguna() async {
    if (penggunaSaatIni == null) return null;
    final data = await client
        .from('users')
        .select('role')
        .eq('id', penggunaSaatIni!.id)
        .maybeSingle();
    return data?['role'] as String?;
  }

  // ──────────────────────────────────────────────────────────
  //  HELPER: map UserRole enum → string DB
  // ──────────────────────────────────────────────────────────
  static String _petaRole(UserRole role) {
    return switch (role) {
      UserRole.penyewa => 'customer',
      UserRole.pemilik => 'rental_owner',
    };
  }

  // ──────────────────────────────────────────────────────────
  //  INISIALISASI SUPABASE (dipanggil sekali di main)
  // ──────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }
}
