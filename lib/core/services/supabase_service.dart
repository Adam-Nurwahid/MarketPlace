import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> testConnection() async {
  try {
    final response = await supabase
        .from('products')
        .select()
        .limit(10);

    print('Connection successful: $response');
  } catch (e) {
    print('Connection failed: $e');
  }
}