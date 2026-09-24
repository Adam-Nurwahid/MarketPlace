import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/role_guard.dart';
import 'admin_store_management_page.dart';
import 'admin_users_and_sellers_view.dart';
import 'admin_products_page.dart';
import 'admin_orders_page.dart';

class AdminMainShell extends StatefulWidget {
  final int initialIndex;

  const AdminMainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  late int _selectedIndex;

  final GlobalKey<AdminStoreManagementPageState> _storesKey =
  GlobalKey<AdminStoreManagementPageState>();
  final GlobalKey<AdminUsersAndSellersViewState> _usersAndSellersKey =
  GlobalKey<AdminUsersAndSellersViewState>();
  final GlobalKey<AdminProductsPageState> _productsKey =
  GlobalKey<AdminProductsPageState>();
  final GlobalKey<AdminOrdersPageState> _ordersKey =
  GlobalKey<AdminOrdersPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      AdminStoreManagementPage(key: _storesKey),
      AdminUsersAndSellersView(key: _usersAndSellersKey),
      AdminProductsPage(key: _productsKey),
      AdminOrdersPage(key: _ordersKey),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _storesKey.currentState?.refreshStores();
    } else if (index == 1) {
      _usersAndSellersKey.currentState?.refreshAll();
    } else if (index == 2) {
      _productsKey.currentState?.refreshProducts();
    } else if (index == 3) {
      _ordersKey.currentState?.refreshOrders();
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
    return RoleGuard(
      requiredRole: 'ADMIN',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWebWide = constraints.maxWidth >= 768;

          if (isWebWide) {
            return _buildWebLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        backgroundColor: AppColors.danger,
        tooltip: 'Keluar',
        child: const Icon(
          Icons.logout,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.navActive,
          unselectedItemColor: AppColors.navInactive,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Persetujuan Toko',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Pengguna',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transaksi',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Web Admin Panel Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Admin Brand Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'NACC Admin Panel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Navigation Tabs
                Row(
                  children: [
                    _buildWebNavItem(0, Icons.store, 'Dashboard & Toko'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(1, Icons.people, 'Pengguna & Seller'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(2, Icons.inventory_2, 'Produk'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(3, Icons.receipt_long, 'Transaksi'),
                  ],
                ),
                const SizedBox(width: 24),
                // Logout Action
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  tooltip: 'Keluar',
                ),
              ],
            ),
          ),
          // Stack Content Body
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.navActive : AppColors.navInactive,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.navActive : AppColors.navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
