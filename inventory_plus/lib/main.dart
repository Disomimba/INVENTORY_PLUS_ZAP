import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'ui/login_page.dart';
import 'ui/main_screen.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logic/inventory_controller.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: "lib/.env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  } catch (e) {
    print("Initialization Error: $e");
  }

  final inventoryController = InventoryController();

  runApp(InventoryApp(controller: inventoryController));
}

class InventoryApp extends StatelessWidget {
  final InventoryController controller;

  const InventoryApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(controller: controller),
        '/login': (context) => LoginPage(controller: controller),
        '/main': (context) => MainScreen(controller: controller),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final InventoryController controller;

  const AuthWrapper({super.key, required this.controller});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      try {
        final userId = session.user.id;
        
        // Fetch user profile from Supabase to get the assigned location_id.
        // Note: Change 'users' to 'profiles' or your actual table name if different.
        final userProfile = await Supabase.instance.client
            .from('users') 
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (userProfile != null) {
          final String? assignedLocationId = userProfile['location_id'];

          widget.controller.setLoggedInUser(
            name: userProfile['name'] ?? 'User',
            id: userId,
            role: userProfile['role'] ?? 'staff',
          );

          if (assignedLocationId != null && assignedLocationId.isNotEmpty) {
            await widget.controller.loadAppData(assignedLocationId);
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/main');
              return;
            }
          }
        }
      } catch (e) {
        print("Error restoring session: $e");
      }
      // If fetching profile or app data loading fails, sign out and fall back to login
      await Supabase.instance.client.auth.signOut();
    }
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );
  }
}