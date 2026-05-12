import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../logic/inventory_controller.dart';

class DashboardPage extends StatelessWidget {
  final InventoryController controller;
  const DashboardPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // 1. Fetch your dynamic data
    final allItems = controller.filterInventory(query: "", category: "All");
    final totalItems = allItems.length;
    final totalCategories = controller.getUniqueCategories().length;

    // Count low stock items (assuming 'quantity' is the variable name)
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
            // RESPONSIVE GRID LAYOUT
            LayoutBuilder(
              builder: (context, constraints) {
                // If Desktop (>800px), use 3 columns. If Tablet, 2. If Mobile, 1.
                int crossAxisCount = constraints.maxWidth > 800
                    ? 3
                    : (constraints.maxWidth > 500 ? 2 : 1);

                // FIX: Give mobile cards more height! (Lower number = taller cards)
                double aspectRatio = constraints.maxWidth < 500 ? 2.0 : 2.6;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio:
                      aspectRatio, // <--- Use the new dynamic variable here
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
                      LucideIcons.triangleAlert,
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

  // Helper widget to build the clean dashboard cards
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
