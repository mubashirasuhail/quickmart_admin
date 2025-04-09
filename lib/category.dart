import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  File? _selectedImage;
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker(); // For picking images

  String? _categoryError;
  String? _imageError;

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageError = null; // Clear image error if selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Upload image to Cloudinary
  Future<String?> _uploadToCloudinary() async {
    if (_selectedImage == null) return null;

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dt4enb1nt/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] =
            'quickmart' // Ensure this preset exists in Cloudinary
        ..files.add(
            await http.MultipartFile.fromPath('file', _selectedImage!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        String imageUrl = jsonMap['secure_url'] as String;

        return imageUrl;
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  // Add category to Firestore
  Future<void> _addCategory() async {
    setState(() {
      _categoryError = _categoryController.text.isEmpty
          ? 'Category name is required.'
          : null;
      _imageError = _selectedImage == null ? 'Please select an image.' : null;
    });

    if (_categoryError != null || _imageError != null) {
      return; // Return early if there are validation errors
    }

    try {
      // Upload image to Cloudinary and get the image URL
      String? imageUrl = await _uploadToCloudinary();
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        return;
      }

      // Add category info to Firestore
      String categoryId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('category').doc(categoryId).set({
        'id': categoryId,
        'name': _categoryController.text,
        'image': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category Added Successfully!')),
      );
      _categoryController.clear();
      setState(() {
        _selectedImage = null;
        _categoryError = null;
        _imageError = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              title: const Text("Category"),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      body: isWeb ? _buildWebDashboard(context) : _buildMobileView(),
      drawer: isWeb ? null : _buildDrawer(context),
    );
  }

  Widget _buildWebDashboard(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 200,
          color: Colors.pinkAccent,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Image.asset("assets/images/supermarkt.jpg",
                      height: 80, width: 80)),
              const SizedBox(height: 20),
              _buildSidebarItem(context, "Home"),
              _buildSidebarItem(context, "Order"),
              _buildSidebarItem(context, "Categories"),
              _buildSidebarItem(context, "Product"),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withAlpha((255 * 0.5).round()),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(3, 3)),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Category",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: "Category",
                              errorText: _categoryError,
                            )),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text("Pick Image")),
                        if (_imageError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_imageError!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: _addCategory,
                            child: const Text("Add Category")),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  _selectedImage != null
                      ? Image.file(_selectedImage!,
                          width: 200, height: 180, fit: BoxFit.cover)
                      : Container(
                          width: 200,
                          height: 180,
                          color: Colors.grey[300],
                          child:
                              const Center(child: Text("No Image Selected"))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withAlpha((255 * 0.5).round()),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(3, 3)),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Category",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: "Category",
                    errorText: _categoryError,
                  )),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image")),
              if (_imageError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_imageError!,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: _addCategory, child: const Text("Add Category")),
              const SizedBox(height: 20),
              Center(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!,
                          width: 200, height: 180, fit: BoxFit.cover)
                      : Container(
                          width: 200,
                          height: 180,
                          color: Colors.grey[300],
                          child:
                              const Center(child: Text("No Image Selected")))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueGrey),
            child: const Text("Menu",
                style: TextStyle(color: Colors.white, fontSize: 24))),
        _buildDrawerItem(context, "Home"),
        _buildDrawerItem(context, "Order"),
        _buildDrawerItem(context, "Categories"),
        _buildDrawerItem(context, "Product"),
      ]),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        // Navigation Logic
      },
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title) {
    return ListTile(
      title: Text(title),
      onTap: () {
        // Navigation Logic
      },
    );
  }
}
