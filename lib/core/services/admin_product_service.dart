import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil semua data produk beserta info toko
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final response = await _supabase
        .from('products')
        .select('''
          id,
          name,
          description,
          price,
          stock,
          image_path,
          status,
          store_id,
          created_at,
          updated_at,
          stores (
            id,
            name,
            status,
            seller_id
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Mengambil daftar toko yang sudah disetujui (APPROVED)
  Future<List<Map<String, dynamic>>> getStores() async {
    final response = await _supabase
        .from('stores')
        .select('''
          id,
          name,
          status,
          seller_id
        ''')
        .eq('status', 'APPROVED')
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Menambahkan produk baru beserta upload gambar (opsional)
  Future<void> createProduct({
    required String storeId,
    required String name,
    required String description,
    required double price,
    required int stock,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    String? imagePath;

    try {
      if (imageBytes != null) {
        final extension = imageExtension ?? 'jpg';
        imagePath =
        'admin/${DateTime.now().millisecondsSinceEpoch}.$extension';

        await _supabase.storage.from('product-images').uploadBinary(
          imagePath,
          imageBytes,
          fileOptions: FileOptions(
            contentType: _getContentType(extension),
            upsert: false,
          ),
        );
      }

      await _supabase.from('products').insert({
        'store_id': storeId,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'image_path': imagePath,
        'status': 'ACTIVE',
      });
    } catch (e) {
      // Rollback: Hapus gambar yang sudah di-upload jika insert ke DB gagal
      if (imagePath != null) {
        try {
          await _supabase.storage
              .from('product-images')
              .remove([imagePath]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Memperbarui data produk dan mengelola pergantian/penghapusan gambar
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    String? currentImagePath,
    Uint8List? newImageBytes,
    String? newImageExtension,
    bool removeCurrentImage = false,
  }) async {
    String? imagePath = currentImagePath;

    // Hapus gambar lama jika user memilih Hapus
    if (removeCurrentImage &&
        currentImagePath != null &&
        currentImagePath.isNotEmpty) {
      await _supabase.storage
          .from('product-images')
          .remove([currentImagePath]);

      imagePath = null;
    }

    // Upload gambar baru jika user memilih Ganti Gambar
    if (newImageBytes != null) {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User belum login');
      }

      final extension = newImageExtension ?? 'jpg';

      final newPath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage
          .from('product-images')
          .uploadBinary(
        newPath,
        newImageBytes,
        fileOptions: FileOptions(
          contentType: 'image/$extension',
          upsert: false,
        ),
      );

      // Hapus gambar lama setelah gambar baru berhasil di-upload
      if (currentImagePath != null &&
          currentImagePath.isNotEmpty &&
          !removeCurrentImage) {
        await _supabase.storage
            .from('product-images')
            .remove([currentImagePath]);
      }

      imagePath = newPath;
    }

    // Update data produk
    await _supabase
        .from('products')
        .update({
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image_path': imagePath,
    })
        .eq('id', productId);
  }

  /// Mengubah status aktif/nonaktif produk (ACTIVE / INACTIVE)
  Future<void> updateProductStatus({
    required String productId,
    required String status,
  }) async {
    await _supabase.from('products').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }

  /// Menghapus produk dan file gambarnya di Supabase Storage
  Future<void> deleteProduct(String productId) async {
    final deletedProduct = await _supabase
        .from('products')
        .delete()
        .eq('id', productId)
        .select('id, image_path');

    if (deletedProduct.isEmpty) {
      throw Exception('Produk tidak ditemukan atau gagal dihapus.');
    }

    final imagePath = deletedProduct.first['image_path'];

    if (imagePath != null && imagePath.toString().isNotEmpty) {
      try {
        await _supabase.storage
            .from('product-images')
            .remove([imagePath.toString()]);
      } catch (_) {}
    }
  }

  /// Mendapatkan Public URL dari file gambar
  String getProductImageUrl(String imagePath) {
    return _supabase.storage.from('product-images').getPublicUrl(imagePath);
  }

  /// Helper untuk menentukan MIME Content Type gambar
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}