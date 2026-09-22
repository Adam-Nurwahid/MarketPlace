import 'package:supabase_flutter/supabase_flutter.dart';

class AddressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyAddresses() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final response = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createAddress({
    required String recipientName,
    required String phone,
    required String addressLine,
    required String city,
    required String province,
    required String postalCode,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    await _supabase.from('addresses').insert({
      'user_id': user.id,
      'recipient_name': recipientName,
      'phone': phone,
      'address_line': addressLine,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'is_default': false,
    });
  }
}