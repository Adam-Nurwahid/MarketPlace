import 'package:supabase_flutter/supabase_flutter.dart';

class StoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMyStore() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final response = await _supabase
        .from('stores')
        .select('id, name, description, status, created_at')
        .eq('seller_id', user.id)
        .maybeSingle();

    return response;
  }
}