import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/inventory.dart';

class StoreMap extends StatefulWidget {
  final List<MapElement> layout; 
  final List<InventoryItem> layoutItems; 
  final String? highlightId;    
  final ItemLocation? location; 
  final String itemName;

  const StoreMap({
    super.key,
    required this.layoutItems,
    required this.layout,
    this.highlightId,
    this.location,
    required this.itemName,
  });

  @override
  State<StoreMap> createState() => _StoreMapState();
}

class _StoreMapState extends State<StoreMap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          _buildLiveMapDisplay(),
          if (widget.location != null) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E293B), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Store Layout",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.itemName,
                        style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildLocationBadge(),
        ],
      ),
    );
  }

  Widget _buildLocationBadge() {
    if (widget.location == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text("UNASSIGNED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(widget.location!.aisle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text("Shelf ${widget.location!.shelf}", style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLiveMapDisplay() {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey.shade50,
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.1,
        maxScale: 2.5,
        child: SizedBox(
          width: 2000,
          height: 2000,
          child: Stack(
            children: [
              ...widget.layout.map((el) => _buildPhysicalElement(el)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalElement(MapElement el) {
  final bool isHighlighted = el.id == widget.highlightId;

  String displayLabel = el.label; 
  
  try {
    final assignedItem = widget.layoutItems.firstWhere(
      (item) => item.locationId == el.id,
    );
    displayLabel = assignedItem.name; 
  } catch (e) {
  }

  return Positioned(
    left: el.position.dx,
    top: el.position.dy,
    width: el.size.width,
    height: el.size.height,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isHighlighted ? Colors.orange : Colors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isHighlighted ? Colors.orange : Colors.blue.withOpacity(0.5),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                displayLabel, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted ? Colors.white : Colors.blue.shade900,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        
        if (isHighlighted)
          Positioned(
            top: -24,
            left: 0,
            right: 0,
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
      ],
    ),
  );
}
 
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}