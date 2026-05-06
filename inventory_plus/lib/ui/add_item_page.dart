import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/inventory.dart';
import '../../logic/inventory_controller.dart';
import 'widgets/location_picker_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class AddItemPage extends StatefulWidget {
  final InventoryController controller;
  final Function(InventoryItem) onAdd;

  const AddItemPage({super.key, required this.controller, required this.onAdd});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();

  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _sizeController = TextEditingController();
  final _shelfLevelController = TextEditingController();
  final _binNumberController = TextEditingController();

  MapElement? _selectedMapElement;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _sizeController.dispose();
    _shelfLevelController.dispose();
    _binNumberController.dispose();
    super.dispose();
  }

  String? _imageUrl; 
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) setState(() {
                  _selectedImage = photo;
                  _imageUrl = photo.path;
                });
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) setState(() {
                  _selectedImage = image;
                  _imageUrl = image.path;
                });
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.link),
              title: const Text('Enter Image URL'),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Image URL"),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: "Paste link here"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                _imageUrl = urlController.text;
                _selectedImage = null;
              });
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  void _showLocationPicker() async {
    final MapElement? result = await showDialog<MapElement>(
      context: context,
      builder: (context) => LocationPickerDialog(controller: widget.controller),
    );

    if (result != null) {
      setState(() {
        _selectedMapElement = result;
      });
    }
  }

void _submitData() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isLoading = true);

  try {
    String? finalImageUrl = _imageUrl;

    // Check if _imageUrl is a local file path (and not a URL from the "Enter URL" option)
    if (_imageUrl != null && !_imageUrl!.startsWith('http')) {
      final String fileName = _nameController.text.isNotEmpty 
          ? '${_nameController.text}_image.jpg' 
          : 'product_image.jpg';

      // 1. Upload to Supabase Storage
      String? uploadedUrl;
      if (kIsWeb && _selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        uploadedUrl = await widget.controller.uploadImageBytes(bytes, fileName);
      } else {
        final File imageFile = File(_imageUrl!);
        uploadedUrl = await widget.controller.uploadProductImage(imageFile, fileName);
      }
      
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      } else {
        throw Exception("Image upload failed. Is your Supabase 'product_images' bucket created and public?");
      }
    }

    // 2. Create the item with the web-accessible URL[cite: 3, 4]
    final newItem = widget.controller.createNewItem(
      name: _nameController.text,
      sku: _skuController.text,
      price: _priceController.text,
      quantity: _quantityController.text,
      category: _categoryController.text,
      description: _descController.text,
      manufacturer: _manufacturerController.text,
      model: _modelController.text,
      productSize: _sizeController.text,
      shelfLevel: _shelfLevelController.text,
      binNumber: _binNumberController.text,
      mapLocationId: _selectedMapElement?.id,
      imageUrl: finalImageUrl ?? '', 
    );

    // 3. Save to the products table[cite: 3, 4]
    await widget.controller.addItem(newItem); 
    
    if (mounted) {
       widget.onAdd(newItem);
       Navigator.pop(context); 
    }
  } catch (e) {
    String errorMessage = "Error: $e";
    if (e is PostgrestException && e.code == '23505') {
      errorMessage = "An item with this SKU already exists! Please enter a unique SKU.";
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          "Add New Product",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageHeader(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("General Information"),
                          _buildTextField(
                            _nameController,
                            "Product Name",
                            LucideIcons.package,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _skuController,
                            "SKU / Barcode",
                            LucideIcons.hash,
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle("Store Placement"),
                          _buildLocationSelector(), 
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _shelfLevelController,
                                  "Shelf (e.g. Level 3)",
                                  LucideIcons.layers,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  _binNumberController,
                                  "Bin (e.g. B-12)",
                                  LucideIcons.box,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle("Technical Specifications"),
                          _buildTextField(
                            _manufacturerController,
                            "Brand / Manufacturer",
                            LucideIcons.factory,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _modelController,
                                  "Model #",
                                  LucideIcons.info,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  _sizeController,
                                  "Size (e.g. 12mm, XL)",
                                  LucideIcons.maximize,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          _buildSectionTitle("Pricing & Inventory"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _priceController,
                                  "Price (₱)",
                                  LucideIcons.banknote,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  _quantityController,
                                  "Initial Stock",
                                  LucideIcons.archive,
                                  isNumber: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _categoryController,
                            "Category",
                            LucideIcons.tag,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _descController,
                            "Detailed Description",
                            LucideIcons.fileText,
                            isMultiline: true,
                          ),

                          const SizedBox(height: 40),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 13,
            ),
          ),
          const Expanded(
            child: Divider(indent: 10, color: Colors.orange, thickness: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return InkWell(
      onTap: _showLocationPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.mapPin, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedMapElement != null
                    ? "Assigned to: ${_selectedMapElement!.label}"
                    : "No location selected (Tap to assign)",
                style: TextStyle(
                  color: _selectedMapElement != null
                      ? Colors.black87
                      : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            if (_selectedMapElement != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMapElement = null;
                  });
                },
                child: const Icon(Icons.cancel, color: Colors.red, size: 20),
              )
            else
              const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        color: const Color(0xFF1E293B),
        child: _imageUrl != null
            ? ((kIsWeb || _imageUrl!.startsWith('http'))
                ? Image.network(_imageUrl!, fit: BoxFit.cover)
                : Image.file(File(_imageUrl!), fit: BoxFit.cover))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.imagePlus, color: Colors.white.withOpacity(0.3), size: 40),
                  const SizedBox(height: 8),
                  Text("Tap to Add Product Photo", 
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Save to Database",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isNumber = false,
    bool isMultiline = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : (isMultiline ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiline ? 3 : 1,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }
}
