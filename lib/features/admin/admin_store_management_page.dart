import 'package:flutter/material.dart';

import '../../core/services/admin_store_service.dart';
import '../../core/widgets/role_guard.dart';

class AdminStoreManagementPage extends StatefulWidget {
  const AdminStoreManagementPage({super.key});

  @override
  State<AdminStoreManagementPage> createState() =>
      _AdminStoreManagementPageState();
}

class _AdminStoreManagementPageState
    extends State<AdminStoreManagementPage> {
  final AdminStoreService _storeService = AdminStoreService();

  List<Map<String, dynamic>> _stores = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stores = await _storeService.getPendingStores();

      if (!mounted) return;

      setState(() {
        _stores = stores;
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

  Future<void> _updateStatus({
    required String storeId,
    required String status,
  }) async {
    try {
      await _storeService.updateStoreStatus(
        storeId: storeId,
        status: status,
      );

      await _loadStores();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status toko berhasil diubah menjadi $status'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'ADMIN',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Persetujuan Toko'),
        ),
        body: _buildBody(),
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Terjadi error:\n$_errorMessage',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_stores.isEmpty) {
      return const Center(
        child: Text('Tidak ada toko yang menunggu persetujuan.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];

        final storeId = store['id'].toString();
        final storeName = store['name'] ?? '-';
        final description = store['description'] ?? '-';

        final profile = store['profiles'];

        final sellerName = profile is Map
            ? profile['name'] ?? '-'
            : '-';

        final sellerEmail = profile is Map
            ? profile['email'] ?? '-'
            : '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text('Deskripsi: $description'),
                Text('Seller: $sellerName'),
                Text('Email: $sellerEmail'),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateStatus(
                            storeId: storeId,
                            status: 'APPROVED',
                          );
                        },
                        child: const Text('Approve'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _updateStatus(
                            storeId: storeId,
                            status: 'REJECTED',
                          );
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}