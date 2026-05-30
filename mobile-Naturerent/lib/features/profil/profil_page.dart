import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/rental_service.dart';
import '../../core/models/rental_profile.dart';
import '../../core/widgets/nr_toast.dart';
import '../auth/login_page.dart';
import '../auth/onboarding_page.dart';
import '../home/aktivitas_page.dart';
import '../owner/owner_activity_page.dart';
import '../owner/widgets/owner_header_widget.dart';
import 'edit_profil_page.dart';

class ProfilPage extends StatefulWidget {
  final bool forceMitra;
  final ValueChanged<int>? onOwnerNavTap;
  final int refreshToken;

  const ProfilPage({
    super.key,
    this.forceMitra = false,
    this.onOwnerNavTap,
    this.refreshToken = 0,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _client = AuthService.client;
  final _rentalService = RentalService();
  bool _isLoggingOut = false;
  bool _openingActivity = false;
  String? _avatarUrl;
  String? _namaDB; // dari public.users table
  String? _roleDB;
  RentalProfile? _rentalProfile;

  User? get _user => _client.auth.currentUser;

  String get _namaLengkap {
    final meta = _user?.userMetadata;
    if (_isMitra) {
      final fromMeta = meta?['full_name'] as String?;
      if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    }
    // Prioritaskan data dari DB agar langsung reflect setelah edit
    if (_namaDB != null && _namaDB!.isNotEmpty) return _namaDB!;
    final fromMeta = meta?['full_name'] as String?;
    if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    return _user?.email?.split('@').first ?? 'Pengguna';
  }

  String get _email => _user?.email ?? '-';
  String? get _roleAktif {
    final roleMeta = _user?.userMetadata?['role'];
    return _roleDB ?? (roleMeta is String ? roleMeta : null);
  }

  bool get _isMitra => widget.forceMitra || _roleAktif == 'rental_owner';
  String get _namaToko =>
      _rentalProfile?.namaRental ??
      (_user?.userMetadata?['store_name'] as String?) ??
      'Rimba Basecamp';
  String? get _fotoProfilToko => _rentalProfile?.fotoProfil ?? _avatarUrl;
  String get _jamOperasional =>
      _rentalProfile?.operationalHours ?? 'Jam operasional belum diatur';

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  @override
  void didUpdateWidget(covariant ProfilPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _muatProfil();
    }
  }

  Future<void> _muatProfil() async {
    final uid = _user?.id;
    if (uid == null) return;

    try {
      final data = await _client
          .from('users')
          .select('avatar_url, nama_lengkap, role')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _avatarUrl = data?['avatar_url'] as String?;
        // Simpan nama dari DB untuk refresh langsung setelah edit
        final dbNama = data?['nama_lengkap'] as String?;
        if (dbNama != null && dbNama.isNotEmpty) _namaDB = dbNama;
        _roleDB = data?['role'] as String?;
      });
    } catch (_) {
      // Profil mitra tetap harus memuat data toko meski tabel users dibatasi RLS.
    }

