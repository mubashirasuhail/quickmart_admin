import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:quick_mart_admin/product.dart';

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
        appBar: AppBar(title: const Text("Products")),
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
                childAspectRatio: 0.8,
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

  const ProductCard({super.key, required this.product, required this.confirmDelete});

  @override
  Widget build(BuildContext context) {
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
                  return Image.network(
                    product['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        provider.setLoading(product['image'], false);
                        return child;
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
                      return Image.asset('assets/images/placeholder.png', width: double.infinity, fit: BoxFit.cover);
                    },
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
                Text(product['productname'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("₹${product['price']}", style: const TextStyle(fontSize: 14, color: Colors.green)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Product(productId: product.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
}/*
class ProductView extends StatefulWidget {
  @override
  _ProductViewState createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    var snapshot = await FirebaseFirestore.instance.collection('product').get();
    setState(() {
      products = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  void _navigateToProductPage(String? productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Product()),
    );
    _fetchProducts(); // Refresh product list after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product List')),
      body: products.isEmpty
          ? Center(child: Text('No products found'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                return ListTile(
                  title: Text(product['productname']),
                  subtitle: Text("Price: ${product['price']}"),
                  leading: product['image'] != null
                      ? Image.network(product['image'], width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image),
                  onTap: () => _navigateToProductPage(product['id']), // Pass product ID to edit
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToProductPage(null), // Pass null for adding a new product
        child: Icon(Icons.add),
      ),
    );
  }
}
*/
