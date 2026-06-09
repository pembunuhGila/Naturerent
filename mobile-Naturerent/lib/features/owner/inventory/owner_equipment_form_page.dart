import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:naturerent/core/models/equipment.dart';
import 'package:naturerent/core/services/equipment_service.dart';
import 'package:naturerent/core/theme/app_theme.dart';
import 'package:naturerent/core/widgets/nr_toast.dart';

class OwnerEquipmentFormPage extends StatefulWidget {
  final Equipment? equipment;
  final String? rentalId;

  const OwnerEquipmentFormPage({super.key, this.equipment, this.rentalId});

  bool get isEdit => equipment != null;

  @override
  State<OwnerEquipmentFormPage> createState() => _OwnerEquipmentFormPageState();
}

class _OwnerEquipmentFormPageState extends State<OwnerEquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _equipmentService = EquipmentService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _draftSizeCtrl;
  late final TextEditingController _draftStockCtrl;
  final Map<String, int> _sizeStocks = {}; // {size: stock}
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _weightCtrl;
  late int _stock;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;
  Uint8List? _pickedImageBytes;
  String _pickedImageExtension = 'jpg';
  String _pickedImageContentType = 'image/jpeg';
  bool _isSaving = false;

  static const _green = AppColors.ownerPrimaryGreen;
  static const _pageBg = AppColors.ownerPageBackground;

  @override
  void initState() {
    super.initState();
    final equipment = widget.equipment;
    _nameCtrl = TextEditingController(text: equipment?.nama ?? '');
    _priceCtrl = TextEditingController(
      text: equipment == null ? '' : equipment.hargaPerHari.round().toString(),
    );
    _descCtrl = TextEditingController(text: equipment?.deskripsi ?? '');
    _draftSizeCtrl = TextEditingController();
    _draftStockCtrl = TextEditingController();
    // Parse existing sizes from JSON or comma-separated string
    if (equipment?.size != null && equipment!.size!.trim().isNotEmpty) {
      final sizeMap = equipment.sizeStockMap;
      _sizeStocks.addAll(sizeMap);
    }
    _capacityCtrl = TextEditingController(
      text: equipment?.capacity == null ? '' : equipment!.capacity.toString(),
    );
    _weightCtrl = TextEditingController(
      text: equipment?.weightKg == null
          ? ''
          : equipment!.weightKg!.toStringAsFixed(
              equipment.weightKg! % 1 == 0 ? 0 : 1,
            ),
    );
    _selectedCategoryId = equipment?.categoryId;
    _stock = equipment?.stock ?? 8;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _draftSizeCtrl.dispose();
    _draftStockCtrl.dispose();

    _capacityCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _equipmentService.ambilKategori();
      _ensureCurrentCategory(categories);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      final categories = <Map<String, dynamic>>[];
      _ensureCurrentCategory(categories);
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    }
  }

  void _ensureCurrentCategory(List<Map<String, dynamic>> categories) {
    final equipment = widget.equipment;
    if (equipment == null) return;

    final categoryId = equipment.categoryId;
    final categoryName = equipment.namaKategori;
    if (categoryId == null ||
        categoryId.isEmpty ||
        categoryName == null ||
        categoryName.isEmpty) {
      return;
    }

    final exists = categories.any((category) => category['id'] == categoryId);
    if (!exists) {
      categories.add({'id': categoryId, 'nama': categoryName});
    }
  }

  String get _selectedCategoryName {
    for (final category in _categories) {
      if (category['id'] == _selectedCategoryId) {
        return (category['nama'] as String?) ?? '';
      }
    }
    return widget.equipment?.namaKategori ?? '';
  }

  bool get _usesSize {
    // Size selalu tersedia untuk semua kategori alat
    return true;
  }

  bool get _sizeRequired {
    // Size wajib hanya untuk pakaian/alas kaki
    final name = _selectedCategoryName.toLowerCase();
    return name.contains('pakaian') || name.contains('alas kaki');
  }

  // Opsi size standar
  static const _clothingSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  static const _shoeSizes = [
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
  ];

  void _addOrUpdateSizeFromDraft() {
    final size = _draftSizeCtrl.text.trim().toUpperCase();
    final stock = int.tryParse(_draftStockCtrl.text.trim()) ?? 0;
    if (size.isEmpty || stock <= 0) return;

    setState(() {
      _sizeStocks[size] = stock;
      _draftSizeCtrl.clear();
      _draftStockCtrl.clear();
    });
  }

  void _setSizeStock(String size, int stock) {
    final normalizedSize = size.trim().toUpperCase();
    if (normalizedSize.isEmpty) return;
    setState(() {
      if (stock <= 0) {
        _sizeStocks.remove(normalizedSize);
      } else {
        _sizeStocks[normalizedSize] = stock.clamp(1, 999);
      }
    });
  }

  void _removeSize(String size) {
    setState(() => _sizeStocks.remove(size));
  }

  Widget _buildSizeChips() {
    Widget buildChipRow(String label, List<String> sizes) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF496171),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              final selected = _sizeStocks.containsKey(size);
              return GestureDetector(
                onTap: () =>
                    selected ? _removeSize(size) : _setSizeStock(size, 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _green : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? _green : AppColors.ownerBorderColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    size,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected ? Colors.white : const Color(0xFF202321),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildChipRow('Pakaian', _clothingSizes),
        const SizedBox(height: 16),
        buildChipRow('Sepatu / Angka', _shoeSizes),
      ],
    );
  }

  Widget _buildSizeStockList() {
    final entries = _sizeStocks.entries.toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ownerBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stok per Ukuran',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF496171),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SizeStockRow(
                size: entry.key,
                stock: entry.value,
                onChanged: (value) => _setSizeStock(entry.key, value),
                onRemove: () => _removeSize(entry.key),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total stok: ${_sizeStocks.values.fold(0, (a, b) => a + b)} unit',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF7B8794),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSizeInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ownerBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _draftSizeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: _compactDecoration('XL'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: TextField(
              controller: _draftStockCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _compactDecoration('10 unit'),
              onSubmitted: (_) => _addOrUpdateSizeFromDraft(),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            height: 42,
            child: ElevatedButton(
              onPressed: _addOrUpdateSizeFromDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;
      if (!mounted) return;

      if (kIsWeb) {
        final originalBytes = await picked.readAsBytes();
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => _SimpleWebCropDialog(imageBytes: originalBytes),
        );
        if (confirm != true) return;
        final croppedBytes = await _centerCropToPng(originalBytes);
        if (!mounted) return;
        setState(() {
          _pickedImageBytes = croppedBytes;
          _pickedImageExtension = 'png';
          _pickedImageContentType = 'image/png';
        });
        return;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
        compressQuality: 80,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Pangkas Foto Produk',
            toolbarColor: AppColors.ownerPrimaryGreen,
            toolbarWidgetColor: Colors.white,
            statusBarLight: false,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppColors.ownerPrimaryGreen,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Pangkas Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped == null || !mounted) return;
      final bytes = await cropped.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageExtension = 'jpg';
        _pickedImageContentType = 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      NrToast.show(
        context,
        'Gagal memilih/memangkas foto: ${e.toString()}',
        type: NrToastType.error,
      );
    }
  }

  Future<Uint8List> _centerCropToPng(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    const targetAspect = 4 / 5;
    final imageAspect = image.width / image.height;

    late final Rect source;
    if (imageAspect > targetAspect) {
      final cropWidth = image.height * targetAspect;
      source = Rect.fromLTWH(
        (image.width - cropWidth) / 2,
        0,
        cropWidth,
        image.height.toDouble(),
      );
    } else {
      final cropHeight = image.width / targetAspect;
      source = Rect.fromLTWH(
        0,
        (image.height - cropHeight) / 2,
        image.width.toDouble(),
        cropHeight,
      );
    }

    const outputWidth = 1080;
    const outputHeight = 1350;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      Paint(),
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(outputWidth, outputHeight);
    final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    cropped.dispose();

    if (byteData == null) {
      throw Exception('Gagal memproses foto.');
    }
    return byteData.buffer.asUint8List();
  }

  void _changeStock(int delta) {
    setState(() => _stock = (_stock + delta).clamp(0, 999));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sizeRequired && _sizeStocks.isEmpty) {
      setState(() {}); // trigger rebuild untuk show error
      return;
    }

    final harga = double.parse(_priceCtrl.text);
    final deskripsi = _descCtrl.text.trim();
    // Simpan size sebagai JSON map {"S":5,"M":10} atau string kosong.
    final size = _sizeStocks.isEmpty ? '' : jsonEncode(_sizeStocks);
    // Total stock = jumlah dari semua per-size stock
    final totalStock = _sizeStocks.isNotEmpty
        ? _sizeStocks.values.fold(0, (a, b) => a + b)
        : _stock;
    final capacityText = _capacityCtrl.text.trim();
    final weightText = _weightCtrl.text.trim().replaceAll(',', '.');
    final capacity = capacityText.isEmpty ? null : int.parse(capacityText);
    final weightKg = weightText.isEmpty ? null : double.parse(weightText);

    setState(() => _isSaving = true);
    try {
      final categoryId = await _equipmentService.pastikanCategoryId(
        _selectedCategoryId,
      );

      if (widget.isEdit) {
        String? imageUrl;
        if (_pickedImageBytes != null) {
          imageUrl = await _equipmentService.uploadFotoAlat(
            bytes: _pickedImageBytes!,
            rentalId: widget.equipment!.rentalId,
            equipmentId: widget.equipment!.id,
            extension: _pickedImageExtension,
            contentType: _pickedImageContentType,
          );
        }

        await _equipmentService.perbaruiAlat(
          equipmentId: widget.equipment!.id,
          nama: _nameCtrl.text.trim(),
          categoryId: categoryId,
          deskripsi: deskripsi.isEmpty ? null : deskripsi,
          size: size.isEmpty ? null : size,
          capacity: capacity,
          weightKg: weightKg,
          hargaPerHari: harga,
          stock: totalStock,
          imageUrl: imageUrl,
        );
      } else {
        final rentalId = widget.rentalId;
        if (rentalId == null) {
          throw Exception('Profil rental belum ditemukan.');
        }

        String? imageUrl;
        if (_pickedImageBytes != null) {
          imageUrl = await _equipmentService.uploadFotoAlat(
            bytes: _pickedImageBytes!,
            rentalId: rentalId,
            extension: _pickedImageExtension,
            contentType: _pickedImageContentType,
          );
        }

        await _equipmentService.tambahAlat(
          rentalId: rentalId,
          nama: _nameCtrl.text.trim(),
          categoryId: categoryId,
          deskripsi: deskripsi.isEmpty ? null : deskripsi,
          size: size.isEmpty ? null : size,
          capacity: capacity,
          weightKg: weightKg,
          hargaPerHari: harga,
          stock: totalStock,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) return;
      NrToast.show(
        context,
        widget.isEdit
            ? 'Peralatan berhasil diperbarui.'
            : 'Alat baru berhasil ditambahkan.',
        type: NrToastType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      NrToast.show(
        context,
        'Gagal menyimpan peralatan: ${e.toString()}',
        type: NrToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _deleteEquipment() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Peralatan'),
        content: Text(
          'Hapus ${widget.equipment?.nama ?? 'peralatan ini'} dari inventaris?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isSaving = true);
              try {
                await _equipmentService.hapusAlat(widget.equipment!.id);
                if (!mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                if (!mounted) return;
                setState(() => _isSaving = false);
                NrToast.show(
                  context,
                  'Gagal menghapus peralatan: ${e.toString()}',
                  type: NrToastType.error,
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
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
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF222523)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          widget.isEdit ? 'Edit Peralatan' : 'Tambah Alat Baru',
          style: AppTextStyles.headlineMedium.copyWith(
            color: const Color(0xFF1F2420),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Color(0xFF1F2420)),
            onPressed: _isSaving ? null : () => _submit(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            children: [
              _ImagePickerCard(
                isEdit: widget.isEdit,
                imageUrl: widget.equipment?.gambarprimaryUrl,
                pickedImageBytes: _pickedImageBytes,
                onTap: _pickImage,
              ),
              const SizedBox(height: 30),
              _SectionLabel('Kategori Alat'),
              const SizedBox(height: 10),
              _CategoryBox(
                value: _selectedCategoryId,
                categories: _categories,
                loading: _loadingCategories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    if (!_usesSize) _sizeStocks.clear();
                  });
                },
              ),
              if (_usesSize) ...[
                const SizedBox(height: 22),
                _SectionLabel('Pilih Ukuran'),
                const SizedBox(height: 6),
                Text(
                  'Pilih preset atau tambah ukuran sendiri, lalu isi jumlah unit.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF7B8794),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCustomSizeInput(),
                const SizedBox(height: 14),
                _buildSizeChips(),
                if (_sizeStocks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSizeStockList(),
                ],
                if (_sizeRequired && _sizeStocks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Ukuran wajib dipilih untuk kategori ini',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFFD32F2F),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 22),
              _SectionLabel('Nama Produk'),
              const SizedBox(height: 10),
              _TextBox(
                controller: _nameCtrl,
                hint: 'Contoh: Tenda Arpenaz',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama produk wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Harga / Hari'),
                        const SizedBox(height: 10),
                        _PriceBox(controller: _priceCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Stok Unit'),
                        const SizedBox(height: 10),
                        _StockBox(
                          value: _stock,
                          onMinus: () => _changeStock(-1),
                          onPlus: () => _changeStock(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionLabel('Deskripsi Produk'),
              const SizedBox(height: 10),
              _TextBox(
                controller: _descCtrl,
                hint: 'Jelaskan kondisi dan fitur alat Anda di sini...',
                minLines: 4,
                maxLines: 5,
              ),
              const SizedBox(height: 26),
              _SpecPanel(
                capacityController: _capacityCtrl,
                weightController: _weightCtrl,
              ),
              const SizedBox(height: 38),
              if (widget.isEdit)
                _DeleteButton(onPressed: _isSaving ? null : _deleteEquipment)
              else
                _SaveButton(
                  isSaving: _isSaving,
                  onPressed: _isSaving ? null : () => _submit(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final bool isEdit;
  final String? imageUrl;
  final Uint8List? pickedImageBytes;
  final VoidCallback onTap;

  const _ImagePickerCard({
    required this.isEdit,
    required this.imageUrl,
    required this.pickedImageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        pickedImageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ownerCardBackground,
            borderRadius: BorderRadius.circular(8),
            border: hasImage
                ? null
                : Border.all(
                    color: AppColors.ownerBorderColor,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage ? _buildImage() : _buildEmptyState(context),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (pickedImageBytes != null)
          Image.memory(pickedImageBytes!, fit: BoxFit.cover)
        else
          Image.network(imageUrl!, fit: BoxFit.cover),
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera_outlined, size: 16),
                const SizedBox(width: 8),
                Text(
                  'UBAH FOTO',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF344B3B),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_outlined,
          color: Color(0xFF496171),
          size: 42,
        ),
        const SizedBox(height: 12),
        Text(
          'UNGGAH FOTO PRODUK',
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF496171),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Format JPG, PNG (Maks. 5MB)',
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF6E776F),
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SimpleWebCropDialog extends StatelessWidget {
  final Uint8List imageBytes;

  const _SimpleWebCropDialog({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pangkas Foto Produk',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: const Color(0xFF202321),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageBytes, fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Text(
                'Foto akan dipangkas otomatis ke rasio 4:5 dari area tengah.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF687369),
                  height: 1.35,
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _OwnerEquipmentFormPageState._green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Gunakan Foto'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        color: const Color(0xFF496171),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _CategoryBox extends StatelessWidget {
  final String? value;
  final List<Map<String, dynamic>> categories;
  final bool loading;
  final ValueChanged<String?> onChanged;

  const _CategoryBox({
    required this.value,
    required this.categories,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = categories.any((category) => category['id'] == value);
    return DropdownButtonFormField<String>(
      initialValue: hasValue ? value : null,
      isExpanded: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Kategori wajib dipilih';
        return null;
      },
      onChanged: loading ? null : onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF748076),
      ),
      decoration: _fieldDecoration(
        loading ? 'Memuat kategori...' : 'Pilih kategori alat',
      ),
      dropdownColor: Colors.white,
      items: categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category['id'] as String,
              child: Text(
                category['nama'] as String? ?? 'Kategori',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TextBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextBox({
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(
        color: const Color(0xFF202321),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: _fieldDecoration(hint),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final TextEditingController controller;

  const _PriceBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        if (parsed == null || parsed <= 0) return 'Harga wajib diisi';
        return null;
      },
      style: AppTextStyles.bodyMedium.copyWith(
        color: const Color(0xFF202321),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      decoration: _fieldDecoration(
        '150000',
        prefix: Text(
          'Rp',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF496171),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StockBox extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StockBox({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _StockButton(
            icon: Icons.remove_rounded,
            color: const Color(0xFFF0F1ED),
            iconColor: const Color(0xFF202321),
            onTap: onMinus,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF202321),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _StockButton(
            icon: Icons.add_rounded,
            color: _OwnerEquipmentFormPageState._green,
            iconColor: Colors.white,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _SizeStockRow extends StatelessWidget {
  final String size;
  final int stock;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  const _SizeStockRow({
    required this.size,
    required this.stock,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _OwnerEquipmentFormPageState._green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            size,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: _OwnerEquipmentFormPageState._green,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            key: ValueKey('size-stock-$size'),
            initialValue: stock.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.trim().isEmpty) return;
              onChanged(int.tryParse(value) ?? 0);
            },
            decoration: _compactDecoration('0 unit'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF202321),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _StockButton(
          icon: Icons.close_rounded,
          color: const Color(0xFFF0F1ED),
          iconColor: const Color(0xFF202321),
          onTap: onRemove,
        ),
      ],
    );
  }
}

class _StockButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _StockButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _SpecPanel extends StatelessWidget {
  final TextEditingController capacityController;
  final TextEditingController weightController;

  const _SpecPanel({
    required this.capacityController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.ownerBorderColor,
          width: AppColors.ownerBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spesifikasi Tambahan',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _OwnerEquipmentFormPageState._green,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SpecInput(
                  icon: Icons.groups_2_outlined,
                  label: 'Kapasitas',
                  controller: capacityController,
                  suffix: 'Orang',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SpecInput(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Berat',
                  controller: weightController,
                  suffix: 'Kg',
                  decimal: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecInput extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String suffix;
  final bool decimal;

  const _SpecInput({
    required this.icon,
    required this.label,
    required this.controller,
    required this.suffix,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF344B3B)),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF344B3B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
            ),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.ownerCardBackground,
            hintText: decimal ? '0.0' : '0',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF748076),
              fontSize: 15,
            ),
            suffixText: suffix,
            suffixStyle: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF7A817A),
              fontSize: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.ownerBorderColor,
                width: AppColors.ownerBorderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.ownerBorderColor,
                width: AppColors.ownerBorderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.ownerPrimaryGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSaving;

  const _SaveButton({required this.onPressed, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_outlined, color: Colors.white),
        label: Text(
          isSaving ? 'Menyimpan...' : 'Simpan Alat',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ownerPrimaryGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_outline_rounded, size: 17),
        label: Text(
          'Hapus Peralatan',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint, {Widget? prefix}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium.copyWith(
      color: const Color(0xFF9A9F99),
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: prefix == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Center(widthFactor: 1, child: prefix),
          ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}

InputDecoration _compactDecoration(String hint) {
  return InputDecoration(
    filled: true,
    fillColor: AppColors.ownerCardBackground,
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium.copyWith(
      color: const Color(0xFF9A9F99),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.ownerBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.ownerBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.ownerPrimaryGreen),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
