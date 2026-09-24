import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/role_guard.dart';
import 'seller_dashboard_page.dart';
import 'seller_products_page.dart';
import 'seller_orders_page.dart';

class SellerMainShell extends StatefulWidget {
  final int initialIndex;

  const SellerMainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<SellerMainShell> createState() => _SellerMainShellState();
}

class _SellerMainShellState extends State<SellerMainShell> {
  late int _selectedIndex;

  final GlobalKey<SellerDashboardPageState> _storeKey =
  GlobalKey<SellerDashboardPageState>();
  final GlobalKey<SellerProductsPageState> _productsKey =
  GlobalKey<SellerProductsPageState>();
  final GlobalKey<SellerOrdersPageState> _ordersKey =
  GlobalKey<SellerOrdersPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      SellerDashboardPage(key: _storeKey),
      SellerProductsPage(key: _productsKey),
      SellerOrdersPage(key: _ordersKey),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _storeKey.currentState?.refreshStore();
    } else if (index == 1) {
      _productsKey.currentState?.refreshProducts();
    } else if (index == 2) {
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
      requiredRole: 'SELLER',
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
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Toko Saya',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Pesanan',
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
          // Top Web Seller Center Header
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
                // Seller Brand Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'NACC Seller Center',
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
                    _buildWebNavItem(0, Icons.storefront, 'Toko Saya'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(1, Icons.inventory_2, 'Produk'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(2, Icons.assignment, 'Pesanan'),
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
