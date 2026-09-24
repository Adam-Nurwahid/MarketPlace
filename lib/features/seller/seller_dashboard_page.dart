import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/store_service.dart';
import 'create_store_page.dart';
import 'seller_products_page.dart';
import 'seller_orders_page.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => SellerDashboardPageState();
}

class SellerDashboardPageState extends State<SellerDashboardPage> {
  final StoreService _storeService = StoreService();

  Map<String, dynamic>? _store;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  void refreshStore() {
    _loadStore(showLoading: false);
  }

  Future<void> _loadStore({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final store = await _storeService.getMyStore();

      if (!mounted) return;

      setState(() {
        _store = store;
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

  Future<void> _logout() async {
    try {
      await AuthService().logout();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal logout: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ringkasan Toko'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal mengambil data toko:\n$_errorMessage',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_store == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateStorePage(),
              ),
            );

            _loadStore();
          },
          child: const Text('Buat Toko'),
        ),
      );
    }

    final storeName = _store!['name'] ?? '-';
    final description = _store!['description'] ?? '-';
    final status = _store!['status'] ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toko Saya',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nama Toko: $storeName',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            'Deskripsi: $description',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'Status: $status',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (status == 'PENDING')
            const Text(
              'Toko sedang menunggu persetujuan Admin.',
            ),
          if (status == 'REJECTED')
            const Text(
              'Toko ditolak oleh Admin.',
            ),
          if (status == 'APPROVED') ...[
          ],
        ],
      ),
    );
  }
}