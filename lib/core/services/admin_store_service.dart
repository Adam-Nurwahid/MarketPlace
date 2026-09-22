import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPendingStores() async {
    final response = await _supabase
        .from('stores')
        .select('''
          id,
          name,
          description,
          status,
          created_at,
          profiles (
            name,
            email
          )
        ''')
        .eq('status', 'PENDING')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateStoreStatus({
    required String storeId,
    required String status,
  }) async {
    await _supabase
        .from('stores')
        .update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', storeId);
  }
}