import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../models/rental_profile.dart';

/// Satu item di keranjang
class CartItem {
  final Equipment equipment;
  final RentalProfile rental;
  final String? selectedSize;
  int qty;

  CartItem({required this.equipment, required this.rental, this.selectedSize, this.qty = 1});

  double get subtotal => equipment.hargaPerHari * qty;
}

class CartRentalGroup {
  final RentalProfile rental;
  final List<CartItem> items;

  const CartRentalGroup({required this.rental, required this.items});

  double get subtotalPerHari =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);
}

/// Singleton sederhana untuk keranjang pesanan.
/// Tidak butuh Provider/Riverpod — cukup import CartService() di mana saja.
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];
  final ValueNotifier<int> count = ValueNotifier(0);

  List<CartItem> get items => List.unmodifiable(_items);

  List<CartRentalGroup> get groupedByRental {
    final map = <String, List<CartItem>>{};
    final rentals = <String, RentalProfile>{};

    for (final item in _items) {
      final key = item.rental.id;
      rentals[key] = item.rental;
      map.putIfAbsent(key, () => []).add(item);
    }

    final groups = map.entries
        .map(
          (entry) => CartRentalGroup(
            rental: rentals[entry.key]!,
            items: List.unmodifiable(entry.value),
          ),
        )
        .toList();

    groups.sort((a, b) => a.rental.namaRental.compareTo(b.rental.namaRental));
    return List.unmodifiable(groups);
  }

  /// Tambah alat ke keranjang (qty +1 jika sudah ada)
  void tambah(Equipment equipment, RentalProfile rental, {String? selectedSize}) {
    final idx = _items.indexWhere(
      (i) => i.equipment.id == equipment.id && i.rental.id == rental.id && i.selectedSize == selectedSize,
    );
    if (idx >= 0) {
      _items[idx].qty++;
    } else {
      _items.add(CartItem(equipment: equipment, rental: rental, selectedSize: selectedSize));
    }
    _updateCount();
  }

  /// Hapus item berdasarkan index
  void hapus(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _updateCount();
    }
  }

  void hapusItem(CartItem item) {
    _items.remove(item);
    _updateCount();
  }

  /// Kosongkan keranjang
  void bersihkan() {
    _items.clear();
    _updateCount();
  }

  /// Total harga per hari (belum dikali durasi)
  double get totalPerHari =>
      _items.fold(0.0, (sum, i) => sum + i.equipment.hargaPerHari * i.qty);

  /// Total harga dikali durasi
  double totalBayar(int durasi) => totalPerHari * durasi;

  void _updateCount() {
    count.value = _items.fold(0, (sum, i) => sum + i.qty);
  }
}
