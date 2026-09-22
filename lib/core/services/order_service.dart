import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil pesanan milik Customer
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final response = await _supabase
        .from('orders')
        .select('''
          id,
          shipping_fee,
          total,
          status,
          created_at,
          recipient_name,
          phone,
          shipping_address,
          order_items (
            id,
            product_id,
            product_name,
            store_name,
            quantity,
            price,
            line_total
          ),
          payments (
            status,
            paid_at
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Membatalkan pesanan Customer
  Future<void> cancelOrder({
    required String orderId,
  }) async {
    await _supabase.rpc(
      'customer_cancel_order',
      params: {
        'p_order_id': orderId,
      },
    );
  }
}