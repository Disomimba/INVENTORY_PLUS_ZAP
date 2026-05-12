import 'package:flutter/material.dart';
import '../data/inventory.dart';
import '../logic/inventory_controller.dart';
// These are your existing, reusable UI pages!
import 'scanner_search_page.dart';
import 'inventory_page.dart';
import 'item_detail_page.dart';
import 'settings_page.dart';
import 'staff_management_page.dart';
import 'dashboard_page.dart';

class MainScreen extends StatefulWidget {
  final InventoryController controller;
  const MainScreen({super.key, required this.controller});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? _currentIndex;
  bool _isDetailView = false;
  InventoryItem? _selectedItem;

  // --- NEW SIDEBAR STATE VARIABLES ---
  bool _isSidebarExpanded = false;
  int? _hoveredIndex;

  // --- DESKTOP COLOR PALETTE ---
  static const Color _primaryOrange = Color(0xFFEA580C);
  static const Color _darkSidebarBg = Color(0xFF0F172A);
  static const Color _mainBg = Color(0xFFF1F5F9);

  // Reusable Page Functions
  void _handleSelectItem(InventoryItem item) {
    // 1. Check screen size
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      // 2. DESKTOP / WEB: Show floating modal over the dashboard
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 500, // Prevents the stretching!
            height: 700,
            child: ItemDetailPage(
              item: item,
              controller: widget.controller,
              onBack: () => Navigator.pop(context), // Closes the dialog
              onUpdate: (updatedItem) {
                setState(() => widget.controller.updateItem(updatedItem));
              },
              onDelete: (id) {
                setState(() => widget.controller.deleteItem(id));
                Navigator.pop(context); // Closes the dialog after delete
              },
            ),
          ),
        ),
      );
    } else {
      // 3. MOBILE: Keep your exact original logic
      setState(() {
        _selectedItem = item;
        _isDetailView = true;
      });
    }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        // 1. SET LANDING PAGES: Index 0 (Dashboard) for Web, Index 1 (Scanner) for Mobile
        if (_currentIndex == null) {
          _currentIndex = isDesktop ? 0 : 1;
        }

        // 2. THE MASTER PAGE LIST (Exactly 5 Pages)
        final pages = [
          DashboardPage(controller: widget.controller), // Index 0
          ScannerSearchPage(
            controller: widget.controller,
            onSelectItem: _handleSelectItem,
          ), // Index 1
          InventoryPage(
            controller: widget.controller,
            onSelectItem: _handleSelectItem,
          ), // Index 2
          StaffManagementPage(controller: widget.controller), // Index 3
          SettingsPage(
            // Index 4
            controller: widget.controller,
            userName: widget.controller.currentUserName ?? "Unknown User",
            userId: widget.controller.currentUserId ?? "Unknown ID",
            userRole: widget.controller.currentUserRole ?? "staff",
          ),
        ];

        // ==========================================
        // DESKTOP LAYOUT (Sidebar with 5 Buttons)
        // ==========================================
        if (isDesktop) {
          return Scaffold(
            backgroundColor: _mainBg,
            body: Row(
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _isSidebarExpanded = true),
                  onExit: (_) => setState(() => _isSidebarExpanded = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: _isSidebarExpanded ? 240 : 88,
                    color: _darkSidebarBg,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 32.0,
                            bottom: 40.0,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 30),
                              const Icon(
                                Icons.inventory_2_rounded,
                                color: _primaryOrange,
                                size: 28,
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: _isSidebarExpanded ? 1.0 : 0.0,
                                    child: const Row(
                                      children: [
                                        SizedBox(width: 16),
                                        Text(
                                          'Inventory Plus',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 3. UPDATED DESKTOP SIDEBAR BUTTONS
                        _buildSidebarItem(
                          0,
                          Icons.dashboard_outlined,
                          'Dashboard',
                          activeIcon: Icons.dashboard,
                        ),
                        _buildSidebarItem(1, Icons.qr_code_scanner, 'Scan'),
                        _buildSidebarItem(
                          2,
                          Icons.inventory_2_outlined,
                          'Inventory',
                          activeIcon: Icons.inventory_2,
                        ),
                        _buildSidebarItem(
                          3,
                          Icons.people_outline,
                          'Staff',
                          activeIcon: Icons.people,
                        ),
                        _buildSidebarItem(
                          4,
                          Icons.settings_outlined,
                          'Settings',
                          activeIcon: Icons.settings,
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: pages),
                ),
              ],
            ),
          );
        }

        // ==========================================
        // MOBILE LAYOUT (Bottom Nav with 4 Buttons)
        // ==========================================
        int mobileNavIndex = 0; // Default to Scanner (which is page 1)
        if (_currentIndex == 2) mobileNavIndex = 1; // Inventory page
        if (_currentIndex == 4) mobileNavIndex = 2; // Settings page

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.black,
            toolbarHeight: 0,
            elevation: 0,
          ),
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1E293B),
            currentIndex: mobileNavIndex,
            selectedItemColor: _primaryOrange,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                // 2. Map the 3 mobile buttons to their exact page numbers
                if (index == 0) _currentIndex = 1; // Go to Scanner
                if (index == 1) _currentIndex = 2; // Go to Inventory
                if (index == 2) _currentIndex = 4; // Go to Settings
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scanner',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Inventory',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for your custom sidebar hover effects
  Widget _buildSidebarItem(
    int index,
    IconData icon,
    String label, {
    IconData? activeIcon,
  }) {
    final isSelected = _currentIndex == index;
    final isHovered = _hoveredIndex == index;
    final currentColor = isSelected || isHovered
        ? _primaryOrange
        : const Color(0xFF94A3B8);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          color: isSelected
              ? _primaryOrange.withOpacity(0.05)
              : Colors.transparent,
          child: Row(
            children: [
              const SizedBox(width: 30),
              Icon(
                isSelected ? (activeIcon ?? icon) : icon,
                color: currentColor,
                size: 28,
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _isSidebarExpanded ? 1.0 : 0.0,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          label,
                          style: TextStyle(
                            color: currentColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
