import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSellerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllSellers() async {
    final response = await _supabase
        .from('profiles')
        .select('''
          id,
          email,
          role,
          is_suspended,
          created_at
        ''')
        .eq('role', 'SELLER')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> toggleSuspension({
    required String sellerId,
    required bool isSuspended,
  }) async {
    await _supabase.rpc(
      'admin_toggle_seller_suspension',
      params: {
        'p_seller_id': sellerId,
        'p_is_suspended': isSuspended,
      },
    );
  }
}