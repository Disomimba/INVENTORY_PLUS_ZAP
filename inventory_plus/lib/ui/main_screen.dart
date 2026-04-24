import 'package:flutter/material.dart';
import '../../data/inventory.dart';
import '../../logic/inventory_controller.dart';
import 'scanner_search_page.dart';
import 'inventory_page.dart';
import 'item_detail_page.dart';
import 'settings_page.dart';
class MainScreen extends StatefulWidget {
  final InventoryController controller; 
  const MainScreen({super.key, required this.controller}); 
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isDetailView = false;
  InventoryItem? _selectedItem;

  void _handleSelectItem(InventoryItem item) {
    setState(() {
      _selectedItem = item;
      _isDetailView = true;
    });
  }

  void _handleBackToMain() {
    setState(() {
      _isDetailView = false;
      _selectedItem = null;
    });
  }

  void _handleUpdateItem(InventoryItem updatedItem) {
    setState(() {
      widget.controller.updateItem(updatedItem);
      _selectedItem = updatedItem;
    });
  }

  void _handleDeleteItem(String id) {
    setState(() {
      widget.controller.deleteItem(id);
      _handleBackToMain();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDetailView && _selectedItem != null) {
      return ItemDetailPage(
        item: _selectedItem!,
        controller: widget.controller, 
        onBack: _handleBackToMain,
        onUpdate: _handleUpdateItem,
        onDelete: _handleDeleteItem,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 0,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ScannerSearchPage(
            controller: widget.controller, 
            onSelectItem: _handleSelectItem,
          ),
          InventoryPage(
            controller: widget.controller,
            onSelectItem: _handleSelectItem,
          ),
          SettingsPage(
            controller: widget.controller,
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Inventory'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}