import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/inventory.dart';

class InventoryController {
  final SupabaseClient supabase = Supabase.instance.client;

  List<MapElement> storeLayout = [];
  List<InventoryItem> _items = [];
  String? activeLocationId;

  List<InventoryItem> get allItems => _items;

  Future<void> loadAppData(String userLocationId) async {
    activeLocationId = userLocationId;

    try {
      final productsResponse = await supabase
          .from('products')
          .select()
          .eq('location_id', userLocationId);

      final locationResponse = await supabase
          .from('locations')
          .select('layout_data')
          .eq('id', userLocationId)
          .single();

      _items = (productsResponse as List)
          .map((p) => InventoryItem.fromSupabase(p))
          .toList();

      if (locationResponse['layout_data'] != null) {
        final List<dynamic> layoutJson = locationResponse['layout_data'];
        storeLayout = layoutJson.map((el) => MapElement.fromJson(el)).toList();
      }

      print("Store Data Sync Complete: $userLocationId");
    } catch (e) {
      print("Error loading store data: $e");
      _items = [];
      storeLayout = [];
    }
  }

  Future<void> saveLayout() async {
    if (activeLocationId == null) return;

    try {
      final String encodedData = jsonEncode(
        storeLayout.map((el) => el.toJson()).toList(),
      );

      await supabase
          .from('locations')
          .update({'layout_data': jsonDecode(encodedData)})
          .eq('id', activeLocationId!);

      print("Layout saved to Supabase.");
    } catch (e) {
      print("Error saving layout: $e");
    }
  }

  Future<void> addItem(InventoryItem newItem) async {
    if (activeLocationId == null) {
      print("Error: No activeLocationId found. Are you logged in?");
      return;
    }

    try {
      final response = await supabase
          .from('products')
          .insert({
            'sku': newItem.sku,
            'product_name': newItem.name,
            'category': newItem.category,
            'product_price': newItem.price,
            'product_quantity': newItem.quantity,
            'description': newItem.description,
            'image_url': newItem.imageUrl,
            'location_id': activeLocationId, 
            'map_element_id': newItem.locationId, 
            'manufacturer': newItem.manufacturer,
            'model': newItem.model,
            'product_size': newItem.productSize,
            'shelf_level': newItem.shelfLevel,
            'bin_number': newItem.binNumber,
          })
          .select()
          .single(); 

      final savedItem = InventoryItem.fromSupabase(response);

      _items.add(savedItem);

      print("SUCCESS: Item saved to Supabase with ID: ${savedItem.id}");
    } catch (e) {
      print("DATABASE ERROR: $e");
      rethrow;
    }
  }

  Future<void> updateItem(InventoryItem updatedItem) async {
    try {
      await supabase
          .from('products')
          .update({
            'product_name': updatedItem.name,
            'sku': updatedItem.sku,
            'product_price': updatedItem.price,
            'product_quantity': updatedItem.quantity,
            'description': updatedItem.description,
            'manufacturer': updatedItem.manufacturer,
            'model': updatedItem.model,
            'product_size': updatedItem.productSize,
            'shelf_level': updatedItem.shelfLevel,
            'bin_number': updatedItem.binNumber,
            'map_element_id':
                updatedItem.locationId, 
          })
          .eq('id', updatedItem.id);

      final index = _items.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        _items[index] = updatedItem;
      }
    } catch (e) {
      print("Error updating item: $e");
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      _items.removeWhere((item) => item.id == id);
    } catch (e) {
      print("Error deleting item: $e");
    }
  }

  Future<void> assignItemToLocation(String itemId, String rackId) async {
    try {
      await supabase
          .from('products')
          .update({'map_element_id': rackId})
          .eq('id', itemId);

      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(locationId: rackId);
      }
    } catch (e) {
      print("Error assigning location: $e");
    }
  }

  List<InventoryItem> get unassignedItems =>
      _items.where((item) => item.locationId == null).toList();

  List<InventoryItem> filterInventory({
    required String query,
    required String category,
  }) {
    return _items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.sku.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == 'All' || item.category == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> getUniqueCategories() {
    final categories = _items.map((item) => item.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  InventoryItem prepareUpdatedItem({
    required InventoryItem originalItem,
    required String newName,
    required String newSku,
    required String newPrice,
    required String newStock,
    required String newDesc,
    String? locationId,
    String? manufacturer,
    String? model,
    String? productSize,
    String? shelfLevel,
    String? binNumber,
  }) {
    return originalItem.copyWith(
      name: newName,
      sku: newSku,
      price: double.tryParse(newPrice) ?? originalItem.price,
      quantity: int.tryParse(newStock) ?? originalItem.quantity,
      description: newDesc,
      locationId: locationId,
      manufacturer: manufacturer,
      model: model,
      productSize: productSize,
      shelfLevel: shelfLevel,
      binNumber: binNumber,
    );
  }

  InventoryItem calculateCheckout(InventoryItem item, int quantity) {
    return item.copyWith(quantity: (item.quantity - quantity).clamp(0, 999999));
  }

  InventoryItem createNewItem({
    required String name,
    required String sku,
    required String price,
    required String quantity,
    required String category,
    required String description,
    String? mapLocationId,
    String? manufacturer,
    String? model,
    String? productSize,
    String? shelfLevel,
    String? binNumber,
    String? imageUrl,
  }) {
    return InventoryItem(
      id: '',
      name: name,
      sku: sku,
      price: double.tryParse(price) ?? 0.0,
      quantity: int.tryParse(quantity) ?? 0,
      category: category,
      description: description,
      locationId: mapLocationId,
      manufacturer: manufacturer,
      model: model,
      productSize: productSize,
      shelfLevel: shelfLevel,
      binNumber: binNumber,
      imageUrl: imageUrl ?? '',
    );
  }

  InventoryItem? findItemByCode(String code) {
    try {
      return _items.firstWhere((item) => item.sku.trim() == code.trim());
    } catch (e) {
      return null;
    }
  }

  List<InventoryItem> searchInventory(String query) {
    if (query.isEmpty) return _items;

    final lowercaseQuery = query.toLowerCase();
    return _items.where((item) {
      return item.name.toLowerCase().contains(lowercaseQuery) ||
          item.sku.toLowerCase().contains(lowercaseQuery) ||
          item.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}
