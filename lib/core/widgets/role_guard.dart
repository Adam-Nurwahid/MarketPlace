import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleGuard extends StatefulWidget {
  final String requiredRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _isLoading = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });

        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('role, status')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      setState(() {
        _hasAccess =
            profile['role'] == widget.requiredRole &&
                profile['status'] == 'ACTIVE';

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasAccess = false;
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

    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Akses Ditolak'),
        ),
        body: const Center(
          child: Text(
            'Kamu tidak memiliki akses ke halaman ini.',
          ),
        ),
      );
    }

    return widget.child;
  }
}