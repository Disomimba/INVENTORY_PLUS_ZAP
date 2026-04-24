import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../logic/inventory_controller.dart';
import 'map_editor_page.dart';

class SettingsPage extends StatelessWidget {
  final InventoryController controller;
  final String userName;
  final String userId;
  final String userRole;

  const SettingsPage({
    super.key, 
    required this.controller,
    this.userName = "Admin User", 
    this.userId = "ID: 100234",
    this.userRole = "admin",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: ListView(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 10),
          
          _buildSectionHeader("WAREHOUSE CONFIGURATION"),
          _buildSettingTile(
            icon: LucideIcons.map,
            color: Colors.blue,
            title: "Store Layout Designer",
            subtitle: "Manage racks, shelves, and pathways",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapEditorPage(controller: controller))),
          ),
          _buildSettingTile(
            icon: LucideIcons.printer,
            color: Colors.orange,
            title: "Label Printer Settings",
            subtitle: "Configure Bluetooth SKU printers",
            onTap: () {},
          ),

          const SizedBox(height: 20),
          _buildSectionHeader("ORGANIZATION"),
          if (userRole == 'admin') ...[
            _buildSettingTile(
              icon: LucideIcons.users,
              color: Colors.purple,
              title: "Staff Management",
              subtitle: "Create and manage staff accounts",
              onTap: () {},
            ),
            _buildSettingTile(
              icon: LucideIcons.trendingUp,
              color: Colors.green,
              title: "Inventory Reports",
              subtitle: "Export stock levels to CSV/PDF",
              onTap: () {},
            ),
          ],

          const SizedBox(height: 20),
          _buildSectionHeader("ACCOUNT"),
          _buildSettingTile(
            icon: LucideIcons.lock,
            color: Colors.grey,
            title: "Change Password",
            onTap: () {},
          ),
          _buildSettingTile(
            icon: LucideIcons.logOut,
            color: Colors.redAccent,
            title: "Logout",
            textColor: Colors.redAccent,
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text("Version 1.0.4", style: TextStyle(color: Colors.grey, fontSize: 12))),
          )
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: const Icon(LucideIcons.user, color: Colors.orange, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(userId, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
      ),
    );
  }
}