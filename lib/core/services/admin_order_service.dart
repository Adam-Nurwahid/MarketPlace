import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final response = await _supabase
        .from('orders')
        .select('''
          id,
          user_id,
          total,
          status,
          created_at,
          recipient_name,
          shipping_address,
          order_items (
            product_name,
            store_name,
            quantity,
            price
          ),
          payments (
            status,
            paid_at
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}