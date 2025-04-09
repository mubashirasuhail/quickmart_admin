import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_mart_admin/category.dart';
import 'package:quick_mart_admin/product.dart';
import 'package:quick_mart_admin/user_detail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _bannerImage;
  final List<Map<String, dynamic>> _topProducts = [];
  bool _isLoading = true; // To indicate loading state

  @override
  void initState() {
    super.initState();
    _loadTopProducts();
  }

  Future<void> _loadTopProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection("topproducts").get();
      _topProducts.clear();
      for (var doc in snapshot.docs) {
        _topProducts.add(doc.data());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading top products: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickBannerImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _bannerImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _showAddProductDialog() async {
    File? selectedImage;
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedFile =
                        await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setDialogState(() {
                        selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[300],
                    child: selectedImage == null
                        ? const Icon(Icons.image, size: 50)
                        : Image.file(selectedImage!, fit: BoxFit.cover),
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Enter Product Name"),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Enter Price"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedImage != null &&
                    nameController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) {
                  // Check if the product already exists
                  final existingProduct = _topProducts.firstWhere(
                    (p) => p['name'].toLowerCase() == nameController.text.toLowerCase(),
                    orElse: () => {}, // Return an empty map if not found
                  );

                  if (existingProduct.isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Product already exists in top products!"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Upload Image to Cloudinary
                  String imageUrl = await _uploadImageToCloudinary(selectedImage!);

                  // Save to Firestore
                  await FirebaseFirestore.instance.collection("topproducts").add({
                    "name": nameController.text,
                    "image": imageUrl,
                    "price": priceController.text,
                  });

                  // Update UI by reloading products
                  _loadTopProducts();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${nameController.text} added successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadImageToCloudinary(File image) async {
    const String cloudName = "dt4enb1nt";
    const String uploadPreset = "quickmart";

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    return jsonData['secure_url'];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              title: const Text("HomeScreen"),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickBannerImage,
              child: _buildBannerSection(isWeb),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Our Top Products",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTopProductsGrid(),
          ],
        ),
      ),
      drawer: isWeb ? null : _buildDrawer(context),
    );
  }

  Widget _buildBannerSection(bool isWeb) {
    return Center(
      child: Container(
        height: 200,
        width: isWeb ? 800 : double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          image: _bannerImage != null
              ? DecorationImage(image: FileImage(_bannerImage!), fit: BoxFit.cover)
              : null,
        ),
        child: _bannerImage == null
            ? const Center(child: Text("Tap to add banner image"))
            : null,
      ),
    );
  }

  Widget _buildTopProductsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: _topProducts.length + 1,
      itemBuilder: (context, index) {
        if (index == _topProducts.length) {
          return GestureDetector(
            onTap: _showAddProductDialog,
            child: Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.add, size: 50),
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: Image.network(_topProducts[index]['image'], fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (BuildContext context, Object error,
                      StackTrace? stackTrace) {
                    return const Center(child: Icon(Icons.error_outline));
                  }),
            ),
            Text(
              _topProducts[index]['name'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Price: ${_topProducts[index]['price']}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueGrey),
            child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _buildDrawerItem(context, "Home"),
          _buildDrawerItem(context, "Orders"),
          _buildDrawerItem(context, "Categories"),
          _buildDrawerItem(context, "Product"),
           _buildDrawerItem(context, "Users"),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (title == "Categories") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Category()));
        } else if (title == "Home") {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        } else if (title == "Orders") {
          // Add your orders screen navigation
        } else if (title == "Product") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Product()));
        }
         else if (title == "Users") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const UserDetailsPage()));
        }
      },
    );
  }
}