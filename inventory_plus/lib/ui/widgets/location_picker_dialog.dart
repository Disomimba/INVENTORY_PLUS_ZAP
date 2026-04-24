import 'package:flutter/material.dart';
import '../../logic/inventory_controller.dart';

class LocationPickerDialog extends StatelessWidget {
  final InventoryController controller;

  const LocationPickerDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Item Location"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: InteractiveViewer(
          child: Stack(
            children: controller.storeLayout.map((el) {
              return Positioned(
                left: el.position.dx,
                top: el.position.dy,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, el),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.layers, color: Colors.white, size: 20),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}