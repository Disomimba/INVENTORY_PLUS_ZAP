// lib/ui/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../logic/inventory_controller.dart';

class DashboardPage extends StatelessWidget {
  final InventoryController controller;

  const DashboardPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // 1. FIX: Use your existing filterInventory method to get the full list!
    final allItems = controller.filterInventory(query: "", category: "All");

    final totalItems = allItems.length;
    final totalCategories = controller.getUniqueCategories().length;

    // 2. Count low stock items.
    // (Note: If your data model uses 'item.stock' instead of 'item.quantity', just change the word below!)
    final lowStockItems = allItems.where((item) => item.quantity < 10).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Overview",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800
                    ? 3
                    : (constraints.maxWidth > 500 ? 2 : 1);

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 2.5,
                  children: [
                    _buildStatCard(
                      "Total Products",
                      totalItems.toString(),
                      LucideIcons.package,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      "Low Stock Alerts",
                      lowStockItems.toString(),
                      LucideIcons.triangleAlert400,
                      Colors.red,
                    ),
                    _buildStatCard(
                      "Active Categories",
                      totalCategories.toString(),
                      LucideIcons.tags,
                      Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
