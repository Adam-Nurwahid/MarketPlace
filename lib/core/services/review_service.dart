import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Membuat review produk
  Future<Map<String, dynamic>> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating harus antara 1 sampai 5');
    }

    try {
      final response = await _supabase.rpc(
        'create_product_review',
        params: {
          'p_order_id': orderId,
          'p_product_id': productId,
          'p_rating': rating,
          'p_comment': comment,
        },
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Gagal membuat review: $e');
    }
  }

  /// Mengambil review berdasarkan produk
  Future<List<Map<String, dynamic>>> getProductReviews(
      String productId,
      ) async {
    final response = await _supabase
        .from('reviews')
        .select('''
          id,
          rating,
          comment,
          created_at,
          user_id
        ''')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<bool> hasReviewed({
    required String orderId,
    required String productId,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final response = await _supabase
        .from('reviews')
        .select('id')
        .eq('user_id', user.id)
        .eq('order_id', orderId)
        .eq('product_id', productId)
        .maybeSingle();

    return response != null;
  }
}