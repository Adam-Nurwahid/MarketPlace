import 'package:flutter/material.dart';

import '../../core/services/product_service.dart';
import 'product_detail_page.dart';
class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() =>
      _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final ProductService _productService = ProductService();

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _products = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({
    String search = '',
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getProducts(
        search: search,
      );

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    final value = double.tryParse(price.toString()) ?? 0;

    return 'Rp ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Marketplace'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari produk atau toko',
                hintText: 'Contoh: Sepatu',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadProducts();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                _loadProducts(search: value);
              },
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _buildProductContent(),
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
          size: 64,
        ),
      );
    }

    final imageUrl =
    _productService.getProductImageUrl(imagePath);

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 64,
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

  Widget _buildProductContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Terjadi kesalahan:\n$_errorMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('Belum ada produk tersedia.'),
      );
    }

    return GridView.builder(
      gridDelegate:
      const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];

        final storeData = product['stores'];

        final storeName = storeData is Map
            ? storeData['name'] ?? 'Toko'
            : 'Toko';

        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: _buildProductImage(
                      product['image_path']?.toString(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  product['name'] ?? 'Produk',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  storeName.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatPrice(product['price']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Stok: ${product['stock']}',
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            product: product,
                          ),
                        ),
                      );
                    },
                    child: const Text('Lihat Produk'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}