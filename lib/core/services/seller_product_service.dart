import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final response = await _supabase
        .from('products')
        .select('''
          id,
          store_id,
          name,
          description,
          price,
          stock,
          image_path,
          status,
          stores!inner (
            seller_id,
            name
          )
        ''')
        .eq('stores.seller_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createProduct({
    required String storeId,
    required String name,
    required String description,
    required double price,
    required int stock,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    String? imagePath;

    try {
      // Upload gambar jika ada
      if (imageBytes != null) {
        final extension = imageExtension ?? 'jpg';

        imagePath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

        await _supabase.storage
            .from('product-images')
            .uploadBinary(
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
      // Kalau insert product gagal setelah gambar berhasil di-upload,
      // hapus gambar agar tidak menjadi file yatim.
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

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    String? currentImagePath,
    Uint8List? newImageBytes,
    String? newImageExtension,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    String? newImagePath;

    try {
      if (newImageBytes != null) {
        final extension = newImageExtension ?? 'jpg';

        newImagePath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

        await _supabase.storage
            .from('product-images')
            .uploadBinary(
          newImagePath,
          newImageBytes,
          fileOptions: FileOptions(
            contentType: _getContentType(extension),
            upsert: false,
          ),
        );
      }

      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newImagePath != null) {
        updateData['image_path'] = newImagePath;
      }

      final updatedProduct = await _supabase
          .from('products')
          .update(updateData)
          .eq('id', productId)
          .select('id');

      if (updatedProduct.isEmpty) {
        throw Exception(
          'Produk tidak dapat diperbarui. '
              'Pastikan produk milik toko Anda dan akun tidak disuspend.',
        );
      }

      // Hapus gambar lama setelah update berhasil
      if (newImagePath != null &&
          currentImagePath != null &&
          currentImagePath.isNotEmpty) {
        try {
          await _supabase.storage
              .from('product-images')
              .remove([currentImagePath]);
        } catch (_) {
          // Tidak menggagalkan update kalau penghapusan gambar lama gagal.
        }
      }
    } catch (e) {
      // Jika upload gambar baru berhasil tetapi update DB gagal,
      // hapus gambar baru.
      if (newImagePath != null) {
        try {
          await _supabase.storage
              .from('product-images')
              .remove([newImagePath]);
        } catch (_) {}
      }

      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final deletedProduct = await _supabase
        .from('products')
        .delete()
        .eq('id', productId)
        .select('id, image_path');

    if (deletedProduct.isEmpty) {
      throw Exception(
        'Produk tidak dapat dihapus. Akun mungkin sedang disuspend.',
      );
    }

    final imagePath = deletedProduct.first['image_path'];

    if (imagePath != null &&
        imagePath.toString().isNotEmpty) {
      try {
        await _supabase.storage
            .from('product-images')
            .remove([imagePath.toString()]);
      } catch (_) {}
    }
  }

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
  String getProductImageUrl(String imagePath) {
    return _supabase.storage
        .from('product-images')
        .getPublicUrl(imagePath);
  }
}