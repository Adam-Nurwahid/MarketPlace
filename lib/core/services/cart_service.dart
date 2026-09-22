import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> _getMyCartId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final cart = await _supabase
        .from('carts')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (cart == null) {
      throw Exception('Cart user tidak ditemukan');
    }

    return cart['id'] as String;
  }

  // Mendapatkan seluruh item dalam cart
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final cartId = await _getMyCartId();

    final response = await _supabase
        .from('cart_items')
        .select('''
          id,
          quantity,
          product_id,
          products (
            id,
            name,
            description,
            price,
            stock,
            image_path,
            stores (
              id,
              name
            )
          )
        ''')
        .eq('cart_id', cartId)
        .order('id');

    return List<Map<String, dynamic>>.from(response);
  }

  // Menambahkan produk ke cart
  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    final cartId = await _getMyCartId();

    final existingItem = await _supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existingItem != null) {
      final currentQuantity = existingItem['quantity'] as int;
      final newQuantity = currentQuantity + quantity;

      await _supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', existingItem['id']);
    } else {
      await _supabase.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  // Mengubah jumlah produk
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    if (quantity < 1) {
      await removeItem(cartItemId);
      return;
    }

    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  // Menghapus item dari cart
  Future<void> removeItem(String cartItemId) async {
    await _supabase
        .from('cart_items')
        .delete()
        .eq('id', cartItemId);
  }

  Future<String> checkout({
    required String addressId,
    double shippingFee = 10000,
  }) async {
    final response = await _supabase.rpc(
      'checkout_cart',
      params: {
        'p_address_id': addressId,
        'p_shipping_fee': shippingFee,
      },
    );

    return response as String;
  }
}