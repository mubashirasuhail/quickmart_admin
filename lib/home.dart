// lib/home.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quick_mart_admin/category.dart'; // Assuming Category page exists
import 'package:quick_mart_admin/color.dart'; // Ensure this file defines AppColors.drkgreen
import 'package:quick_mart_admin/dashboard.dart';
import 'package:quick_mart_admin/edit_offer.dart';
import 'package:quick_mart_admin/login.dart'; // Assuming LoginScreen exists
import 'package:quick_mart_admin/order.dart'; // Assuming OrderDetails exists
import 'package:quick_mart_admin/product.dart'; // Assuming Product page exists
import 'package:quick_mart_admin/user_detail.dart'; // Assuming UserDetailsPage exists
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quick_mart_admin/view%20category.dart'; // Assuming ViewCategory exists
import 'package:quick_mart_admin/viewproduct.dart'; // Assuming ProductView exists
import 'dart:developer' as developer; // For better logging

// Ensure main.dart is calling runApp with MyApp, which then handles initial navigation
// This `main()` function here is just for standalone testing if needed,
// but it should not be the primary entry point if you have a main.dart that calls MyApp.
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: HomeScreen()));
}
*/

// --- NEW WIDGET FOR REUSABLE SIDEBAR/DRAWER CONTENT ---
// This widget encapsulates the common content for both the mobile drawer and the web sidebar.
class _AppSidebarContent extends StatelessWidget {
  final BuildContext parentContext;
  final double? width; // Optional width for the sidebar/drawer

  const _AppSidebarContent({
    super.key,
    required this.parentContext,
    this.width,
  });

  // Helper method to build individual navigation list tiles
  // Now accepts a specific context for the ListTile, ensuring it's a descendant of a Scaffold.
  Widget _buildSidebarItem(
      BuildContext itemContext, String title, IconData icon, Widget targetPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 134, 133, 133)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          developer.log('Tapped on $title (Sidebar)', name: 'Navigation');

