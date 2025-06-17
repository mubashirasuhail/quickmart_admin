import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:quick_mart_admin/color.dart';

import 'package:quick_mart_admin/product.dart'; // Make sure this path is correct

class ImageLoadingProvider extends ChangeNotifier {
  final Map<String, bool> _loadingStates = {};

  bool isLoading(String imageUrl) => _loadingStates[imageUrl] ?? true;

  void setLoading(String imageUrl, bool loading) {
    _loadingStates[imageUrl] = loading;
    notifyListeners();
  }
}

class ProductView extends StatelessWidget {
  const ProductView({super.key});

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance.collection('product').doc(productId).delete();
    } catch (e) {
      debugPrint("Error deleting product: $e");
    }
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _deleteProduct(productId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ImageLoadingProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Products"),
          actions: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Product(), // Correct way
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // Button background color
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255), // Button text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("Add Product"),
                ),
                const SizedBox(width: 8), // Add some spacing to the right of the button
              ],
            ),
          ],
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('product').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No Products Available"));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                // --- MODIFIED: Adjust childAspectRatio for larger images ---
                // A smaller childAspectRatio means the child is taller relative to its width.
                // 0.75 makes the cards taller, allowing images to appear larger.
                childAspectRatio: 0.65, // Was 0.8, changed to 0.75 for bigger images
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var product = snapshot.data!.docs[index];
                return ProductCard(product: product, confirmDelete: (ctx, id) => _confirmDelete(ctx, id));
              },
            );
          },
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot product;
  final Function(BuildContext, String) confirmDelete;
  final String _placeholderImage = 'assets/images/placeholder.png'; // Define the placeholder image path.

  const ProductCard({super.key, required this.product, required this.confirmDelete});

  // Helper method to safely get product price, handling String or num
  double _getProductPrice(Map<String, dynamic> productData) {
    final dynamic priceData = productData['price'];
    if (priceData is num) {
      return priceData.toDouble();
    } else if (priceData is String) {
      try {
        return double.parse(priceData);
      } catch (e) {
        debugPrint('Error parsing price string "${priceData}": $e');
        return 0.0;
      }
    }
    return 0.0; // Default for unexpected types
  }

  // Helper method to safely get product type (e.g., 'kg', 'unit')
  String _getProductType(Map<String, dynamic> productData) {
    return productData['type'] as String? ?? 'unit'; // Default to 'unit' if not found
  }

  @override
  Widget build(BuildContext context) {
    final String productName = product['productname'] as String? ?? 'N/A';
    final double productPrice = _getProductPrice(product.data() as Map<String, dynamic>);
    final String productType = _getProductType(product.data() as Map<String, dynamic>);


    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Consumer<ImageLoadingProvider>(
                builder: (context, provider, child) {
                  return Stack(
                    children: [
                      // Placeholder Image (always present, behind the network image)
                      Image.asset(
                        _placeholderImage,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover, // Use cover to fill space
                      ),
                      // Network Image (Actual Product Image)
                      Image.network(
                        product['image'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover, // Use cover to fill space
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            provider.setLoading(product['image'], false);
                            return child; // Image loaded, show it
                          }
                          provider.setLoading(product['image'], true);
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          provider.setLoading(product['image'], false);
                          // On error, let the placeholder image show through by returning an empty container or SizedBox.
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, // Prevent long names from overflowing
                  overflow: TextOverflow.ellipsis, // Add ellipsis if name is too long
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${productPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 14, color: AppColors.darkgreen), // Use your AppColors
                ),
                // --- NEW: Display product type ---
                Text(
                  "per $productType",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- Edit Button with Image ---
                    IconButton(
                      icon: Image.asset(
                        'assets/images/edit.png', // Your edit image path
                        width: 24, // Adjust size as needed
                        height: 24, // Keep width and height consistent for icons
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Product(productId: product.id),
                          ),
                        );
                      },
                    ),
                    // --- Delete Button with Image ---
                    IconButton(
                      icon: Image.asset(
                        'assets/images/delete.png', // Your delete image path
                        width: 24, // Adjust size as needed
                        height: 24, // Keep width and height consistent for icons
                      ),
                      onPressed: () => confirmDelete(context, product.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}