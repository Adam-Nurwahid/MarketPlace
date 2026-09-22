import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getProducts({
    String search = '',
  }) async {
    var query = _supabase
        .from('products')
        .select('''
          id,
          name,
          description,
          price,
          stock,
          image_path,
          status,
          stores (
            id,
            name,
            status
          )
        ''')
        .eq('status', 'ACTIVE');

    final response = await query;

    final products = List<Map<String, dynamic>>.from(response);

    if (search.trim().isEmpty) {
      return products;
    }

    final keyword = search.toLowerCase();

    return products.where((product) {
      final productName =
      (product['name'] ?? '').toString().toLowerCase();

      final storeData = product['stores'];

      final storeName = storeData is Map
          ? (storeData['name'] ?? '').toString().toLowerCase()
          : '';

      return productName.contains(keyword) ||
          storeName.contains(keyword);
    }).toList();
  }
}