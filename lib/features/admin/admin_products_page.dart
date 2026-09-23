import 'package:flutter/material.dart';
import 'package:marketplace/core/services/admin_product_service.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => AdminProductsPageState();
}

class AdminProductsPageState extends State<AdminProductsPage> {
  final AdminProductService _service = AdminProductService();

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void refreshProducts() {
    _loadProducts(showLoading: false);
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final products = await _service.getAllProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil produk: $e'),
        ),
      );
    }
  }

  String _formatPrice(dynamic value) {
    final price = (value as num?)?.toDouble() ?? 0;
    return 'Rp ${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Manajemen Produk'),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _products.isEmpty
          ? const Center(
        child: Text('Belum ada produk'),
      )
          : RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];

            final store = product['stores']
            as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.inventory_2),
                ),
                title: Text(
                  product['name'] ?? '-',
                ),
                subtitle: Text(
                  'Toko: ${store?['name'] ?? '-'}\n'
                      'Harga: ${_formatPrice(product['price'])}\n'
                      'Stok: ${product['stock'] ?? 0}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}