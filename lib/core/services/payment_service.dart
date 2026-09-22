import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> simulatePayment({
    required String orderId,
    required bool success,
  }) async {
    await _supabase.rpc(
      'simulate_payment',
      params: {
        'p_order_id': orderId,
        'p_success': success,
      },
    );
  }
}