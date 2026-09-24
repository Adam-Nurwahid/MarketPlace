import 'package:supabase_flutter/supabase_flutter.dart';

class SellerOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    // Ambil toko milik seller yang sedang login.
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
          ),

          order_store_status (
            store_id,
            status,
            updated_at
          )
        ''')
        .order('created_at', ascending: false);

    final orders = List<Map<String, dynamic>>.from(response);

    // Hanya order yang memiliki produk dari toko seller.
    final filteredOrders = orders.where((order) {
      final items = order['order_items'] as List<dynamic>? ?? [];

      return items.any((item) {
        return storeIds.contains(item['store_id']);
      });
    }).map((order) {
      final statuses =
          order['order_store_status'] as List<dynamic>? ?? [];

      // Seller hanya memiliki toko yang sedang digunakan.
      final sellerStoreId = storeIds.firstWhere(
            (storeId) {
          return statuses.any(
                (status) => status['store_id'] == storeId,
          );
        },
        orElse: () => storeIds.first,
      );

      final sellerStatusEntry = statuses.cast<Map<String, dynamic>?>().firstWhere(
            (status) => status?['store_id'] == sellerStoreId,
        orElse: () => null,
      );

      final result = Map<String, dynamic>.from(order);

      // Status khusus toko seller.
      result['seller_store_id'] = sellerStoreId;
      result['seller_status'] =
          sellerStatusEntry?['status'] ?? order['status'];

      return result;
    }).toList();

    return filteredOrders;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String storeId,
    required String newStatus,
  }) async {
    await _supabase.rpc(
      'seller_update_order_status',
      params: {
        'p_order_id': orderId,
        'p_store_id': storeId,
        'p_new_status': newStatus,
      },
    );
  }
}