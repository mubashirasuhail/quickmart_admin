import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_mart_admin/category.dart';
import 'package:quick_mart_admin/color.dart';
import 'package:quick_mart_admin/home.dart'; // Make sure this path is correct

class ViewCategory extends StatefulWidget {
  const ViewCategory({super.key});

  @override
  State<ViewCategory> createState() => _ViewCategoryState();
}

class _ViewCategoryState extends State<ViewCategory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600; // Determine if it's a web (larger screen) layout

    return SafeArea(
      child: Scaffold(
        appBar: isWeb
            ? null // No AppBar for web view (sidebar handles navigation)
            : AppBar(
                title: const Text("View Categories"),
               // backgroundColor: Colors.pinkAccent, // AppBar color
               // foregroundColor: Colors.white, // Text and icon color
                leading: Builder(
                  // Use Builder to get a context that can open the Scaffold's drawer
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(), // Open drawer on mobile
                  ),
                ),
                actions: [
                  // Move the "Add New Category" button to the AppBar for mobile view
                  if (!isWeb) // Only show in AppBar for mobile
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Category()),
                          );
                        },
                        label: const Text('Add', style: TextStyle(color: Colors.white)),
                        icon: const Icon(Icons.add, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, // Button background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        body: isWeb ? _buildWebDashboard(context) : _buildMobileView(), // Render appropriate view
        drawer: isWeb ? null : _buildAppDrawer(), // Render drawer for mobile
        // Keep the FloatingActionButton for web view for consistency or remove if not needed
        floatingActionButton: isWeb
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Category()),
                  );
                },
                label: const Text('Add New Category'),
                icon: const Icon(Icons.add),
                backgroundColor:Theme.of(context).primaryColor,
              )
            : null, // Hide FAB for mobile since button is in AppBar
      ),
    );
  }

  /// ---
  /// ## Web Dashboard View
  /// ---
  // Builds the main content area for web view (sidebar + content)
  Widget _buildWebDashboard(BuildContext context) {
    return Row(
      children: [
        // Sidebar for navigation on web
        Container(
          width: 200,
          color: Colors.pinkAccent, // Consistent sidebar color
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Image.asset("assets/images/supermarkt.jpg", // Placeholder image
                      height: 80, width: 80)),
              const SizedBox(height: 20),
              // Use _buildDrawerItem for consistency and icons
              _buildDrawerItem(context, Icons.home, "Home"),
              _buildDrawerItem(context, Icons.receipt, "Orders"),
              _buildDrawerItem(context, Icons.category, "Categories"),
              _buildDrawerItem(context, Icons.shopping_bag, "Product"),
            ],
          ),
        ),
        // Main content area (category list)
        Expanded(
          child: SingleChildScrollView(
            // Allows content to scroll if it overflows
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("All Categories",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildCategoryList(), // Displays the list of categories
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

  /// ---
  /// ## Mobile View
  /// ---
  // Builds the main content area for mobile view (category list)
  Widget _buildMobileView() {
    return SingleChildScrollView(
      // Allows content to scroll if it overflows
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("All Categories",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildCategoryList(), // Displays the list of categories
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---
  /// ## Category List Display
  /// ---
  // Builds the list of categories fetched from Firestore
  Widget _buildCategoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('category').snapshots(), // Listen to real-time changes
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading categories: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loading indicator
        }

        final categories = snapshot.data!.docs; // Get the list of category documents

        if (categories.isEmpty) {
          return const Center(child: Text('No categories added yet.')); // Message if no categories
        }

        return ListView.builder(
          shrinkWrap: true, // Important for nested scrollable widgets
          physics: const NeverScrollableScrollPhysics(), // Prevents nested scrolling
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index].data() as Map<String, dynamic>; // Get category data
            // final categoryId = category['id']; // categoryId is not directly used here, but kept for context
            final categoryName = category['name'];
            final categoryImage = category['image'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              elevation: 2,
              child: ListTile(
                leading: categoryImage != null && categoryImage.isNotEmpty
                    ? Image.network(
                        categoryImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50), // Fallback icon
                      )
                    : const Icon(Icons.category, size: 50), // Default icon if no image
                title: Text(categoryName),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Navigate to the Category page for editing
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Category(categoryData: category), // Pass data
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ---
  /// ## App Drawer (Mobile)
  /// ---
  // Builds the drawer for mobile view (like a home page drawer)
  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
           Container(
            height: 150, // Fixed height for the header section
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.darkgreen), // Consistent background, using AppColors.drkgreen as specified in the previous prompt if `color.dart` exists, otherwise using the RGB values
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo image with border radius
                ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Apply border radius
                  child: Image.asset(
                    'assets/images/iconlogo.png', // Ensure this path is correct
                    height: 80, // Adjust height as needed
                    width: 80, // Adjust width as needed
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback for when the image fails to load
                      return const Icon(Icons.error, size: 80, color: Colors.white);
                    },
                  ),
                ),
                const SizedBox(height: 10), // Spacing between image and text
                // App name text
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
          // Drawer items with icons
          _buildDrawerItem(context, Icons.home, "Home"),
          _buildDrawerItem(context, Icons.receipt, "Orders"),
          _buildDrawerItem(context, Icons.category, "Categories"),
          _buildDrawerItem(context, Icons.shopping_bag, "Products"),
          const Divider(), // A visual separator
         // _buildDrawerItem(context, Icons.settings, "Settings"),
          _buildDrawerItem(context, Icons.logout, "Logout"),
        ],
      ),
    );
  }

  /// ---
  /// ## Drawer/Sidebar Item Helper
  /// ---
  // Builds a list tile item for the drawer/sidebar
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 165, 165, 166)), // Icon for the drawer item
      title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 16)),
      onTap: () {
        // Close the drawer
        Navigator.pop(context);
        // Implement your navigation logic here based on the title or a more robust system
        // Example:
  if (title == "Home") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        } else if (title == "Categories") {
       
       }
        // etc.
      },
    );
  }
}