          // Close the drawer if it's open (relevant for mobile)
          if (Scaffold.of(itemContext).hasDrawer &&
              Scaffold.of(itemContext).isDrawerOpen) {
            Navigator.pop(itemContext);
          }
          // Navigate to the target page
          try {
            if (title == "Home") {
              // Only pushReplacement if not already on Home to avoid re-stacking
              if (ModalRoute.of(parentContext)?.settings.name != '/home' &&
                  !(parentContext.findAncestorWidgetOfExactType<HomeScreen>() != null)) {
                Navigator.pushReplacement(parentContext,
                    MaterialPageRoute(builder: (context) => targetPage));
              } else {
                developer.log('Already on Home screen, not navigating.',
                    name: 'Navigation');
              }
            } else {
              Navigator.push(parentContext,
                  MaterialPageRoute(builder: (context) => targetPage));
            }
          } catch (e) {
            developer.log('Error during navigation to $title: $e',
                name: 'NavigationError', error: e);
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Error navigating to $title: $e')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.darkgreen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/iconlogo.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error,
                          size: 80, color: Colors.white);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Quickmart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildSidebarItem(context, "Home", Icons.home, const HomeScreen()),
          _buildSidebarItem(
              context, "Order", Icons.receipt_long, const OrderDetails()),
          _buildSidebarItem(
              context, "Categories", Icons.category, const ViewCategory()),
          _buildSidebarItem(
              context, "Product", Icons.shopping_bag, const ProductView()),
          //  _buildSidebarItem(
          // context, "Manage Offer Types", Icons.local_offer, const ViewOfferTypesScreen()),
          _buildSidebarItem(
              context, "Users", Icons.people, const UserDetailsPage()),
          _buildSidebarItem(
              context, "Revenue Dashboard", Icons.analytics, const AdminDashboardScreen()),
          const Divider(),
          // Logout Button with Confirmation Dialog
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red),
            ),
            onTap: () async {
              developer.log('Tapped on Logout (Sidebar)', name: 'Navigation');

              if (Scaffold.of(context).hasDrawer &&
                  Scaffold.of(context).isDrawerOpen) {
                Navigator.pop(context);
              }

              final bool? confirmLogout = await showDialog<bool>(
                context: parentContext,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                try {
                  await FirebaseAuth.instance.signOut();
                  // Use pushAndRemoveUntil to clear the stack and go to LoginScreen
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  developer.log('Error during logout: $e',
                      name: 'AuthError', error: e);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text("Error logging out: $e")),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingBanners = true; // Keep this for individual section loading indication
  Map<String, List<Map<String, dynamic>>> _productsByOfferType = {};
  bool _isLoadingProducts = true; // Keep this for individual section loading indication
  final String _placeholderImage = 'assets/images/placeholder.png';

  // Master loading flag for the entire screen
  bool _isScreenLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isScreenLoading = true; // Set master loading to true at the start
      _isLoadingBanners = true;
      _isLoadingProducts = true;
    });

    // Use Future.wait to load data concurrently
    await Future.wait([
      _loadBanners(),
      _loadProductsByOfferType(),
    ]);

    setState(() {
      _isScreenLoading = false; // Set master loading to false when all data is loaded
      _isLoadingBanners = false; // Also set individual flags to false
      _isLoadingProducts = false;
    });
  }

  Future<void> _loadBanners() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('banners')
              .orderBy('timestamp', descending: false)
              .get();

      if (mounted) { // Check if the widget is still in the tree before setState
        setState(() {
          _banners =
              snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        });
      }
    } catch (e) {
      developer.log('Error loading banners: $e', name: 'BannerLoad', error: e);
      _showSnackBar("Error loading banners: $e", Colors.red);
    }
  }

  Future<void> _pickAndUploadBannerImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _showSnackBar("Uploading new banner...", Colors.blue);
      try {
        String cloudinaryUrl =
            await _uploadImageToCloudinary(File(pickedFile.path));
        await _saveNewBannerUrlToFirestore(cloudinaryUrl);
        await _loadBanners(); // Reload banners after adding a new one
        _showSnackBar(
            "New banner uploaded and saved successfully!", Colors.green);
      } catch (e) {
        developer.log('Error during banner upload/save: $e',
            name: 'BannerUpload', error: e);
        _showSnackBar("Error uploading banner: $e", Colors.red);
      }
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content:
                const Text('Are you sure you want to delete this banner?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      _showSnackBar("Deleting banner...", Colors.blue);
      try {
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(bannerId)
            .delete();
        _showSnackBar("Banner deleted successfully!", Colors.green);
        await _loadBanners(); // Reload banners after deletion
      } catch (e) {
        developer.log('Error deleting banner: $e',
            name: 'BannerDelete', error: e);
        _showSnackBar("Error deleting banner: $e", Colors.red);
      }
    }
  }

  Future<void> _loadProductsByOfferType() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection("product").get();

      final Map<String, List<Map<String, dynamic>>> tempProductsByOfferType = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String? offerType = data['offerType'] as String?;

        if (offerType == null || offerType.trim().isEmpty) {
          continue; // Skip products without an offer type
        }

        // Normalize the offerType to lowercase for consistent grouping
        final String normalizedOfferType = offerType.trim().toLowerCase();

        // Skip "normal offer type" or "normal" after normalization
        if (normalizedOfferType == "normal offer type" ||
            normalizedOfferType == "normal") {
          continue;
        }

        // Use the normalized offerType as the key for the map
        if (!tempProductsByOfferType.containsKey(normalizedOfferType)) {
          tempProductsByOfferType[normalizedOfferType] = [];
        }
        tempProductsByOfferType[normalizedOfferType]!.add({...data, 'id': doc.id});
      }

      tempProductsByOfferType.forEach((key, value) {
        value.sort((a, b) => (a['productname'] as String? ?? '')
            .compareTo(b['productname'] as String? ?? ''));
      });

      if (mounted) {
        setState(() {
          _productsByOfferType = tempProductsByOfferType;
        });
      }
    } catch (e) {
      developer.log('Error loading products: $e',
          name: 'ProductLoad', error: e);
      _showSnackBar("Error loading products: $e", Colors.red);
    }
  }


  Future<void> _deleteProduct(String productId, String productName) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(
                'Are you sure you want to delete "$productName"? This action is permanent and cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      _showSnackBar("Deleting $productName...", Colors.blue);
      try {
        await FirebaseFirestore.instance
            .collection('product')
            .doc(productId)
            .delete();
        _showSnackBar("$productName deleted successfully!", Colors.green);
        _loadProductsByOfferType(); // Reload products after deletion
      } catch (e) {
        developer.log('Error deleting product $productId: $e',
            name: 'ProductDelete', error: e);
        _showSnackBar("Error deleting $productName: $e", Colors.red);
      }
    }
  }

  Future<String> _uploadImageToCloudinary(File image) async {
    const String cloudName = "dt4enb1nt";
    const String uploadPreset = "quickmart";

    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonData['secure_url'];
    } else {
      developer.log('Cloudinary upload failed: ${jsonData['error']}',
          name: 'CloudinaryError');
      throw Exception(
          'Failed to upload image to Cloudinary: ${jsonData['error']['message'] ?? 'Unknown error'}');
    }
  }

  Future<void> _saveNewBannerUrlToFirestore(String imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('banners').add({
        'url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error saving new banner URL to Firestore: $e',
          name: 'FirestoreSave', error: e);
      throw Exception('Failed to save new banner URL to Firestore: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return SafeArea(
      child: Scaffold(
        appBar: isWeb
            ? null
            : AppBar(
                title: const Text("Quick Mart Admin", style: TextStyle(
                color: Colors
                    .white, // White text color for contrast on green background
                fontSize: 22,
                fontFamily: 'Libre',// Adjust font size as needed
                fontWeight: FontWeight.bold,
              ),),
                leading: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  },
                ),
                backgroundColor: AppColors.darkgreen,
                foregroundColor: Colors.white,
              ),
        body: _isScreenLoading // Check the master loading flag
            ? const Center( // Center the CircularProgressIndicator
                child: CircularProgressIndicator(),
              )
            : (isWeb
                ? _buildWebDashboard(context)
                : _buildMobileDashboard()),
        drawer: isWeb ? null : _buildDrawer(context),
      ),
    );
  }

  // --- Widget Building Methods ---
  Widget _buildMainContent(bool isWeb) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBannerSection(isWeb),
          const SizedBox(height: 20),
          // Here, the individual loading indicators for products will still work if needed
          // But the main screen won't be shown until _isScreenLoading is false
          if (_productsByOfferType.isEmpty && !_isLoadingProducts) // Only show if not loading and empty
            const Center(child: Text("No products found in offer types."))
          else if (!_isLoadingProducts) // Only show content if not individually loading
            Column(
              children: _productsByOfferType.entries.map((entry) {
                final String offerTypeTitle = entry.key; // This will now be the normalized key
                final List<Map<String, dynamic>> products = entry.value;
                return _buildProductOfferSection(
                    // You might want to capitalize the first letter for display
                    offerTypeTitle.isNotEmpty
                        ? '${offerTypeTitle[0].toUpperCase()}${offerTypeTitle.substring(1)}'
                        : offerTypeTitle,
                    products);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDashboard() {
    return _buildMainContent(false);
  }

  Widget _buildWebDashboard(BuildContext context) {
    return Row(
      children: [
        _AppSidebarContent(
          parentContext: context,
          width: MediaQuery.of(context).size.width * 0.2,
        ),
        Expanded(
          child: _buildMainContent(true),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: _AppSidebarContent(parentContext: context),
    );
  }

  Widget _buildBannerSection(bool isWeb) {
    // No need for _isLoadingBanners check here directly controlling visibility
    // since _isScreenLoading already handles the main visibility.
    // However, if you want a separate loader for just this section *after* the main screen loads,
    // you could keep the check. For a unified "all loaded" approach, this is fine.
    return SizedBox(
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Home Banners",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _banners.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _banners.length) {
                        return GestureDetector(
                          onTap: () {
                            developer.log('Tapped on Add New Banner',
                                name: 'BannerSection');
                            _pickAndUploadBannerImage();
                          },
                          child: Container(
                            width: isWeb ? 300 : 250,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Add New Banner",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final banner = _banners[index];
                      final String bannerUrl = banner['url'] as String? ?? '';
                      final String bannerId = banner['id'] as String? ?? '';

                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: isWeb ? 300 : 250,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              image: bannerUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(bannerUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: bannerUrl.isEmpty
                                ? Center(
                                    child: Image.asset(
                                      _placeholderImage,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  )
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: IconButton(
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.red, size: 28),
                              onPressed: () => _deleteBanner(bannerId),
                              tooltip: 'Delete Banner',
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.white70,
                                  shape: const CircleBorder()),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildProductOfferSection(
      String title, List<Map<String, dynamic>> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.all(8.0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: products.length + 1,
          itemBuilder: (context, index) {
            if (index == products.length) {
              return GestureDetector(
                onTap: () {
                  developer.log('Tapped on Add Product button for section: $title', name: 'ProductSection');
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Product(),
                      ),
                    ).then((_) {
                      // Reload products after returning from Product creation/edit
                      _loadProductsByOfferType();
                    });
                  } catch (e) {
                    developer.log('Error during navigation to Product (add): $e', name: 'NavigationError', error: e);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error navigating to Product (add): $e')),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 50, color: Colors.grey),
                  ),
                ),
              );
            }
            final product = products[index];
            final String productId = product['id'] as String? ?? '';
            final String productName = product['productname'] as String? ?? 'N/A';
            final String productImage = product['image'] as String? ?? '';

            return GestureDetector(
              onTap: () {
                developer.log('Tapped on product: $productName (ID: $productId)', name: 'ProductSection');
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Product(
                          productId: productId), // Pass productId to edit existing product
                    ),
                  ).then((_) {
                    // Reload products after returning from Product creation/edit
                    _loadProductsByOfferType();
                  });
                } catch (e) {
                  developer.log('Error during navigation to Product (edit): $e', name: 'NavigationError', error: e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error navigating to Product (edit): $e')),
                  );
                }
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: Image.asset(
                                _placeholderImage,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          if (productImage.isNotEmpty)
                            Image.network(
                              productImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (BuildContext context, Object error,
                                  StackTrace? stackTrace) {
                                developer.log(
                                    'Error loading product image for $productName: $error',
                                    error: error,
                                    stackTrace: stackTrace);
                                return Center(
                                  child: Image.asset(
                                    _placeholderImage,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.red, size: 24),
                              onPressed: () =>
                                  _deleteProduct(productId, productName),
                              tooltip: 'Delete Product',
                              style: IconButton.styleFrom(
                                  backgroundColor: Colors.white70,
                                  shape: const CircleBorder()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        productName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}