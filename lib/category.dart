import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quick_mart_admin/button.dart';
import 'package:quick_mart_admin/color.dart'; // Ensure AppColors is correctly imported

class Category extends StatefulWidget {
  final Map<String, dynamic>? categoryData;

  const Category({super.key, this.categoryData});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  File? _selectedImage;
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String? _categoryError;
  String? _imageError;
  String? _existingImageUrl;
  String? _editingCategoryId;
  bool _isLoading = false; // Loading state variable

  @override
  void initState() {
    super.initState();
    if (widget.categoryData != null) {
      _editingCategoryId = widget.categoryData!['id'];
      _categoryController.text = widget.categoryData!['name'];
      _existingImageUrl = widget.categoryData!['image'];
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageError = null; // Clear image error when a new image is picked
        });
      }
    } catch (e) {
      // It's good practice to show a more user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selectedImage == null) return null;

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dt4enb1nt/upload'); // Replace with your Cloudinary upload URL
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'quickmart' // Replace with your upload preset
        ..files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        String imageUrl = jsonMap['secure_url'] as String;
        return imageUrl;
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Upload failed with status ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _saveCategory() async {
    // Input validation
    setState(() {
      _categoryError = _categoryController.text.trim().isEmpty // Use trim() to handle whitespace
          ? 'Category name is required.'
          : null;
      _imageError = (_selectedImage == null && _existingImageUrl == null)
          ? 'Please select an image.'
          : null;
    });

    if (_categoryError != null || _imageError != null) {
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final String categoryName = _categoryController.text.trim().toLowerCase(); // Trim and convert to lowercase

      // --- Check for Duplicate Category Name (only for new categories) ---
      if (_editingCategoryId == null) {
        final existingCategoryQuery = await _firestore
            .collection('category')
            .where('name', isEqualTo: categoryName)
            .limit(1)
            .get();

        if (existingCategoryQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category with this name already exists!')),
          );
          return; // Stop the save process
        }
      }
      // --- End Duplicate Check ---

      String? imageUrl = _existingImageUrl; // Start with the existing image URL

      // If a new image is selected, upload it
      if (_selectedImage != null) {
        imageUrl = await _uploadToCloudinary();
        if (imageUrl == null) {
          // If upload fails, stop and show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload new image')),
          );
          return;
        }
      }

      // Ensure an image URL is available (either new or existing)
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An image is required for the category')),
        );
        return;
      }

      if (_editingCategoryId == null) {
        // Add new category
        String categoryId = _firestore.collection('category').doc().id; // Generate a unique ID
        await _firestore.collection('category').doc(categoryId).set({
          'id': categoryId,
          'name': categoryName, // Save lowercase name
          'image': imageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category Added Successfully!')),
        );
      } else {
        // Update existing category
        await _firestore.collection('category').doc(_editingCategoryId).update({
          'name': categoryName, // Update lowercase name
          'image': imageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category Updated Successfully!')),
        );
      }

      // Clear fields and navigate back on success
      _categoryController.clear();
      setState(() {
        _selectedImage = null;
        _categoryError = null;
        _imageError = null;
        _existingImageUrl = null;
        _editingCategoryId = null; // Clear editing state
      });
      // Pop the current screen (Category form) to go back to the previous one
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving category: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading, regardless of success or error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600; // Define 'isWeb' based on screen width

    return Scaffold(
      appBar: isWeb // Only show AppBar on mobile view or if you want it on web too
          ? null // No AppBar for web, as the sidebar acts as primary navigation
          : AppBar(
              title: Text(_editingCategoryId == null ? "Add New Category" : "Edit Category"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: AppColors.darkgreen, // Using your custom color
              foregroundColor: Colors.white,
            ),
      body: isWeb ? _buildWebDashboard(context) : _buildMobileView(),
    );
  }

  Widget _buildWebDashboard(BuildContext context) {
    // This part assumes a navigation setup that is separate from this form.
    // The current implementation of _buildWebDashboard includes a sidebar
    // and then the form content. If this `Category` widget is displayed
    // as a standalone page in the web app, then the sidebar might be
    // part of a parent Scaffold, or you might need to adjust the structure.
    return Row(
      children: [
        // Sidebar (assuming this is part of your web layout)
        Container(
          width: 200,
          color: AppColors.drkgreen, // Using your custom color
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Image.asset("assets/images/supermarkt.jpg",
                      height: 80, width: 80)),
              const SizedBox(height: 20),
              // These need to navigate properly in a web context
              _buildSidebarItem(context, "Home"),
              _buildSidebarItem(context, "Order"),
              _buildSidebarItem(context, "Categories"),
              _buildSidebarItem(context, "Product"),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
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
                  child: Column( // Changed from Row to Column to stack elements more clearly for web form
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingCategoryId == null ? "Add New Category" : "Edit Category",
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20), // Increased spacing
                      TextField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: "Category Name",
                          errorText: _categoryError,
                        ),
                      ),
                      const SizedBox(height: 20), // Increased spacing
                      Row( // Keep pick image button and image side by side
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickImage, // Disable while loading
                              icon: const Icon(Icons.image),
                              label: const Text("Pick Image"),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Display image
                          _selectedImage != null
                              ? Image.file(_selectedImage!,
                                  width: 150, height: 100, fit: BoxFit.cover)
                              : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                  ? Image.network(_existingImageUrl!,
                                      width: 150,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                              width: 150,
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                  child: Text("Image Load Error"))),
                                    )
                                  : Container(
                                      width: 150,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Center(child: Text("No Image Selected")))),
                        ],
                      ),
                      if (_imageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_imageError!, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 30), // Increased spacing
                      SizedBox(
                        width: 200, // Fixed width for the button on web
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Mybutton(
                              buttonText: _editingCategoryId == null ? "Add Category" : "Update Category",
                              height: 60,
                              width: double.infinity, // Use infinity for MyButton to fill SizedBox
                              onTap: _isLoading ? null : _saveCategory,
                            ),
                            if (_isLoading)
                              const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((255 * 0.5).round()),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(3, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingCategoryId == null ? "Add New Category" : "Edit Category",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: "Category Name",
                    errorText: _categoryError,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage, // Disable while loading
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image"),
                ),
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_imageError!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Mybutton(
                      buttonText: _editingCategoryId == null ? "Add Category" : "Update Category",
                      height: 60,
                      width: double.infinity,
                      onTap: _isLoading ? null : _saveCategory, // Disable button when loading
                    ),
                    if (_isLoading)
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, width: 200, height: 180, fit: BoxFit.cover)
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? Image.network(_existingImageUrl!,
                              width: 200,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                  width: 200,
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Center(child: Text("Image Load Error"))),
                            )
                          : Container(
                              width: 200,
                              height: 180,
                              color: Colors.grey[300],
                              child: const Center(child: Text("No Image Selected")))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This sidebar item method is within the Category class, meaning it only affects
  // navigation when the Category screen is the current context. You'll likely
  // want a more robust navigation solution for a web dashboard.
  Widget _buildSidebarItem(BuildContext context, String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        // Handle navigation based on title.
        // For example, if "Home" is tapped, you might want to navigate to the HomeScreen.
        // This 'pop' might not be suitable for a general web dashboard navigation.
        Navigator.pop(context); // This pops the current route.
        // Consider using Navigator.pushReplacement or named routes for proper navigation:
        // if (title == "Home") {
        //   Navigator.pushReplacementNamed(context, '/home');
        // } else if (title == "Categories") {
        //   Navigator.pushReplacementNamed(context, '/categories_list'); // Assuming you have a route for category list
        // }
      },
    );
  }
}