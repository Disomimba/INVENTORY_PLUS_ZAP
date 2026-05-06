import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/inventory.dart';
import '../../logic/inventory_controller.dart';

enum MapMode { view, manage, selection }

class StoreMap extends StatefulWidget {
  final InventoryController controller;
  final String? highlightId;    
  final ItemLocation? location; 
  final String? itemName;
  final MapMode mode;
  final String? selectedItemId;
  final VoidCallback? onSelectionAssigned;

  const StoreMap({
    super.key,
    required this.controller,
    this.highlightId,
    this.location,
    this.itemName,
    this.mode = MapMode.view,
    this.selectedItemId,
    this.onSelectionAssigned,
  });

  @override
  State<StoreMap> createState() => _StoreMapState();
}

class _StoreMapState extends State<StoreMap> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.mode == MapMode.view ? const EdgeInsets.symmetric(vertical: 8) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: widget.mode == MapMode.view ? BorderRadius.circular(12) : BorderRadius.zero,
        border: widget.mode == MapMode.view ? Border.all(color: Colors.grey.shade800) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (widget.mode == MapMode.view) _buildHeader(),
          _buildLiveMapDisplay(),
          if (widget.location != null) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
                const Icon(LucideIcons.mapPin, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Store Map",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (widget.itemName != null)
                        Text(
                          widget.itemName!,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLiveMapDisplay() {
    double mapWidth = 1000;
    double mapHeight = 1000;

    for (var el in widget.controller.storeLayout) {
      if (el.position.dx + el.size.width + 100 > mapWidth) {
        mapWidth = el.position.dx + el.size.width + 100;
      }
      if (el.position.dy + el.size.height + 100 > mapHeight) {
        mapHeight = el.position.dy + el.size.height + 100;
      }
    }

    // Depth sort: Elements furthest away (smaller X + Y in this rotated view) must paint first
    var sortedLayout = List<MapElement>.from(widget.controller.storeLayout);
    sortedLayout.sort((a, b) {
      double distA = a.position.dx + a.position.dy;
      double distB = b.position.dx + b.position.dy;
      return distA.compareTo(distB);
    });

    Widget map = InteractiveViewer(
              constrained: false,
              minScale: 0.1,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(200),
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-30 * math.pi / 180)
                  ..rotateZ(-45 * math.pi / 180),
                alignment: FractionalOffset.center,
                child: Builder(
                  builder: (BuildContext dropContext) {
                    return DragTarget<ElementType>(
                      onAcceptWithDetails: (details) {
                        final RenderBox box = dropContext.findRenderObject() as RenderBox;
                        final Offset localOffset = box.globalToLocal(details.offset);

                        setState(() {
                          widget.controller.storeLayout.add(MapElement(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            type: details.data,
                            position: localOffset,
                            label: details.data.name.toUpperCase(),
                          ));
                        });
                        widget.controller.saveLayout();
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: mapWidth,
                          height: mapHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            border: Border.all(color: Colors.blueGrey, width: 2),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                painter: GridPainter(),
                                size: Size(mapWidth, mapHeight),
                              ),
                              ...sortedLayout.map((el) => _buildPhysicalElement(el)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );

    if (widget.mode == MapMode.view) {
      return Container(
        height: 400,
        width: double.infinity,
        color: const Color(0xFF0F172A),
        child: map,
      );
    } else {
      return Expanded(
        child: Container(
          width: double.infinity,
          color: const Color(0xFF0F172A),
          child: map,
        ),
      );
    }
  }

  Color _getElementColor(ElementType type, bool isHighlighted) {
    if (isHighlighted) return Colors.orange;
    switch (type) {
      case ElementType.door: return Colors.green;
      case ElementType.rack: return Colors.blue;
      case ElementType.shelf: return Colors.brown;
      case ElementType.cashier: return Colors.purple;
      case ElementType.pathway: return Colors.blueGrey;
    }
  }

  Widget _buildPhysicalElement(MapElement el) {
    final bool isHighlighted = el.id == widget.highlightId;

    String displayLabel = el.label; 
    
    try {
      final assignedItem = widget.controller.allItems.firstWhere(
        (item) => item.locationId == el.id,
      );
      displayLabel = assignedItem.name; 
    } catch (e) {
    }

    Color baseColor = _getElementColor(el.type, isHighlighted);
    
    List<Widget> shelves = [];
    int numShelves = 4;
    double shelfSpacing = 15.0;
    bool isSolid = false;

    // Define different 3D characteristics for each element type
    switch (el.type) {
      case ElementType.pathway:
        numShelves = 1;
        shelfSpacing = 0;
        break;
      case ElementType.door:
        numShelves = 1;
        shelfSpacing = 0;
        break;
      case ElementType.cashier:
        numShelves = 10;
        shelfSpacing = 3.0; // Tightly stacked to look like a solid block
        isSolid = true;
        break;
      case ElementType.shelf:
      case ElementType.rack:
      default:
        numShelves = 4;     // Spaced out to look like actual shelving units
        shelfSpacing = 15.0;
        break;
    }

    for (int i = 0; i < numShelves; i++) {
      bool isTop = i == numShelves - 1;
      bool isBottom = i == 0;
      
      shelves.add(
        Transform(
          // Extrude by pushing it into the negative Z space relative to the floor
          transform: Matrix4.translationValues(0, 0, -i * shelfSpacing),
          child: Container(
            width: el.size.width,
            height: el.size.height,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(isSolid && !isTop ? 0.9 : 0.7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isTop || isBottom || !isSolid ? baseColor : Colors.transparent,
                width: 1,
              ),
              boxShadow: isBottom ? [BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(5, 5), blurRadius: 5)] : null,
            ),
            child: isTop
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        displayLabel, 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal, color: Colors.white),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      );
    }

    double topZ = -(numShelves - 1) * shelfSpacing;

    return Positioned(
      left: el.position.dx,
      top: el.position.dy,
      width: el.size.width,
      height: el.size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              if (widget.mode == MapMode.selection && widget.selectedItemId != null) {
                widget.controller.assignItemToLocation(widget.selectedItemId!, el.id);
                if (widget.onSelectionAssigned != null) {
                  widget.onSelectionAssigned!();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Item assigned to location!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                );
              }
            },
            onPanUpdate: widget.mode == MapMode.manage
                ? (details) {
                    setState(() {
                      el.position += details.delta;
                    });
                  }
                : null,
            onPanEnd: widget.mode == MapMode.manage
                ? (details) {
                    widget.controller.saveLayout();
                  }
                : null,
            onLongPress: widget.mode == MapMode.manage
                ? () {
                    setState(() {
                      widget.controller.storeLayout.remove(el);
                    });
                    widget.controller.saveLayout();
                  }
                : null,
            child: Container(
              child: Stack(
                clipBehavior: Clip.none,
                children: shelves,
              ),
            ),
          ),
          
          if (isHighlighted)
            Positioned.fill(
              child: Transform(
                transform: Matrix4.translationValues(0, 0, topZ - 20.0) // Hover above 3D object
                  ..rotateZ(45 * math.pi / 180)
                  ..rotateX(30 * math.pi / 180),
                alignment: Alignment.center,
                child: Align(
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: const Icon(LucideIcons.mapPin, color: Colors.orange, size: 28),
                      );
                    },
                  ),
                ),
              ),
            ),
            
          if (widget.mode == MapMode.manage)
            Positioned(
              right: -10,
              bottom: -10,
              child: Transform(
                transform: Matrix4.translationValues(0, 0, topZ), // Position resize handle at top of 3D object
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
                  onPanEnd: (details) {
                    widget.controller.saveLayout();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.open_in_full, size: 12, color: Colors.black),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
 
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          _buildDetailItem("Aisle", widget.location?.aisle ?? "N/A"),
          const SizedBox(width: 8),
          _buildDetailItem("Shelf", widget.location?.shelf.toString() ?? "N/A"),
          const SizedBox(width: 8),
          _buildDetailItem("Section", widget.location?.section ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.3)
      ..strokeWidth = 1;
      
    const double step = 50;
    
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}