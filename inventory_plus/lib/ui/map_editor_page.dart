import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/inventory.dart';
import '../../logic/inventory_controller.dart'; 

class MapEditorPage extends StatefulWidget {
  final InventoryController controller;

  const MapEditorPage({super.key, required this.controller});

  @override
  State<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends State<MapEditorPage> {
  late List<MapElement> layout;

  @override
  void initState() {
    super.initState();
    layout = List.from(widget.controller.storeLayout);
  }

  IconData _getIcon(ElementType type) {
    switch (type) {
      case ElementType.door: return LucideIcons.doorOpen;
      case ElementType.rack: return LucideIcons.layers;
      case ElementType.shelf: return LucideIcons.container;
      case ElementType.cashier: return LucideIcons.banknote;
      case ElementType.pathway: return LucideIcons.footprints;
    }
  }

  void _handleSave() async {
    widget.controller.storeLayout = layout;
    await widget.controller.saveLayout(); 
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Store layout saved successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store Layout Designer"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () => setState(() => layout.clear()),
          ),
          IconButton(
            icon: const Icon(LucideIcons.save),
            onPressed: _handleSave,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DragTarget<ElementType>(
              onAcceptWithDetails: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final Offset localOffset = box.globalToLocal(details.offset);

                setState(() {
                  layout.add(MapElement(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: details.data,
                    position: localOffset,
                    label: details.data.name.toUpperCase(),
                  ));
                });
              },
              builder: (context, candidateData, rejectedData) {
                return InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(1000),
                  minScale: 0.1,
                  maxScale: 2.5,
                  child: Container(
                    width: 2000, 
                    height: 2000,
                    decoration: _buildGridDecoration(),
                    child: Stack(
                      children: layout.map((el) => _buildPositionedElement(el)).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildToolbox(),
        ],
      ),
    );
  }

  BoxDecoration _buildGridDecoration() {
    return BoxDecoration(
      color: Colors.white,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF8FAFC)],
      ),
    );
  }

  Widget _buildPositionedElement(MapElement el) {
    return Positioned(
      left: el.position.dx,
      top: el.position.dy,
      width: el.size.width,
      height: el.size.height,
      child: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                el.position += details.delta;
              });
            },
            onLongPress: () => setState(() => layout.remove(el)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColor(el.type).withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black26)
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIcon(el.type), color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      el.label,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  double newWidth = el.size.width + details.delta.dx;
                  double newHeight = el.size.height + details.delta.dy;

                  el.size = Size(
                    newWidth < 40 ? 40 : newWidth,
                    newHeight < 40 ? 40 : newHeight,
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_full, size: 12, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(ElementType type) {
    switch (type) {
      case ElementType.door: return Colors.green;
      case ElementType.rack: return Colors.blue;
      case ElementType.shelf: return Colors.orange;
      case ElementType.cashier: return Colors.purple;
      case ElementType.pathway: return Colors.grey;
    }
  }

  Widget _buildToolbox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDraggableTool(ElementType.door, "Door", Colors.green),
            _buildDraggableTool(ElementType.rack, "Rack", Colors.blue),
            _buildDraggableTool(ElementType.shelf, "Shelf", Colors.orange),
            _buildDraggableTool(ElementType.cashier, "Cashier", Colors.purple),
            _buildDraggableTool(ElementType.pathway, "Path", Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableTool(ElementType type, String label, Color color) {
    return Draggable<ElementType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Icon(_getIcon(type), color: Colors.white),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(_getIcon(type), color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}