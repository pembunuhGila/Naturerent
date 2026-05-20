import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'owner_destination_data.dart';

class OwnerEditRentalPage extends StatefulWidget {
  const OwnerEditRentalPage({super.key});

  @override
  State<OwnerEditRentalPage> createState() => _OwnerEditRentalPageState();
}

class _OwnerEditRentalPageState extends State<OwnerEditRentalPage> {
  final _namaRentalController = TextEditingController(text: 'Rimba Basecamp');
  final _alamatController = TextEditingController(
    text: 'Kaki Gunung Semeru, Desa Ranupani, Senduro, Lumajang, Jawa Timur',
  );
  final Set<String> _nearbyTitles = {'Ranu Kumbolo', 'Gunung Semeru'};
  final Set<String> _selected = {'Ranu Kumbolo', 'Gunung Semeru'};

  @override
  void dispose() {
    _namaRentalController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Perubahan detail rental tersimpan.'),
        backgroundColor: const Color(0xFF123E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
    Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF8F8F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(38, 26, 20, 120),
                children: [
                  Text(
                    'Ubah Detail Base\nCamp',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: const Color(0xFF202321),
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Perbarui informasi rental Anda agar\ntetap relevan bagi para petualang.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF757D73),
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _IdentityCard(controller: _namaRentalController),
                  const SizedBox(height: 22),
                  _LocationCard(controller: _alamatController),
                  const SizedBox(height: 54),
                  Text(
                    'Dekat dari Lokasimu',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: const Color(0xFF263229),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...ownerCandidateDestinations.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _DestinationCard(
                        item: item,
                        selected: _selected.contains(item.title),
                        disabled: _nearbyTitles.contains(item.title),
                        onTap: () {
                          if (_nearbyTitles.contains(item.title)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${item.title} sudah ada di destinasi terdekat.',
                                ),
                                backgroundColor: const Color(0xFF123E1E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            if (_selected.contains(item.title)) {
                              _selected.remove(item.title);
                            } else {
                              _selected.add(item.title);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFF8F8F5),
        padding: EdgeInsets.fromLTRB(
          38,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF123E1E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'SIMPAN PERUBAHAN',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF263229),
              size: 24,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Ubah Detail Rental',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF263229),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final TextEditingController controller;
  const _IdentityCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _EditSectionCard(
      title: 'Identitas Rental',
      subtitle: 'Nama ini akan muncul pada hasil\npencarian dan halaman utama.',
      child: _LabeledInput(
        label: 'NAMA TEMPAT RENTAL',
        controller: controller,
        maxLines: 1,
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final TextEditingController controller;
  const _LocationCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _EditSectionCard(
      title: 'Lokasi & Alamat',
      subtitle: 'Pastikan titik GPS akurat agar penyewa\ntidak tersesat.',
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 224,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/loading_background.png',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF123E1E),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Titik Lokasi',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Ubah di Peta',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF123E1E),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _LabeledInput(
            label: 'ALAMAT LENGKAP',
            controller: controller,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _EditSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _EditSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEAEDE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: const Color(0xFF303B32),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF7F877E),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 34),
          child,
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF798076),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF384036),
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F0ED),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF123E1E)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final DestinationInfo item;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.item,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 178,
            decoration: BoxDecoration(
              color: disabled ? item.color.withValues(alpha: 0.74) : item.color,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Icon(item.icon, color: Colors.white, size: 72),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFF337F52),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '4.9',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF8F968E),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: const Color(0xFF202321),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFB4BBB2),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.detailDistance,
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFB4BBB2),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: disabled
                        ? const Color(0xFFEAEAE7)
                        : const Color(0xFF337F52),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    disabled
                        ? Icons.check_rounded
                        : selected
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    color: disabled ? const Color(0xFFB7BDB5) : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
