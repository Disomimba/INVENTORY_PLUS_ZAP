import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/inventory.dart';
import '../../logic/inventory_controller.dart';
import 'store_map.dart';

class ItemDetailPage extends StatefulWidget {
  final InventoryItem item;
  final InventoryController controller;
  final VoidCallback onBack;
  final Function(InventoryItem) onUpdate;
  final Function(String) onDelete;

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.controller,
    required this.onBack,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool _isEditing = false;
  bool _showMap = false;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _skuController;
  late TextEditingController _descController;
  late TextEditingController _manufacturerController;
  late TextEditingController _modelController;
  late TextEditingController _sizeController;
  late TextEditingController _shelfLevelController;
  late TextEditingController _binNumberController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: widget.item.price.toString());
    _stockController = TextEditingController(text: widget.item.quantity.toString());
    _skuController = TextEditingController(text: widget.item.sku);
    _descController = TextEditingController(text: widget.item.description);
    
    _manufacturerController = TextEditingController(text: widget.item.manufacturer ?? "");
    _modelController = TextEditingController(text: widget.item.model ?? "");
    _sizeController = TextEditingController(text: widget.item.productSize ?? "");
    _shelfLevelController = TextEditingController(text: widget.item.shelfLevel ?? "");
    _binNumberController = TextEditingController(text: widget.item.binNumber ?? "");
  }

  @override
  void didUpdateWidget(ItemDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      setState(() {
        _nameController.text = widget.item.name;
        _priceController.text = widget.item.price.toString();
        _stockController.text = widget.item.quantity.toString();
        _skuController.text = widget.item.sku;
        _descController.text = widget.item.description;
        _manufacturerController.text = widget.item.manufacturer ?? "";
        _modelController.text = widget.item.model ?? "";
        _sizeController.text = widget.item.productSize ?? "";
        _shelfLevelController.text = widget.item.shelfLevel ?? "";
        _binNumberController.text = widget.item.binNumber ?? "";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _descController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _sizeController.dispose();
    _shelfLevelController.dispose();
    _binNumberController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updated = widget.controller.prepareUpdatedItem(
      originalItem: widget.item,
      newName: _nameController.text,
      newSku: _skuController.text,
      newPrice: _priceController.text,
      newStock: _stockController.text,
      newDesc: _descController.text,
      locationId: widget.item.locationId,
      manufacturer: _manufacturerController.text,
      model: _modelController.text,
      productSize: _sizeController.text,
      shelfLevel: _shelfLevelController.text,
      binNumber: _binNumberController.text,
    );

    widget.onUpdate(updated);
    setState(() => _isEditing = false);
    _showSnackBar('Item updated successfully', Colors.green);
  }

  void _handleCheckout(int qty) {
    final updated = widget.controller.calculateCheckout(widget.item, qty);
    widget.onUpdate(updated);
    Navigator.pop(context);
    _showSnackBar('Checked out $qty item(s)', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard("Price", "₱${widget.item.price.toStringAsFixed(2)}", LucideIcons.banknote, Colors.green, _priceController),
                          const SizedBox(width: 12),
                          _buildStatCard("Stock", widget.item.quantity.toString(), LucideIcons.package, widget.item.quantity < 20 ? Colors.red : Colors.blue, _stockController),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildProductSpecsBox(),
                      const SizedBox(height: 24),
                      _buildDetailsBox(),
                      const SizedBox(height: 24),
                      _buildMapBox(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!_isEditing) _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: const Color(0xFF1E293B),
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
        onPressed: widget.onBack,
      ),
      actions: [
        if (_isEditing)
          IconButton(
            icon: const Icon(LucideIcons.check, color: Colors.greenAccent),
            onPressed: _handleSave,
          )
        else
          IconButton(
            icon: const Icon(LucideIcons.pencil, color: Colors.white, size: 20),
            onPressed: () => setState(() => _isEditing = true),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.item.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.category.toUpperCase(),
                    style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.item.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, TextEditingController controller) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  _isEditing
                      ? TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        )
                      : Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSpecsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(LucideIcons.info, size: 16, color: Colors.grey), SizedBox(width: 8), Text("Specifications", style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField("Manufacturer", _manufacturerController, widget.item.manufacturer ?? "N/A")),
              const SizedBox(width: 12),
              Expanded(child: _buildField("Model", _modelController, widget.item.model ?? "N/A")),
            ],
          ),
          const SizedBox(height: 16),
          _buildField("Product Size", _sizeController, widget.item.productSize ?? "Standard"),
        ],
      ),
    );
  }

  Widget _buildDetailsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(LucideIcons.tag, size: 16, color: Colors.grey), SizedBox(width: 8), Text("Inventory Info", style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          _buildField("SKU", _skuController, widget.item.sku),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildField("Shelf Level", _shelfLevelController, widget.item.shelfLevel ?? "Unassigned")),
              const SizedBox(width: 12),
              Expanded(child: _buildField("Bin Number", _binNumberController, widget.item.binNumber ?? "None")),
            ],
          ),
          const SizedBox(height: 16),
          _buildField("Description", _descController, widget.item.description, isMultiline: true),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String displayValue, {bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        _isEditing
            ? TextField(
                controller: controller,
                maxLines: isMultiline ? null : 1,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(displayValue.isEmpty ? "N/A" : displayValue, style: const TextStyle(fontSize: 14)),
              ),
      ],
    );
  }

  Widget _buildMapBox() {
    final bool hasMapId = widget.item.locationId != null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(children: [Icon(LucideIcons.mapPin, size: 16, color: Colors.orange), SizedBox(width: 8), Text("Store Location", style: TextStyle(fontWeight: FontWeight.bold))]),
            if (!_isEditing && hasMapId)
              TextButton(
                onPressed: () => setState(() => _showMap = !_showMap),
                child: Text(_showMap ? "Hide Map" : "View Map", style: const TextStyle(color: Colors.orange)),
              ),
            if (_isEditing)
              TextButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(LucideIcons.locateFixed, size: 14),
                label: Text(hasMapId ? "Change Rack" : "Set Rack"),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
          ],
        ),
        if (_showMap && !_isEditing && hasMapId)
          StoreMap(
            layout: widget.controller.storeLayout,
            layoutItems: widget.controller.allItems,
            highlightId: widget.item.locationId,
            itemName: widget.item.name,
          ),
        if (!hasMapId && !_isEditing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("No rack assigned. Tap 'Edit' to place this item.", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showDeleteDialog,
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text("Delete"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _showCheckoutSheet,
                icon: const Icon(LucideIcons.shoppingCart, size: 18),
                label: const Text("Checkout Item"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Remove \"${widget.item.name}\" from inventory?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete(widget.item.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutSheet() {
    int checkoutQty = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Checkout Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setModalState(() => checkoutQty = checkoutQty > 1 ? checkoutQty - 1 : 1),
                    icon: const Icon(Icons.remove_circle_outline, size: 40),
                  ),
                  Text("$checkoutQty", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setModalState(() => checkoutQty = checkoutQty < widget.item.quantity ? checkoutQty + 1 : checkoutQty),
                    icon: const Icon(Icons.add_circle_outline, size: 40),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => _handleCheckout(checkoutQty),
                child: const Text("Confirm Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLocationPicker() async {
    final MapElement? selectedRack = await showDialog<MapElement>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Rack"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: InteractiveViewer(
            constrained: false,
            child: SizedBox(
              width: 2000, height: 2000,
              child: Stack(
                children: widget.controller.storeLayout.map((el) {
                  return Positioned(
                    left: el.position.dx, top: el.position.dy,
                    width: el.size.width, height: el.size.height,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, el),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(4)),
                        child: Center(child: Text(el.label, style: const TextStyle(fontSize: 8))),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    if (selectedRack != null) {
      setState(() {
        widget.controller.assignItemToLocation(widget.item.id, selectedRack.id);
        final updatedItem = widget.item.copyWith(locationId: selectedRack.id);
        widget.onUpdate(updatedItem); 
      });
      _showSnackBar("Updated to ${selectedRack.label}", Colors.blue);
    }
  }
}