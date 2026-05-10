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
  // 1. The GlobalKey to control our Form validation
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // 2. Trigger validation before doing anything else
    // If validation fails (returns false), we stop here and don't show loading.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

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
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
              // 3. Wrap the Column in the Form widget
              child: Form(
                key: _formKey,
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
                        child: const Icon(
                          LucideIcons.packageCheck,
                          color: Colors.orange,
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        "Inventory Plus",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        "Hardware Management System",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 60),

                    const Text(
                      "USERNAME",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      _usernameController,
                      "Enter your username",
                      LucideIcons.user,
                      false,
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "PASSWORD",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      _passwordController,
                      "••••••••",
                      LucideIcons.lock,
                      true,
                      suffix: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                          color: Colors.grey,
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 4. Update to TextFormField with validator logic
  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isPassword, {
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return isPassword ? 'Password is required' : 'Username is required';
        }

        if (isPassword && text.length < 6) {
          return 'Password must be at least 6 characters';
        }

        if (!isPassword && text.length < 3) {
          return 'Username must be at least 3 characters';
        }

        return null; // Returning null means no error!
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Add a subtle error style to blend with the dark theme
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
