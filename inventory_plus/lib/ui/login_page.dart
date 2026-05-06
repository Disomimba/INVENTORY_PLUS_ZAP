import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../login/auth_service.dart'; 
import '../logic/inventory_controller.dart';

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

    final userProfile = await _authService.login(username, password);

    if (userProfile != null) {
      try {
        final String? assignedLocationId = userProfile['location_id'];
        
        // Save the user's details to the controller so the rest of the app knows!
        widget.controller.setLoggedInUser(
          name: userProfile['name'] ?? username,
          id: userProfile['id']?.toString() ?? 'Unknown ID',
          role: userProfile['role'] ?? 'staff',
        );

        if (assignedLocationId != null && assignedLocationId.isNotEmpty) {
          await widget.controller.loadAppData(assignedLocationId);

          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          setState(() => _isLoading = false);
          _showError("Account Error: No store assigned to this user.");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError("Sync Error: Could not connect to store data.");
        print("Load Error: $e");
      }
    } else {
      setState(() => _isLoading = false);
      _showError("Invalid username or password");
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