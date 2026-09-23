import 'package:flutter/material.dart';
import 'package:marketplace/features/customer/customer_orders_page.dart';
import 'package:marketplace/features/customer/order_history_page.dart';
import '../../core/services/auth_service.dart';
import '../seller/seller_dashboard_page.dart';
import 'marketplace_page.dart';
import 'cart_page.dart';

class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
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
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MarketplacePage(),
                  ),
                );
              },
              child: const Text('Buka Marketplace'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartPage(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Keranjang Belanja'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryPage(),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Pesanan Saya'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerOrdersPage(),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Riwayat Pesanan'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SellerDashboardPage(),
                  ),
                );
              },
              child: const Text('Test Akses Seller'),
            )
          ],
        )
      ),
    );
  }
}