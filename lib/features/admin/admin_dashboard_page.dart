import 'package:flutter/material.dart';

import '../../core/widgets/role_guard.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';
import 'admin_sellers_page.dart';
import 'admin_store_management_page.dart';
import 'admin_users_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'ADMIN',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildAdminContent(context),
        ),
      ),
    );
  }

  Widget _buildAdminContent(BuildContext context) {
    return Column(
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
                builder: (context) => const AdminProductsPage(),
              ),
            );
          },
          icon: const Icon(Icons.inventory_2),
          label: const Text('Manajemen Produk'),
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
                builder: (context) => const AdminSellersPage(),
              ),
            );
          },
          icon: const Icon(Icons.storefront),
          label: const Text('Manajemen Seller'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}