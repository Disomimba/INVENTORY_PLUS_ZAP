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

      return response;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      print("Get Profile Error: $e");
      return null;
    }
  }
}