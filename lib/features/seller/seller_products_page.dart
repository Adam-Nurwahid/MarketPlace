import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/seller_product_service.dart';
import '../../core/services/store_service.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => SellerProductsPageState();
}

class SellerProductsPageState extends State<SellerProductsPage> {
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

  void refreshProducts() {
    _loadProducts(showLoading: false);
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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

  Future<Map<String, dynamic>?> _getApprovedStore() async {
    try {
      final store = await _storeService.getMyStore();

      if (store == null) {
        return null;
      }

      if (store['status'] != 'APPROVED') {
        return null;
      }

      return store;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showProductDialog({
    Map<String, dynamic>? product,
  }) async {
    final isEdit = product != null;

    final store = await _getApprovedStore();

    if (!mounted) return;

    if (!isEdit && store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Toko harus sudah disetujui Admin terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController(
      text: product?['name']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: product?['description']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: product == null
          ? ''
          : _formatRupiah(product['price']),
    );

    final stockController = TextEditingController(
      text: product?['stock']?.toString() ?? '',
    );

    Uint8List? selectedImageBytes;
    String? selectedImageExtension;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();

              final image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
                maxWidth: 1200,
              );

              if (image == null) return;

              final bytes = await image.readAsBytes();

              final extension = image.name.contains('.')
                  ? image.name.split('.').last.toLowerCase()
                  : 'jpg';

              setDialogState(() {
                selectedImageBytes = bytes;
                selectedImageExtension = extension;
              });
            }

            return AlertDialog(
              title: Text(
                isEdit ? 'Edit Produk' : 'Tambah Produk',
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =========================
                        // IMAGE
                        // =========================
                        GestureDetector(
                          onTap: isSaving ? null : pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                              ),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: selectedImageBytes != null
                                ? ClipRRect(
                              borderRadius:
                              BorderRadius.circular(12),
                              child: Image.memory(
                                selectedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                                : _buildExistingImage(product),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton.icon(
                          onPressed: isSaving ? null : pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(
                            isEdit
                                ? 'Ganti Gambar'
                                : 'Pilih Gambar',
                          ),
                        ),

                        const SizedBox(height: 8),

                        // =========================
                        // NAME
                        // =========================
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Nama produk wajib diisi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // DESCRIPTION
                        // =========================
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // PRICE
                        // =========================
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            hintText: 'Contoh: 150.000',
                          ),
                          onChanged: (value) {
                            final digits =
                            value.replaceAll('.', '');

                            if (digits.isEmpty) {
                              return;
                            }

                            final formatted =
                            _formatRupiah(digits);

                            if (formatted != value) {
                              priceController.value =
                                  TextEditingValue(
                                    text: formatted,
                                    selection:
                                    TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                            }
                          },
                          validator: (value) {
                            final raw =
                            (value ?? '').replaceAll('.', '');

                            final price =
                            int.tryParse(raw);

                            if (price == null || price <= 0) {
                              return 'Harga tidak valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // STOCK
                        // =========================
                        TextFormField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final stock =
                            int.tryParse(value ?? '');

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
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      final rawPrice =
                      priceController.text
                          .replaceAll('.', '');

                      final price =
                      double.parse(rawPrice);

                      final stock =
                      int.parse(
                        stockController.text,
                      );

                      if (isEdit) {
                        await _productService
                            .updateProduct(
                          productId:
                          product!['id'].toString(),
                          name:
                          nameController.text.trim(),
                          description:
                          descriptionController.text
                              .trim(),
                          price: price,
                          stock: stock,
                          currentImagePath:
                          product['image_path']
                              ?.toString(),
                          newImageBytes:
                          selectedImageBytes,
                          newImageExtension:
                          selectedImageExtension,
                        );
                      } else {
                        await _productService
                            .createProduct(
                          storeId:
                          store!['id'].toString(),
                          name:
                          nameController.text.trim(),
                          description:
                          descriptionController.text
                              .trim(),
                          price: price,
                          stock: stock,
                          imageBytes:
                          selectedImageBytes,
                          imageExtension:
                          selectedImageExtension,
                        );
                      }

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(dialogContext);

                      await _loadProducts();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Produk berhasil diperbarui.'
                                : 'Produk berhasil ditambahkan.',
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        isSaving = false;
                      });

                      if (!dialogContext.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            _getFriendlyErrorMessage(e),
                          ),
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isEdit ? 'Simpan Perubahan' : 'Simpan',
                  ),
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

  Widget _buildExistingImage(
      Map<String, dynamic>? product,
      ) {
    final imagePath = product?['image_path']?.toString();

    if (imagePath == null || imagePath.isEmpty) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 50,
          ),
          SizedBox(height: 8),
          Text('Pilih gambar produk'),
        ],
      );
    }

    final imageUrl = _productServiceUrl(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 50,
              ),
              SizedBox(height: 8),
              Text('Gambar tidak dapat ditampilkan'),
            ],
          );
        },
      ),
    );
  }

  String _productServiceUrl(String imagePath) {
    return _productService.getProductImageUrl(imagePath);
  }

  String _formatRupiah(dynamic value) {
    final number = int.tryParse(
      value.toString().replaceAll('.', ''),
    ) ??
        0;

    final digits = number.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 &&
          (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  String _getFriendlyErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('row-level security') ||
        message.contains('violates row-level security')) {
      return 'Akun seller sedang disuspend. '
          'Kamu tidak dapat mengubah produk.';
    }

    if (message.contains('akun mungkin sedang disuspend')) {
      return 'Produk tidak dapat diubah karena akun sedang disuspend.';
    }

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  Future<void> _confirmDeleteProduct(
      String productId,
      String productName,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$productName"?',
        ),
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
      await _deleteProduct(productId);
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
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
        child: Text(
          'Belum ada produk. Tekan + untuk menambahkan.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];

          final imagePath =
          product['image_path']?.toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: SizedBox(
                width: 70,
                height: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imagePath != null &&
                      imagePath.isNotEmpty
                      ? Image.network(
                    _productServiceUrl(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.image_not_supported,
                      );
                    },
                  )
                      : const Icon(
                    Icons.image_outlined,
                    size: 40,
                  ),
                ),
              ),
              title: Text(
                product['name'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Harga: Rp ${_formatRupiah(product['price'])}\n'
                      'Stok: ${product['stock'] ?? 0}\n'
                      'Status: ${product['status'] ?? '-'}',
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showProductDialog(
                      product: product,
                    );
                  } else if (value == 'delete') {
                    _confirmDeleteProduct(
                      product['id'].toString(),
                      product['name'] ?? 'Produk ini',
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}