import 'package:flutter/material.dart';
import 'package:marketplace/core/services/cart_service.dart';
import 'package:marketplace/features/customer/checkout_page.dart';


class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();

  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void refreshCart() {
    _loadCart(showLoading: false);
  }

  Future<void> _loadCart({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final items = await _cartService.getCartItems();

      setState(() {
        cartItems = items;
      });
    } catch (e) {
      _showMessage('Gagal memuat cart: $e');
    } finally {
      if (showLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double _calculateSubtotal() {
    double subtotal = 0;

    for (final item in cartItems) {
      final product = item['products'];

      if (product == null) continue;

      final price = double.parse(product['price'].toString());
      final quantity = item['quantity'] as int;

      subtotal += price * quantity;
    }

    return subtotal;
  }

  Future<void> _updateQuantity(
      Map<String, dynamic> item,
      int newQuantity,
      ) async {
    final product = item['products'];

    if (product == null) return;

    final stock = int.parse(product['stock'].toString());

    if (newQuantity > stock) {
      _showMessage('Jumlah melebihi stok yang tersedia');
      return;
    }

    try {
      await _cartService.updateQuantity(
        cartItemId: item['id'],
        quantity: newQuantity,
      );

      await _loadCart(showLoading: false);
    } catch (e) {
      _showMessage('Gagal mengubah jumlah: $e');
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    try {
      await _cartService.removeItem(cartItemId);

      await _loadCart(showLoading: false);

      _showMessage('Produk dihapus dari keranjang');
    } catch (e) {
      _showMessage('Gagal menghapus produk: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Keranjang Belanja'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : cartItems.isEmpty
          ? const Center(
        child: Text(
          'Keranjang masih kosong',
          style: TextStyle(fontSize: 18),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final product = item['products'];

                if (product == null) {
                  return const SizedBox.shrink();
                }

                final productName = product['name'] ?? '-';
                final store = product['stores'];
                final storeName = store?['name'] ?? '-';

                final price = double.parse(
                  product['price'].toString(),
                );

                final stock = int.parse(
                  product['stock'].toString(),
                );

                final quantity = item['quantity'] as int;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toko: $storeName',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPrice(price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Stok tersedia: $stock'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: quantity > 1
                                      ? () => _updateQuantity(
                                    item,
                                    quantity - 1,
                                  )
                                      : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  onPressed: quantity < stock
                                      ? () => _updateQuantity(
                                    item,
                                    quantity + 1,
                                  )
                                      : null,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                _removeItem(item['id']);
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Subtotal: ${_formatPrice(price * quantity)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text('Total Belanja'),
                    Text(
                      _formatPrice(subtotal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutPage(),
                      ),
                    );

                    if (result == true) {
                      await _loadCart();
                    }
                  },
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}