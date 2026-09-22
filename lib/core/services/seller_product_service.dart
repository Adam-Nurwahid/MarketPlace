import 'package:marketplace/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final response = await _supabase
        .from('products')
        .select('''
          id,
          store_id,
          name,
          description,
          price,
          stock,
          status,
          stores!inner (
            seller_id,
            name
          )
        ''')
        .eq('stores.seller_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createProduct({
    required String storeId,
    required String name,
    required String description,
    required double price,
    required int stock,
  }) async {
    await _supabase.from('products').insert({
      'store_id': storeId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'status': 'ACTIVE',
    });
  }

  Future<void> deleteProduct(String productId) async {
    final deletedProduct = await _supabase
        .from('products')
        .delete()
        .eq('id', productId)
        .select('id');

    if (deletedProduct.isEmpty) {
      throw Exception(
        'Produk tidak dapat dihapus. Akun mungkin sedang disuspend.',
      );
    }
  }
}