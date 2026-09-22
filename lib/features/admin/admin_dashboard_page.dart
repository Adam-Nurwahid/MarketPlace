import 'package:flutter/material.dart';
import 'package:marketplace/features/admin/admin_orders_page.dart';
import 'package:marketplace/features/admin/admin_products_page.dart';
import 'package:marketplace/features/admin/admin_sellers_page.dart';
import '../../core/services/auth_service.dart';
import 'admin_store_management_page.dart';
import 'admin_users_page.dart'; // Ditambahkan: import untuk AdminUsersPage

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();

              if (context.mounted) {
                Navigator.popUntil(
                  context,
                      (route) => route.isFirst,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStoreManagementPage(),
                  ),
                );
              },
              icon: const Icon(Icons.store),
              label: const Text('Kelola Persetujuan Toko'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersPage(),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Manajemen Pengguna'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminOrdersPage(),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Seluruh Transaksi'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminProductsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.inventory_2),
              label: const Text('Manajemen Produk'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminSellersPage(),
                  ),
                );
              },
              icon: const Icon(Icons.store),
              label: const Text('Manajemen Seller'),
            ),
          ],
        ),
      ),
    );
  }
}