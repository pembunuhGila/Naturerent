import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../models/rental_profile.dart';

/// Satu item di keranjang
class CartItem {
  final Equipment equipment;
  final RentalProfile rental;
  int qty;

  CartItem({required this.equipment, required this.rental, this.qty = 1});

  double get subtotal => equipment.hargaPerHari * qty;
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

  /// Tambah alat ke keranjang (qty +1 jika sudah ada)
  void tambah(Equipment equipment, RentalProfile rental) {
    final idx = _items.indexWhere((i) => i.equipment.id == equipment.id);
    if (idx >= 0) {
      _items[idx].qty++;
    } else {
      _items.add(CartItem(equipment: equipment, rental: rental));
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

  /// Kosongkan keranjang
  void bersihkan() {
    _items.clear();
    _updateCount();
  }

  /// Total harga per malam (belum dikali durasi)
  double get totalPerMalam =>
      _items.fold(0.0, (sum, i) => sum + i.equipment.hargaPerHari * i.qty);

  /// Total harga dikali durasi
  double totalBayar(int durasi) => totalPerMalam * durasi;

  void _updateCount() {
    count.value = _items.fold(0, (sum, i) => sum + i.qty);
  }
}