    if (_isMitra) {
      try {
        final rental = await _rentalService.ambilRentalSaya();
        if (!mounted) return;
        setState(() => _rentalProfile = rental);
      } catch (_) {
        // Biarkan fallback UI tampil jika data rental belum bisa dimuat.
      }
    }
  }

  String get _inisial {
    final words = _namaLengkap.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return _namaLengkap.isNotEmpty ? _namaLengkap[0].toUpperCase() : 'N';
  }

  Future<void> _bukaEditProfil() async {
    final updated = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilPage(
          namaAwal: _namaLengkap,
          email: _email,
          avatarUrlAwal: _avatarUrl,
          isMitra: _isMitra,
          namaTokoAwal: _namaToko,
          rentalProfile: _rentalProfile,
        ),
      ),
    );
    if (updated == true && mounted) {
      await _muatProfil(); // reload nama & avatar dari DB
      setState(() {}); // trigger rebuild
      _snack('Profil toko berhasil diperbarui.');
    } else if (updated is RentalProfile && mounted) {
      setState(() => _rentalProfile = updated);
      await _muatProfil();
      if (!mounted) return;
      setState(() {});
      _snack('Profil toko berhasil diperbarui.');
    }
  }

  /// Navigasi ke halaman aktivitas yang sesuai dengan role user.
  /// Owner → OwnerActivityPage, Customer → AktivitasPage
  Future<void> _bukaAktivitas() async {
    await _bukaHalamanAktivitas(initialTab: 0);
  }

  Future<void> _bukaRiwayatTransaksi() async {
    await _bukaHalamanAktivitas(initialTab: 2);
  }

  Future<void> _bukaHalamanAktivitas({required int initialTab}) async {
    if (_openingActivity) return;

    setState(() => _openingActivity = true);

    final roleMetadata = _user?.userMetadata?['role'];
    String? role = _roleDB ?? (roleMetadata is String ? roleMetadata : null);
    try {
      final roleDariDb = await AuthService().ambilRolePengguna().timeout(
        const Duration(seconds: 5),
      );
      if (roleDariDb != null && roleDariDb.isNotEmpty) {
        role = roleDariDb;
        _roleDB = roleDariDb;
      }
    } catch (_) {
      // Tetap lanjut pakai role dari profil/metadata.
    } finally {
      if (mounted) setState(() => _openingActivity = false);
    }

    if (!mounted) return;

    if (role == 'rental_owner') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OwnerActivityPage()),
      );
    } else {
      // Default: halaman aktivitas customer
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AktivitasPage(initialTab: initialTab, showBackButton: true),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar Akun',
          style: AppTextStyles.headlineLarge.copyWith(
            color: const Color(0xFF202321),
          ),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF496171),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF496171),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Keluar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      final roleTujuan = _isMitra ? UserRole.pemilik : UserRole.penyewa;
      await AuthService().keluar();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage(role: roleTujuan)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      NrToast.show(
        context,
        'Gagal logout: ${e.toString()}',
        type: NrToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    if (_isMitra) return _buildMitraProfile();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 132,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Bar
              _buildAppBar(),
              const SizedBox(height: 28),

              // ── Avatar + Info
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildEditProfileButton(),
              const SizedBox(height: 28),

              // ── Seksi AKUN
              _buildSectionLabel('AKUN'),
              const SizedBox(height: 8),
              _buildMenuCard(
                items: [
                  _MenuItem(
                    icon: Icons.history_rounded,
                    label: 'Aktivitas Saya',
                    onTap: _bukaAktivitas,
                    loading: _openingActivity,
                  ),
                  _MenuItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Daftar Transaksi',
                    onTap: _bukaRiwayatTransaksi,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Seksi INFO LAINNYA
              _buildSectionLabel('INFO LAINNYA'),
              const SizedBox(height: 8),
              _buildMenuCard(
                items: [
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Pusat Bantuan',
                    onTap: () => _snackComingSoon('Pusat Bantuan'),
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Kebijakan Privasi',
                    onTap: () => _snackComingSoon('Kebijakan Privasi'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Logout
              _buildLogoutButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  WIDGETS
  // ──────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Center(
      child: Text(
        'Profil Saya',
        style: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _bukaEditProfil,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                        ? Image.network(
                            _avatarUrl!,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.primary,
                            child: Center(
                              child: Text(
                                _inisial,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _bukaEditProfil,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _namaLengkap,
            style: AppTextStyles.headlineLarge.copyWith(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _email,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _bukaEditProfil,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(
          'Edit Profil',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        fontSize: 11,
      ),
    );
  }

  Widget _buildMenuCard({required List<_MenuItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: i == items.length - 1
                      ? const Radius.circular(16)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.primaryDark,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.loading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF18743A),
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 66, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5DE)),
      ),
      child: InkWell(
        onTap: _isLoggingOut ? null : _logout,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _isLoggingOut
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _snackComingSoon(String fitur) {
    _snack('$fitur — Segera hadir!');
  }

  void _snack(String pesan) {
    NrToast.show(
      context,
      pesan,
      type: NrToastType.info,
      duration: const Duration(seconds: 2),
    );
  }

  void _bukaOwnerTab(int index, String fallbackLabel) {
    final onOwnerNavTap = widget.onOwnerNavTap;
    if (onOwnerNavTap != null) {
      onOwnerNavTap(index);
      return;
    }
    _snackComingSoon(fallbackLabel);
  }

  Widget _buildMitraProfile() {
    return Scaffold(
      backgroundColor: AppColors.ownerPageBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 132),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMitraAppBar(),
              const SizedBox(height: 26),
              _buildMitraHero(),
              const SizedBox(height: 26),
              _buildMitraStats(),
              const SizedBox(height: 28),
              _buildMitraInfoList(),
              const SizedBox(height: 34),
              Text(
                'Lainnya',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: const Color(0xFF202321),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MitraMenuTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'Stok Alat',
                      onTap: () => _bukaOwnerTab(2, 'Stok Alat'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MitraMenuTile(
                      icon: Icons.payments_outlined,
                      label: 'Keuangan',
                      onTap: () => _bukaOwnerTab(0, 'Keuangan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 54),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMitraAppBar() {
    return const OwnerHeaderWidget(padding: EdgeInsets.fromLTRB(8, 10, 0, 0));
  }

  Widget _buildMitraHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 176,
                    child:
                        _rentalProfile?.fotoBanner != null &&
                            _rentalProfile!.fotoBanner!.isNotEmpty
                        ? Image.network(
                            _rentalProfile!.fotoBanner!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _buildMitraCoverPlaceholder(),
                          )
                        : _buildMitraCoverPlaceholder(),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 132,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'FOTO SAMPUL',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 136,
                child: GestureDetector(
                  onTap: _bukaEditProfil,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEFEA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child:
                              _fotoProfilToko != null &&
                                  _fotoProfilToko!.isNotEmpty
                              ? Image.network(
                                  _fotoProfilToko!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _buildInitialAvatar(),
                                )
                              : _buildInitialAvatar(),
                        ),
                      ),
                      Positioned(
                        right: -8,
                        bottom: -3,
                        child: _TinyEditButton(onTap: _bukaEditProfil),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 108,
                right: 8,
                top: 188,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _namaToko,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: const Color(0xFF202321),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PARTNER TERVERIFIKASI',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF9BA19A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.ownerBorderColor, height: 1),
      ],
    );
  }

  Widget _buildMitraCoverPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/loading_background.png', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialAvatar() {
    return Container(
      color: AppColors.ownerPrimaryGreen,
      alignment: Alignment.center,
      child: Text(
        _inisial,
        style: AppTextStyles.headlineLarge.copyWith(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMitraStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.ownerBorderColor,
            width: AppColors.ownerBorderWidth,
          ),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _MitraStatItem(label: 'TOTAL SEWA', value: '124'),
          ),
          _VerticalSoftDivider(),
          Expanded(
            child: _MitraStatItem(
              label: 'STATUS',
              value: 'AKTIF',
              valueColor: AppColors.ownerPrimaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMitraInfoList() {
    return Column(
      children: [
        _MitraInfoItem(
          icon: Icons.person_outline_rounded,
          label: 'PEMILIK TOKO',
          value: _namaLengkap,
        ),
        const SizedBox(height: 26),
        _MitraInfoItem(
          icon: Icons.mail_outline_rounded,
          label: 'EMAIL',
          value: _email,
        ),
        const SizedBox(height: 26),
        _MitraInfoItem(
          icon: Icons.access_time_rounded,
          label: 'JAM OPERASIONAL',
          value: _jamOperasional,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────
class _MitraStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MitraStatItem({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF202321),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF7D847D),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _VerticalSoftDivider extends StatelessWidget {
  const _VerticalSoftDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.ownerBorderColor);
  }
}

class _MitraInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MitraInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.ownerSoftGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.ownerPrimaryGreen, size: 21),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF7D847D),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFF202321),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MitraMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MitraMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 94,
        decoration: BoxDecoration(
          color: AppColors.ownerCardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.ownerBorderColor,
            width: AppColors.ownerBorderWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF626A60), size: 24),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF626A60),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyEditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TinyEditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 23,
        height: 23,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.ownerBorderColor,
            width: AppColors.ownerBorderWidth,
          ),
        ),
        child: const Icon(
          Icons.edit_rounded,
          color: AppColors.ownerPrimaryGreen,
          size: 13,
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });
}
