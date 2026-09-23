import 'package:flutter/material.dart';
import 'admin_users_page.dart';
import 'admin_sellers_page.dart';

class AdminUsersAndSellersView extends StatefulWidget {
  const AdminUsersAndSellersView({super.key});

  @override
  State<AdminUsersAndSellersView> createState() =>
      AdminUsersAndSellersViewState();
}

class AdminUsersAndSellersViewState extends State<AdminUsersAndSellersView> {
  final GlobalKey<AdminUsersPageState> _usersKey =
  GlobalKey<AdminUsersPageState>();
  final GlobalKey<AdminSellersPageState> _sellersKey =
  GlobalKey<AdminSellersPageState>();

  void refreshAll() {
    _usersKey.currentState?.refreshUsers();
    _sellersKey.currentState?.refreshSellers();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Manajemen Pengguna & Seller'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Semua Pengguna'),
              Tab(icon: Icon(Icons.storefront), text: 'Daftar Seller'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AdminUsersPage(key: _usersKey),
            AdminSellersPage(key: _sellersKey),
          ],
        ),
      ),
    );
  }
}
