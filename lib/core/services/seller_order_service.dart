import 'package:supabase_flutter/supabase_flutter.dart';

class SellerOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    // Mengambil toko milik seller yang sedang login
    final storesResponse = await _supabase
        .from('stores')
        .select('id')
        .eq('seller_id', user.id);

    final storeIds = (storesResponse as List)
        .map((store) => store['id'] as String)
        .toList();

    if (storeIds.isEmpty) {
      return [];
    }

    // Mengambil pesanan
    final response = await _supabase
        .from('orders')
        .select('''
          id,
          user_id,
          recipient_name,
          phone,
          shipping_address,
          subtotal,
          shipping_fee,
          total,
          status,
          created_at,
          order_items (
            id,
            order_id,
            product_id,
            store_id,
            product_name,
            store_name,
            quantity,
            price,
            line_total
          )
        ''')
        .order('created_at', ascending: false);

    final orders = List<Map<String, dynamic>>.from(response);

    // Hanya tampilkan order yang memiliki produk dari toko seller
    final filteredOrders = orders.where((order) {
      final items = order['order_items'] as List<dynamic>? ?? [];

      return items.any((item) {
        return storeIds.contains(item['store_id']);
      });
    }).toList();

    return filteredOrders;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    await _supabase.rpc(
      'seller_update_order_status',
      params: {
        'p_order_id': orderId,
        'p_new_status': newStatus,
      },
    );
  }

}