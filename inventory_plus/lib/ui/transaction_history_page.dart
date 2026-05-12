import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../logic/inventory_controller.dart';

class TransactionHistoryPage extends StatefulWidget {
  final InventoryController controller;

  const TransactionHistoryPage({super.key, required this.controller});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.controller.fetchAllTransactionHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No transaction history found for this store.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final transactions = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final productInfo = transaction['products'];
              final productName = productInfo != null ? productInfo['product_name'] : 'N/A';
              
              // Safely extract the linked profile data (Foreign Key)
              final profileInfo = transaction['profiles'];
              final userName = profileInfo != null ? profileInfo['name'] : (transaction['user_name'] ?? 'Unknown');
              final userRole = profileInfo != null ? profileInfo['role'] : '';

              final date = DateTime.parse(transaction['created_at']).toLocal();
              final formattedDate = "${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
              final quantityChange = transaction['quantity_change'];
              final isPositive = quantityChange > 0;
              final type = transaction['transaction_type'] as String;

              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: Icon(
                    isPositive ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                    color: isPositive ? Colors.green : (type == 'delete' ? Colors.red : Colors.orange),
                    size: 32,
                  ),
                  title: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    "${type.replaceAll('_', ' ').capitalize()} by $userName${userRole.isNotEmpty ? ' ($userRole)' : ''}\n$formattedDate",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isPositive ? '+' : ''}$quantityChange",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        "Qty: ${transaction['new_quantity']}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}