import 'package:flutter/foundation.dart';
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
          cancellation_reason,
          cancellation_note,
          cancelled_by,
          cancelled_at,
          cancellation_status,
          refund_uploaded_at,
          refund_status,
          created_at,
          users(
            nama_lengkap,
            email,
            phone,
            phone_number,
            no_wa,
            bank_name,
            account_number,
            bank_account
          ),
          rental_profiles(nama_rental),
          booking_items(nama_equipment, nama_rental, jumlah, total_harga)
        ''')
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => AdminOrder.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> accPesanan(String bookingId) async {
    final updated = await _client
        .from('bookings')
        .update({
          'status': 'confirmed',
          'payment_status': 'dp_confirmed',
          'confirmed_by_admin_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .eq('status', 'pending')
        .select('customer_id, booking_code')
        .maybeSingle();

    debugPrint('accPesanan updated=$updated');
    if (updated == null) return;

    final customerId = updated['customer_id'] as String?;
    if (customerId == null || customerId.isEmpty) {
      debugPrint(
        'Admin notification skipped for booking=$bookingId because customerId is empty.',
      );
      return;
    }

    try {
      await _client.from('notifications').insert({
        'user_id': customerId,
        'judul': 'Pesanan kamu telah disetujui admin.',
        'pesan':
            'Pesanan #${updated['booking_code'] ?? bookingId} sudah disetujui dan akan diteruskan ke pemilik rental.',
        'type': 'booking',
        'ref_id': bookingId,
        'is_read': false,
      });
      debugPrint(
        'Admin notification inserted for booking=$bookingId userId=$customerId',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Failed to insert admin notification for booking=$bookingId userId=$customerId error=$e',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> batalkanPesanan(String bookingId) async {
    await _client
        .from('bookings')
        .update({
          'status': 'cancelled',
          'payment_status': 'failed',
          'admin_notes': 'Dibatalkan oleh admin',
          'cancellation_reason': 'Dibatalkan oleh admin',
          'cancelled_by': 'admin',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancellation_status': 'Dibatalkan Admin',
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
