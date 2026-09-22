import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final response = await _supabase
        .from('products')
        .select('''
          id,
          name,
          price,
          stock,
          store_id,
          stores (
            id,
            name,
            seller_id
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}