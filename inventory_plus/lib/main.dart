import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'ui/login_page.dart';
import 'ui/main_screen.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logic/inventory_controller.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
  '/': (context) => LoginPage(controller: controller),
  '/main': (context) => MainScreen(controller: controller),
},
    );
  }
}