import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/role_guard.dart';

class CreateStorePage extends StatefulWidget {
  const CreateStorePage({super.key});

  @override
  State<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _supabase = Supabase.instance.client;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabase.from('stores').insert({
        'seller_id': user.id,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'PENDING',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toko berhasil dibuat dan menunggu persetujuan Admin.'),
        ),
      );

      Navigator.pop(context);
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat toko: ${e.message}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'SELLER',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buat Toko'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Toko',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama toko wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Toko',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createStore,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Buat Toko'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}