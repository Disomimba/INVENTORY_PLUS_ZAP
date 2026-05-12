import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../login/auth_service.dart'; 
import '../logic/inventory_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
 

  const LoginPage({super.key, required this.controller});
  
  final InventoryController controller; 
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService(); 
  
  bool _isPasswordVisible = false;
  bool _isLoading = false; 

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError("Please enter your username and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate against custom profiles table
      final userProfile = await _authService.login(username, password);

      if (userProfile != null) {
        final String? assignedLocationId = userProfile['location_id'];
        final String userId = userProfile['id'].toString();
        
        // 2. Save session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userId);

        // 3. Save user details to the controller
        widget.controller.setLoggedInUser(
          name: userProfile['name'] ?? username,
          id: userId,
          role: userProfile['role'] ?? 'staff',
        );

        // 4. Load app data based on user's location
        if (assignedLocationId != null && assignedLocationId.isNotEmpty) {
          await widget.controller.loadAppData(assignedLocationId);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          _showError("Account Error: No store assigned to this user.");
          await prefs.clear();
        }
      } else {
        _showError("Invalid username or password");
      }
    } catch (e) {
      _showError("An unexpected error occurred during login.");
      print("Login Page Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.packageCheck, color: Colors.orange, size: 60),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    "Inventory Plus",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(
                  child: Text(
                    "Hardware Management System",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 60),

                const Text("USERNAME", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTextField(_usernameController, "Enter your username", LucideIcons.user, false),

                const SizedBox(height: 24),

                const Text("PASSWORD", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTextField(
                  _passwordController, 
                  "••••••••", 
                  LucideIcons.lock, 
                  true,
                  suffix: IconButton(
                    icon: Icon(_isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff, color: Colors.grey, size: 18),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPassword, {Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}