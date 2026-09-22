import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    final profile = await _supabase
        .from('profiles')
        .select('id, name, email, role, status')
        .eq('id', user.id)
        .single();

    return profile;
  }
}