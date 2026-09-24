import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:marketplace/core/services/admin_product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';

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
    return CurrencyFormatter.rupiah(value);
  }

  String _getProductImageUrl(String imagePath) {
    return Supabase.instance.client.storage
        .from('product-images')
        .getPublicUrl(imagePath);
  }

  Future<Uint8List?> _pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return null;

    return await image.readAsBytes();
  }

  // Fungsi untuk mengubah status aktif/nonaktif produk
  Future<void> _toggleProductStatus(Map<String, dynamic> product) async {
    final isActive = product['status'] == 'ACTIVE';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isActive ? 'Nonaktifkan Produk' : 'Aktifkan Produk',
        ),
        content: Text(
          isActive
              ? 'Produk tidak akan tampil di marketplace. Lanjutkan?'
              : 'Produk akan kembali tampil di marketplace. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.updateProductStatus(
        productId: product['id'].toString(),
        status: isActive ? 'INACTIVE' : 'ACTIVE',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Produk berhasil dinonaktifkan'
                : 'Produk berhasil diaktifkan',
          ),
        ),
      );

      await _loadProducts(showLoading: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status produk: $e'),
        ),
      );
    }
  }

  // Fungsi konfirmasi hapus produk
  Future<void> _confirmDeleteProduct(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
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
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteProduct(productId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil dihapus'),
        ),
      );

      await _loadProducts(showLoading: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus produk: $e'),
        ),
      );
    }
  }

  // Dialog Tambah/Edit Produk
  Future<void> _showProductDialog({Map<String, dynamic>? product}) async {
    final isEdit = product != null;

    final nameController = TextEditingController(
      text: isEdit ? product['name']?.toString() : '',
    );

    final descriptionController = TextEditingController(
      text: isEdit ? product['description']?.toString() : '',
    );

    final priceController = TextEditingController(
      text: isEdit ? product['price']?.toString() : '',
    );

    final stockController = TextEditingController(
      text: isEdit ? product['stock']?.toString() : '',
    );

    Uint8List? selectedImageBytes;

    bool removeCurrentImage = false;

    final currentImagePath =
    isEdit ? product['image_path']?.toString() : null;

    final store =
    isEdit ? product['stores'] as Map<String, dynamic>? : null;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget imagePreview() {
              // Preview gambar baru
              if (selectedImageBytes != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    selectedImageBytes!,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                );
              }

              // Tidak ada gambar
              if (removeCurrentImage ||
                  currentImagePath == null ||
                  currentImagePath.isEmpty) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tidak ada gambar',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Gambar lama
              final imageUrl = _getProductImageUrl(currentImagePath);

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                      ),
                    );
                  },
                ),
              );
            }

            return AlertDialog(
              title: Text(
                isEdit ? 'Edit Produk' : 'Tambah Produk',
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =========================
                        // GAMBAR
                        // =========================
                        imagePreview(),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final bytes = await _pickImage();

                                if (bytes == null) return;

                                setDialogState(() {
                                  selectedImageBytes = bytes;
                                  removeCurrentImage = false;
                                });
                              },
                              icon: const Icon(Icons.upload),
                              label: Text(
                                isEdit
                                    ? 'Ganti Gambar'
                                    : 'Upload Gambar',
                              ),
                            ),

                            if (selectedImageBytes != null ||
                                (currentImagePath != null &&
                                    currentImagePath.isNotEmpty &&
                                    !removeCurrentImage)) ...[
                              const SizedBox(width: 8),

                              OutlinedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    selectedImageBytes = null;
                                    removeCurrentImage = true;
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Hapus',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 20),

                        // =========================
                        // NAMA
                        // =========================
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Wajib diisi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // DESKRIPSI
                        // =========================
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // HARGA
                        // =========================
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Harga wajib diisi';
                            }

                            if (double.tryParse(v.trim()) == null) {
                              return 'Harga tidak valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // STOK
                        // =========================
                        TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Stok wajib diisi';
                            }

                            if (int.tryParse(v.trim()) == null) {
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final price =
                    double.parse(priceController.text.trim());

                    final stock =
                    int.parse(stockController.text.trim());

                    try {
                      if (isEdit) {
                        await _service.updateProduct(
                          productId: product['id'].toString(),
                          name: nameController.text.trim(),
                          description:
                          descriptionController.text.trim(),
                          price: price,
                          stock: stock,
                          currentImagePath: currentImagePath,
                          newImageBytes: selectedImageBytes,
                          newImageExtension:
                          selectedImageBytes != null
                              ? 'jpg'
                              : null,
                          removeCurrentImage: removeCurrentImage,
                        );
                      } else {
                        await _service.createProduct(
                          storeId:
                          store?['id']?.toString() ?? '',
                          name: nameController.text.trim(),
                          description:
                          descriptionController.text.trim(),
                          price: price,
                          stock: stock,
                          imageBytes: selectedImageBytes,
                          imageExtension:
                          selectedImageBytes != null
                              ? 'jpg'
                              : null,
                        );
                      }

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Produk berhasil diperbarui'
                                : 'Produk berhasil ditambahkan',
                          ),
                        ),
                      );

                      await _loadProducts(
                        showLoading: false,
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal menyimpan produk: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
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
            tooltip: 'Refresh',
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
            final store = product['stores'] as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _buildProductImage(
                  product['image_path']?.toString(),
                ),
                title: Text(
                  product['name'] ?? '-',
                ),
                subtitle: Text(
                  'Toko: ${store?['name'] ?? '-'}\n'
                      'Harga: ${_formatPrice(product['price'])}\n'
                      'Stok: ${product['stock'] ?? 0}\n'
                      'Status: ${product['status'] ?? '-'}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showProductDialog(product: product);
                    } else if (value == 'delete') {
                      _confirmDeleteProduct(
                        product['id'].toString(),
                        product['name']?.toString() ?? 'Produk ini',
                      );
                    } else if (value == 'toggle_status') {
                      _toggleProductStatus(product);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
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
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            product['status'] == 'ACTIVE'
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product['status'] == 'ACTIVE'
                                ? 'Nonaktifkan'
                                : 'Aktifkan',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
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
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const CircleAvatar(
        child: Icon(Icons.inventory_2),
      );
    }

    final imageUrl = _getProductImageUrl(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const CircleAvatar(
            child: Icon(Icons.broken_image_outlined),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }
}