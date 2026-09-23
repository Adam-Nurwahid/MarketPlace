import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../customer/customer_main_shell.dart';
import '../seller/seller_main_shell.dart';
import '../admin/admin_main_shell.dart';

class RoleDashboardPage extends StatefulWidget {
  const RoleDashboardPage({super.key});

  @override
  State<RoleDashboardPage> createState() =>
      _RoleDashboardPageState();
}

class _RoleDashboardPageState
    extends State<RoleDashboardPage> {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  String? _errorMessage;
  Widget? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final profile =
      await _profileService.getCurrentProfile();

      final role = profile['role'];
      final status = profile['status'];

      if (status != 'ACTIVE') {
        throw Exception(
          'Akun kamu belum aktif atau sedang ditangguhkan.',
        );
      }

      Widget dashboard;

      switch (role) {
        case 'CUSTOMER':
          dashboard = const CustomerMainShell();
          break;

        case 'SELLER':
          dashboard = const SellerMainShell();
          break;

        case 'ADMIN':
          dashboard = const AdminMainShell();
          break;

        default:
          throw Exception('Role user tidak dikenal.');
      }

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_errorMessage!),
          ),
        ),
      );
    }

    return _dashboard!;
  }
}