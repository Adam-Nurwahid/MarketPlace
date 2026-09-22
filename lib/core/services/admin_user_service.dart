import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _supabase
        .from('profiles')
        .select('''
          id,
          email,
          role,
          created_at
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}