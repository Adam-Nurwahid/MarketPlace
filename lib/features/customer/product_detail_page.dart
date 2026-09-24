import 'package:flutter/material.dart';

import '../../core/services/cart_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/currency_formatter.dart';
class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() =>
      _ProductDetailPageState();
}

class _ProductDetailPageState
    extends State<ProductDetailPage> {
  final CartService _cartService = CartService();

  int _quantity = 1;
  bool _isLoading = false;



  Future<void> _addToCart() async {
    final productId = widget.product['id'].toString();

    final stock = int.tryParse(
      widget.product['stock'].toString(),
    ) ??
        0;

    if (_quantity > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity melebihi stok tersedia.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _cartService.addToCart(
        productId: productId,
        quantity: _quantity,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan ke cart.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan produk: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final productName = product['name'] ?? 'Produk';
    final description = product['description'] ?? '-';
    final price = product['price'];
    final stock = product['stock'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: _buildProductImage(
                product['image_path']?.toString(),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              productName.toString(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              CurrencyFormatter.rupiah(product['price']),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text('Stok tersedia: $stock'),

            const SizedBox(height: 24),

            const Text(
              'Deskripsi Produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(description.toString()),

            const SizedBox(height: 24),

            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () {
                    setState(() {
                      _quantity--;
                    });
                  }
                      : null,
                  icon: const Icon(Icons.remove),
                ),

                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: _quantity < (stock as int)
                      ? () {
                    setState(() {
                      _quantity++;
                    });
                  }
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: stock > 0 && !_isLoading
                    ? _addToCart
                    : null,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Tambah ke Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(
        child: Icon(
          Icons.shopping_bag,
          size: 100,
        ),
      );
    }

    final imageUrl = Supabase.instance.client.storage
        .from('product-images')
        .getPublicUrl(imagePath);

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 100,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}