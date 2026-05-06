import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        return null; 
      }

      print("Login success! Role: ${response['role']}");
      return response;
      
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
}