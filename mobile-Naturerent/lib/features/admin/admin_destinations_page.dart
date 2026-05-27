import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/destination_model.dart';
import '../../core/services/admin_service.dart';
import '../../core/theme/app_theme.dart';

class AdminDestinationsPage extends StatefulWidget {
  const AdminDestinationsPage({super.key});

  @override
  State<AdminDestinationsPage> createState() => _AdminDestinationsPageState();
}

class _AdminDestinationsPageState extends State<AdminDestinationsPage> {
  final _adminService = AdminService();
  late Future<List<DestinationModel>> _futureDestinations;

  @override
  void initState() {
    super.initState();
    _futureDestinations = _adminService.ambilDestinasi();
  }

  void _reload() {
    setState(() => _futureDestinations = _adminService.ambilDestinasi());
  }

  Future<void> _openForm({DestinationModel? destination}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationFormPage(destination: destination),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _deleteDestination(DestinationModel destination) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus destinasi?'),
        content: Text('${destination.name} akan dihapus dari halaman user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    try {
      await _adminService.hapusDestinasi(destination.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destinasi berhasil dihapus.'),
          backgroundColor: AppColors.primary,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus destinasi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<DestinationModel>>(
            future: _futureDestinations,
            builder: (context, snapshot) {
              final destinations =
                  snapshot.data ?? const <DestinationModel>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                children: [
                  Text(
                    'Destinasi Wisata',
                    style: AppTextStyles.headlineLarge.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola destinasi yang tampil di halaman user',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (snapshot.hasError)
                    _DestinationState(
                      icon: Icons.error_outline_rounded,
                      title: 'Destinasi gagal dimuat',
                      message: '${snapshot.error}',
                    )
                  else if (destinations.isEmpty)
                    const _DestinationState(
                      icon: Icons.landscape_outlined,
                      title: 'Belum ada destinasi',
                      message:
                          'Tambahkan destinasi pertama agar tampil di halaman user.',
                    )
                  else
                    ...destinations.map(
                      (destination) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DestinationCard(
                          destination: destination,
                          onEdit: () => _openForm(destination: destination),
                          onDelete: () => _deleteDestination(destination),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class DestinationFormPage extends StatefulWidget {
  final DestinationModel? destination;

  const DestinationFormPage({super.key, this.destination});

  @override
  State<DestinationFormPage> createState() => _DestinationFormPageState();
}

class _DestinationFormPageState extends State<DestinationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  XFile? _pickedImage;
  bool _saving = false;

  bool get _isEdit => widget.destination != null;

  @override
  void initState() {
    super.initState();
    final destination = widget.destination;
    if (destination != null) {
      _nameController.text = destination.name;
      _locationController.text = destination.location;
      _descriptionController.text = destination.description;
      _latitudeController.text = destination.latitude?.toString() ?? '';
      _longitudeController.text = destination.longitude?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (image == null) return;
    setState(() => _pickedImage = image);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _pickedImage == null) {
      _showMessage('Gambar destinasi wajib diupload.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      var imageUrl = widget.destination?.imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _adminService.uploadGambarDestinasi(
          bytes: await _pickedImage!.readAsBytes(),
          fileName: _pickedImage!.name,
        );
      }

      final input = DestinationInput(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        latitude: double.tryParse(_latitudeController.text.trim()),
        longitude: double.tryParse(_longitudeController.text.trim()),
      );

      if (_isEdit) {
        await _adminService.editDestinasi(
          id: widget.destination!.id,
          input: input,
        );
      } else {
        await _adminService.tambahDestinasi(input);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menyimpan destinasi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_isEdit ? 'Edit Destinasi' : 'Tambah Destinasi'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _TextField(
                controller: _nameController,
                label: 'Nama Destinasi',
                hint: 'Masukkan nama destinasi',
                validator: _required,
              ),
              _TextField(
                controller: _locationController,
                label: 'Lokasi',
                hint: 'Masukkan lokasi destinasi',
                validator: _required,
              ),
              _ImagePickerBox(
                currentImageUrl: widget.destination?.imageUrl,
                pickedImageName: _pickedImage?.name,
                onPick: _pickImage,
              ),
              _TextField(
                controller: _descriptionController,
                label: 'Deskripsi',
                hint: 'Masukkan deskripsi destinasi',
                maxLines: 5,
                validator: _required,
              ),
              Row(
                children: [
                  Expanded(
                    child: _TextField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      hint: 'Masukkan latitude',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TextField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      hint: 'Masukkan longitude',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Destinasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }
}

class _DestinationCard extends StatelessWidget {
  final DestinationModel destination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DestinationCard({
    required this.destination,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: destination.imageUrl == null || destination.imageUrl!.isEmpty
                ? Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.landscape_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  )
                : Image.network(
                    destination.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        destination.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  destination.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: const Text('Hapus'),
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
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final String? currentImageUrl;
  final String? pickedImageName;
  final VoidCallback onPick;

  const _ImagePickerBox({
    required this.currentImageUrl,
    required this.pickedImageName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gambar',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Upload Gambar Destinasi'),
          ),
          if (pickedImageName != null || currentImageUrl != null) ...[
            const SizedBox(height: 8),
            Text(
              pickedImageName ?? 'Gambar lama tetap digunakan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DestinationState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DestinationState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 52),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
