import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'marketplace_page.dart';
import 'cart_page.dart';
import 'customer_orders_page.dart';
import 'customer_dashboard_page.dart';

class CustomerMainShell extends StatefulWidget {
  final int initialIndex;

  const CustomerMainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<CustomerMainShell> createState() => _CustomerMainShellState();
}

class _CustomerMainShellState extends State<CustomerMainShell> {
  late int _selectedIndex;

  final GlobalKey<CartPageState> _cartKey = GlobalKey<CartPageState>();
  final GlobalKey<CustomerOrdersPageState> _ordersKey = GlobalKey<CustomerOrdersPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      const MarketplacePage(),
      CartPage(key: _cartKey),
      CustomerOrdersPage(key: _ordersKey),
      const CustomerDashboardPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _cartKey.currentState?.refreshCart();
    } else if (index == 2) {
      _ordersKey.currentState?.refreshOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWebWide = constraints.maxWidth >= 768;

        if (isWebWide) {
          return _buildWebLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
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
              label: 'Marketplace',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Keranjang',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Akun',
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
          // Top Web Header Bar
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
                // Brand Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'NACC Marketplace',
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
                    _buildWebNavItem(0, Icons.storefront, 'Marketplace'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(1, Icons.shopping_cart, 'Keranjang'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(2, Icons.receipt_long, 'Pesanan'),
                    const SizedBox(width: 8),
                    _buildWebNavItem(3, Icons.person, 'Akun'),
                  ],
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
