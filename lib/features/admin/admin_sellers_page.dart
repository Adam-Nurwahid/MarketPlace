import 'package:flutter/material.dart';
import 'package:marketplace/core/services/admin_seller_service.dart';
import '../../core/widgets/role_guard.dart';

class AdminSellersPage extends StatefulWidget {
  const AdminSellersPage({super.key});

  @override
  State<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends State<AdminSellersPage> {
  final AdminSellerService _service = AdminSellerService();

  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  Future<void> _loadSellers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sellers = await _service.getAllSellers();

      if (!mounted) return;

      setState(() {
        _sellers = sellers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil seller: $e'),
        ),
      );
    }
  }

  Future<void> _toggleSuspension(
      Map<String, dynamic> seller,
      ) async {
    final sellerId = seller['id'] as String;
    final isSuspended = seller['is_suspended'] == true;
    final newStatus = !isSuspended;

    final action = newStatus ? 'mensuspend' : 'mengaktifkan';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            newStatus ? 'Suspend Seller' : 'Aktifkan Seller',
          ),
          content: Text(
            'Apakah kamu yakin ingin $action seller ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.toggleSuspension(
        sellerId: sellerId,
        isSuspended: newStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Seller berhasil disuspend'
                : 'Seller berhasil diaktifkan',
          ),
        ),
      );

      await _loadSellers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status seller: $e'),
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
          title: const Text('Manajemen Seller'),
          actions: [
            IconButton(
              onPressed: _loadSellers,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _sellers.isEmpty
            ? const Center(
          child: Text('Belum ada seller'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _sellers.length,
          itemBuilder: (context, index) {
            final seller = _sellers[index];

            final isSuspended =
                seller['is_suspended'] == true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    isSuspended
                        ? Icons.block
                        : Icons.store,
                  ),
                ),
                title: Text(
                  seller['email'] ?? '-',
                ),
                subtitle: Text(
                  isSuspended
                      ? 'Status: SUSPENDED'
                      : 'Status: ACTIVE',
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    _toggleSuspension(seller);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuspended
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isSuspended
                        ? 'Aktifkan'
                        : 'Suspend',
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}