import 'package:flutter/material.dart';
import 'package:marketplace/core/services/admin_user_service.dart';
import '../../core/widgets/role_guard.dart';


class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminUserService _service = AdminUserService();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _service.getAllUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil pengguna: $e'),
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
          title: const Text('Manajemen Pengguna'),
          actions: [
            IconButton(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _users.isEmpty
            ? const Center(
          child: Text('Belum ada pengguna'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  user['email'] ?? 'Email tidak tersedia',
                ),
                subtitle: Text(
                  'Role: ${user['role'] ?? '-'}\n'
                      'ID: ${user['id'] ?? '-'}',
                ),
                isThreeLine: true,
                trailing: Text(
                  user['role'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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