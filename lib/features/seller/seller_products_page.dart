import 'package:flutter/material.dart';

import '../../core/services/seller_product_service.dart';
import '../../core/services/store_service.dart';
import '../../core/widgets/role_guard.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final SellerProductService _productService = SellerProductService();
  final StoreService _storeService = StoreService();

  List<Map<String, dynamic>> _products = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getMyProducts();

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

  Future<void> _showAddProductDialog() async {
    // Tampilkan indikator loading saat mengecek toko
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? store;
    try {
      store = await _storeService.getMyStore();
    } catch (_) {
      store = null;
    }

    if (!mounted) return;
    Navigator.pop(context); // Tutup dialog loading

    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu belum memiliki toko.'),
        ),
      );
      return;
    }

    if (store['status'] != 'APPROVED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toko harus disetujui Admin terlebih dahulu.'),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Produk'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                      ),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                        ),
                        validator: (value) {
                          final price = double.tryParse(value ?? '');

                          if (price == null || price <= 0) {
                            return 'Harga tidak valid';
                          }

                          return null;
                        },
                      ),
                      TextFormField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok',
                        ),
                        validator: (value) {
                          final stock = int.tryParse(value ?? '');

                          if (stock == null || stock < 0) {
                            return 'Stok tidak valid';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                  isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      await _productService.createProduct(
                        storeId: store!['id'],
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        price: double.parse(priceController.text),
                        stock: int.parse(stockController.text),
                      );

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      await _loadProducts();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Produk berhasil ditambahkan.'),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        isSaving = false;
                      });

                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(_getFriendlyErrorMessage(e)),
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  String _getFriendlyErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('row-level security') ||
        message.contains('violates row-level security')) {
      return 'Akun seller sedang disuspend. '
          'Kamu tidak dapat mengubah produk.';
    }

    if (message.contains('akun mungkin sedang disuspend')) {
      return 'Produk tidak dapat dihapus karena akun sedang disuspend.';
    }

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  Future<void> _confirmDeleteProduct(
      String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteProduct(productId);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);

      await _loadProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil dihapus.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getFriendlyErrorMessage(e)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'SELLER',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Produk'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadOrders,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddProductDialog,
          child: const Icon(Icons.add),
        ),
        body: _buildBody(),
      ),
    );
  }

  void _loadOrders() {
    _loadProducts();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text('Error: $_errorMessage'),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('Belum ada produk. Tekan + untuk menambahkan.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                product['name'] ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Harga: Rp ${product['price'] ?? 0}\n'
                      'Stok: ${product['stock'] ?? 0}\n'
                      'Status: ${product['status'] ?? '-'}',
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _confirmDeleteProduct(
                    product['id'],
                    product['name'] ?? 'Produk ini',
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}