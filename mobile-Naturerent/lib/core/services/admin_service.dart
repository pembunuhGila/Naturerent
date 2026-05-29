import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_order.dart';
import '../models/destination_model.dart';
import 'auth_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  static SupabaseClient get _client => AuthService.client;
  static const String destinationBucket = 'destinasi_wisata';

  Future<List<AdminOrder>> ambilPesananMasuk() async {
    final data = await _client
        .from('bookings')
        .select('''
          id,
          booking_code,
          customer_id,
          rental_id,
          tgl_mulai,
          tgl_selesai,
          total_bayar,
          status,
          payment_status,
          payment_proof_url,
          created_at,
          users(nama_lengkap, email),
          rental_profiles(nama_rental),
          booking_items(nama_equipment, nama_rental, jumlah, total_harga)
        ''')
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => AdminOrder.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> accPesanan(String bookingId) async {
    await _client
        .from('bookings')
        .update({
          'status': 'confirmed',
          'payment_status': 'dp_confirmed',
          'confirmed_by_admin_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .eq('status', 'pending');
  }

  Future<void> batalkanPesanan(String bookingId) async {
    await _client
        .from('bookings')
        .update({
          'status': 'cancelled',
          'payment_status': 'failed',
          'admin_notes': 'Dibatalkan oleh admin',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .eq('status', 'pending');
  }

  Future<List<DestinationModel>> ambilDestinasi() async {
    final data = await _client
        .from('wisata_locations')
        .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at')
        .neq('kategori', 'QRIS')
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => DestinationModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<DestinationModel> tambahDestinasi(DestinationInput input) async {
    final data = await _client
        .from('wisata_locations')
        .insert(input.toWisataPayload())
        .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at')
        .single();

    return DestinationModel.fromMap(data);
  }

  Future<DestinationModel> editDestinasi({
    required String id,
    required DestinationInput input,
  }) async {
    final data = await _client
        .from('wisata_locations')
        .update(input.toWisataPayload())
        .eq('id', id)
        .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at')
        .single();

    return DestinationModel.fromMap(data);
  }

  Future<void> hapusDestinasi(String id) async {
    await _client.from('wisata_locations').delete().eq('id', id);
  }

  Future<String> uploadGambarDestinasi({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty ? 'jpg' : extension;
    final path =
        'destinations/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    await _client.storage
        .from(destinationBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from(destinationBucket).getPublicUrl(path);
  }
}
