import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:quick_mart_admin/color.dart';
import 'package:quick_mart_admin/viewproduct.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Product extends StatefulWidget {
  final String? productId;
  const Product({super.key, this.productId});

  @override
  State<Product> createState() => _ProductState();
}

class _ProductState extends State<Product> {
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  File? _mainImage;
  final List<File?> _additionalImages = [];
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _weightType;
  String? _category;
  final _formKey = GlobalKey<FormState>();

  String? _offerType;
  final TextEditingController _newOfferTypeController = TextEditingController();
  List<String> _offerTypes = [];

  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _getCategories();
    _loadOfferTypesFromPrefs(); // Load saved offer types and set initial selection
    if (widget.productId != null) {
      _fetchProductData(widget.productId!); // Fetch data if editing
    }
  }

  Future<void> _loadOfferTypesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedOfferTypes = prefs.getStringList('offerTypes');
    setState(() {
      if (savedOfferTypes != null && savedOfferTypes.isNotEmpty) {
        _offerTypes = savedOfferTypes;
      } else {
        // If no offer types are saved yet, initialize with default ones
        _offerTypes = ["Normal", "Top Product"];
      }

      // --- NEW LOGIC HERE ---
      // Ensure "Normal" is always present in the list, adding it if missing
      if (!_offerTypes.contains("Normal")) {
        _offerTypes.insert(0, "Normal"); 
      }
      // Ensure "Top Product" is also present if we consider it a fixed default
      if (!_offerTypes.contains("Top Product")) {
        _offerTypes.add("Top Product");
      }


      _offerType = "Normal";
      // --- END NEW LOGIC ---
    });
  }

  Future<void> _saveOfferTypesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('offerTypes', _offerTypes);
    developer.log('Offer Types saved: $_offerTypes', name: 'SharedPreferences');
  }

  void _addOfferTypeAndSave() {
    final String value = _newOfferTypeController.text.trim();
    if (value.isNotEmpty) {
      if (!_offerTypes.contains(value)) {
        setState(() {
          _offerTypes.add(value);
          _newOfferTypeController.clear();
          _offerType = value; // Select the newly added type
        });
        _saveOfferTypesToPrefs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer Type "$value" added and saved.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer Type "$value" already exists.')),
        );
        _newOfferTypeController.clear();
      }
    }
  }

  Future<void> _fetchProductData(String productId) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .get();
      if (doc.exists) {
        setState(() {
          _offerType = doc['offerType']; // This will override the default "Normal" if editing
          _productNameController.text = doc['productname'];
          _priceController.text = doc['price'];
          _descriptionController.text = doc['description'];
          _category = doc['category'];
          _weightType = doc['type'];
          if (doc['image'] != null && doc['image'].toString().isNotEmpty) {
            _loadMainImageFromUrl(doc['image']);
          }
          if (doc['moreImages'] != null && doc['moreImages'].length > 0) {
            _loadAdditionalImagesFromUrl(doc['moreImages']);
          }
        });
      }
    } catch (e) {
      developer.log('Error fetching product: $e', name: 'FirebaseFetch');
    }
  }

  Future<void> _loadMainImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mainImage.png');
      await file.writeAsBytes(response.bodyBytes);
      setState(() {
        _mainImage = file;
      });
    } catch (e) {
      developer.log('Error downloading image: $e', name: 'MyImageDownloader');
    }
  }

  Future<void> _loadAdditionalImagesFromUrl(List<dynamic> urls) async {
    try {
      for (String url in urls) {
        final response = await http.get(Uri.parse(url));
        final tempDir = await getTemporaryDirectory();
        final file =
            File('${tempDir.path}/additionalImage_${urls.indexOf(url)}.png');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _additionalImages.add(file);
        });
      }
    } catch (e) {
      developer.log("Error loading additional images from url: $e",
          name: "ImageLoading");
    }
  }

  Future<void> _getCategories() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('category').get();
      setState(() {
        categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      developer.log('Error fetching categories: $e', name: 'CategoryLoading');
    }
  }

  Future<void> _pickMainImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mainImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickAdditionalImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _additionalImages
            .addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dt4enb1nt/image/upload'),
      );
      request.fields['upload_preset'] = 'quickmart';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = json.decode(responseData.body);
        return data['secure_url'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
      });

      String? mainImageUrl;
      if (_mainImage != null) {
        mainImageUrl = await _uploadImage(_mainImage!);
      } else if (widget.productId != null && _mainImage == null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("product")
            .doc(widget.productId)
            .get();
        mainImageUrl = doc['image'];
      }

      List<String> additionalImageUrls = [];
      for (var image in _additionalImages) {
        if (image != null) {
          String? imageUrl = await _uploadImage(image);
          if (imageUrl != null) {
            additionalImageUrls.add(imageUrl);
          }
        }
      }
      if (widget.productId != null && _additionalImages.isEmpty) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("product")
            .doc(widget.productId)
            .get();
        additionalImageUrls = List<String>.from(doc['moreImages'] ?? []);
      }

      try {
        Map<String, dynamic> productData = {
          'category': _category,
          'description': _descriptionController.text,
          'image': mainImageUrl ?? '',
          'price': _priceController.text,
          'productname': _productNameController.text,
          'type': _weightType,
          'moreImages': additionalImageUrls,
          'offerType': _offerType ?? "Normal",
        };

        if (widget.productId != null) {
          await FirebaseFirestore.instance
              .collection('product')
              .doc(widget.productId!)
              .update(productData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('product')
              .add(productData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
        }

        setState(() {
          _descriptionController.clear();
          _productNameController.clear();
          _priceController.clear();
          _mainImage = null;
          _additionalImages.clear();
          _category = null;
          _weightType = null;
          // After adding/updating, reset selected offer type to "Normal"
          _offerType = "Normal";
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _productNameController.dispose();
    _priceController.dispose();
    _newOfferTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(
              child: isWeb ? _buildWebDashboard(context) : _buildMobileView(),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
        drawer: isWeb ? null : _buildDrawer(context),
      ),
    );
  }

  Widget _buildWebDashboard(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 250,
          color: const Color.fromARGB(255, 239, 129, 157),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset("assets/images/supermarkt.jpg",
                    height: 80, width: 80),
              ),
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
                    offset: const Offset(3, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ProductView()),
                                  );
                                },
                                child: const Text("View Product"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text("Add Product",
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _newOfferTypeController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Add New Offer Type",
                                    hintText: "e.g., Seasonal, Featured",
                                  ),
                                  onFieldSubmitted: (value) {
                                    _addOfferTypeAndSave();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addOfferTypeAndSave,
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text("Offer Type:",
                              style: TextStyle(fontSize: 16)),
                          Row(
                            children: _offerTypes.map((type) {
                              return Expanded(
                                child: RadioListTile<String>(
                                  title: Text(type),
                                  value: type,
                                  groupValue: _offerType,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _offerType = value;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Select Category",
                            ),
                            value: _category,
                            onChanged: (value) {
                              setState(() {
                                _category = value;
                              });
                            },
                            items: categories
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _productNameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Product Name",
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter a product name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Price",
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter a price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Select Weight Type",
                            ),
                            value: _weightType,
                            onChanged: (value) {
                              setState(() {
                                _weightType = value;
                              });
                            },
                            items: <String>["Kg", "g", "Unit", "Litre"]
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a weight type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _pickMainImage,
                            icon: const Icon(Icons.image),
                            label: const Text("Pick Main Image"),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _pickAdditionalImages,
                            icon: const Icon(Icons.image),
                            label: const Text("Pick Additional Images"),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Product Description",
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _addProduct,
                            child: Text(widget.productId != null
                                ? "Update Product"
                                : "Add Product"),
                          ),
                          
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        const SizedBox(height: 30),
                        _mainImage != null
                            ? Image.file(_mainImage!,
                                width: 200, height: 180, fit: BoxFit.cover)
                            : Container(
                                width: 200,
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(
                                    child: Text("No Main Image Selected"))),
                        const SizedBox(height: 20),
                        _additionalImages.isNotEmpty
                            ? Column(
                                children: _additionalImages.map((image) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Image.file(image!,
                                        width: 150,
                                        height: 120,
                                        fit: BoxFit.cover),
                                  );
                                }).toList(),
                              )
                            : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                  width: 150,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Center(
                                      child: Text("No Additional Images Selected"))),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView() {
    return Center(
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
              offset: const Offset(3, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Product",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProductView()),
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
                    child: const Text("View Product"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Add Product", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newOfferTypeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Add New Offer Type",
                        hintText: "e.g., Seasonal, Featured",
                      ),
                      onFieldSubmitted: (value) {
                        _addOfferTypeAndSave();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addOfferTypeAndSave,
                    child: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Offer Type:", style: TextStyle(fontSize: 16)),
              Column(
                children: _offerTypes.map((type) {
                  return RadioListTile<String>(
                    title: Text(type),
                    value: type,
                    groupValue: _offerType,
                    onChanged: (String? value) {
                      setState(() {
                        _offerType = value;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Select Category",
                ),
                value: _category,
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
                items: categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Product Name",
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Price",
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Select Weight Type",
                ),
                value: _weightType,
                onChanged: (value) {
                  setState(() {
                    _weightType = value;
                  });
                },
                items: <String>["Kg", "g", "Unit", "Litre"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a weight type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickMainImage,
                icon: const Icon(Icons.image),
                label: const Text("Pick Main Image"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickAdditionalImages,
                icon: const Icon(Icons.image),
                label: const Text("Pick Additional Images"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Product Description",
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10,),
              
              ElevatedButton(
                
                 style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // Button background color
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255), // Button text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                onPressed: _addProduct,
                
                 child: SizedBox(
    height: 40, // Fixed height, you can make this dynamic if 'height' is a variable
    width: double.infinity, // This makes the button take full available width
    child: Center( // Center the text within the SizedBox
      child: Text(
        widget.productId != null ? "Update Product" : "Add Product",
      ),
    ),)
              ),
              const SizedBox(height: 20),
              Center(
                child: _mainImage != null
                    ? Image.file(_mainImage!,
                        width: 200, height: 180, fit: BoxFit.cover)
                    : Container(
                        width: 200,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                            child: Text("No Main Image Selected"))),
              ),
              const SizedBox(height: 20),
              _additionalImages.isNotEmpty
                  ? Column(
                      children: _additionalImages.map((image) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Image.file(image!,
                              width: 150, height: 120, fit: BoxFit.cover),
                        );
                      }).toList(),
                    )
                  : Container(
                      width: 150,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No Additional Images Selected"),
                          ))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          // Navigation logic here
        },
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Center(child: Text('Menu'))),
          ListTile(title: const Text("Home")),
          ListTile(title: const Text("Order")),
          ListTile(title: const Text("Categories")),
          ListTile(title: const Text("Product")),
        ],
      ),
    );
  }
}
/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quick_mart_admin/viewproduct.dart';

class Product extends StatefulWidget {
  const Product({super.key});

  @override
  State<Product> createState() => _ProductState();
}

class _ProductState extends State<Product> {
  File? _mainImage;
  List<File?> _additionalImages = [];
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _weightType;
  String? _category;
  final _formKey = GlobalKey<FormState>();

  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _getCategories();
  }

  Future<void> _getCategories() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('category').get();
      setState(() {
        categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _pickMainImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mainImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickAdditionalImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _additionalImages
            .addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dt4enb1nt/image/upload'),
      );
      request.fields['upload_preset'] = 'quickmart';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = json.decode(responseData.body);
        return data['secure_url'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      String? mainImageUrl;
      if (_mainImage != null) {
        mainImageUrl = await _uploadImage(_mainImage!);
      }

      List<String> additionalImageUrls = [];
      for (var image in _additionalImages) {
        if (image != null) {
          String? imageUrl = await _uploadImage(image);
          if (imageUrl != null) {
            additionalImageUrls.add(imageUrl);
          }
        }
      }

      try {
        await FirebaseFirestore.instance.collection('product').add({
          'category': _category,
          'description': _descriptionController.text,
          'image': mainImageUrl ?? '',
          'price': _priceController.text,
          'productname': _productNameController.text,
          'type': _weightType,
          'moreImages': additionalImageUrls,
        });

        setState(() {
          _descriptionController.clear();
          _productNameController.clear();
          _priceController.clear();
          _mainImage = null;
          _additionalImages.clear();
          _category = null;
          _weightType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _productNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 600;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: isWeb ? _buildWebDashboard(context) : _buildMobileView(),
        ),
        drawer: isWeb ? null : _buildDrawer(context),
      ),
    );
  }
  Widget _buildWebDashboard(BuildContext context) {
  return Row(
    children: [
      Container(
        width: 250,
        color: const Color.fromARGB(255, 239, 129, 157),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset("assets/images/supermarkt.jpg",
                  height: 80, width: 80),
            ),
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
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(3, 3),
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProductView()),
                                );
                              },
                              child: const Text("View Product"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text("Add Product",
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          hint: const Text("Select Category"),
                          value: _category,
                          onChanged: (value) {
                            setState(() {
                              _category = value;
                            });
                          },
                          items: categories
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _productNameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Product Name",
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter a product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Price",
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter a price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          hint: const Text("Select Weight Type"),
                          value: _weightType,
                          onChanged: (value) {
                            setState(() {
                              _weightType = value;
                            });
                          },
                          items: <String>["Kg", "g", "Unit", "Litre"]
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickMainImage,
                          icon: const Icon(Icons.image),
                          label: const Text("Pick Main Image"),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickAdditionalImages,
                          icon: const Icon(Icons.image),
                          label: const Text("Pick Additional Images"),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Product Description",
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _addProduct,
                          child: const Text("Add Product"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const SizedBox(height: 30),
                      _mainImage != null
                          ? Image.file(_mainImage!,
                              width: 200, height: 180, fit: BoxFit.cover)
                          : Container(
                              width: 200,
                              height: 180,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Text("No Main Image Selected"))),
                      const SizedBox(height: 20),
                      _additionalImages.isNotEmpty
                          ? Column(
                              children: _additionalImages.map((image) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Image.file(image!,
                                      width: 150,
                                      height: 120,
                                      fit: BoxFit.cover),
                                );
                              }).toList(),
                            )
                          : Container(
                              width: 150,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Text("No Additional Images Selected"))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildMobileView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(3, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
      child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Product",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(), // Pushes button to the right
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductView()), // Correct navigation
                      );
                    },
                    child: const Text("View Product"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Add Product", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),

              // Dropdown for Categories
              DropdownButton<String>(
                hint: const Text("Select Category"),
                value: _category,
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
                items: categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Product Name
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Product Name",
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Price",
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Weight Type Dropdown
              DropdownButton<String>(
                hint: const Text("Select Weight Type"),
                value: _weightType,
                onChanged: (value) {
                  setState(() {
                    _weightType = value;
                  });
                },
                items: <String>["Kg", "g", "Unit", "Litre"]
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),

              // Main Image (Pick Image)
              ElevatedButton.icon(
                onPressed: _pickMainImage,
                icon: const Icon(Icons.image),
                label: const Text("Pick Main Image"),
              ),
              const SizedBox(height: 10),

              // Additional Images (Pick Images)
              ElevatedButton.icon(
                onPressed: _pickAdditionalImages,
                icon: const Icon(Icons.image),
                label: const Text("Pick Additional Images"),
              ),
              const SizedBox(height: 10),

              // Product Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Product Description",
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Add Product Button
              ElevatedButton(
                onPressed: _addProduct,
                child: const Text("Add Product"),
              ),
              const SizedBox(height: 20),

              // Image Preview (Below Form)
              Center(
                child: _mainImage != null
                    ? Image.file(_mainImage!,
                        width: 200, height: 180, fit: BoxFit.cover)
                    : Container(
                        width: 200,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                            child: Text("No Main Image Selected"))),
              ),
              const SizedBox(height: 20),
              _additionalImages.isNotEmpty
                  ? Column(
                      children: _additionalImages.map((image) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Image.file(image!,
                              width: 150, height: 120, fit: BoxFit.cover),
                        );
                      }).toList(),
                    )
                  : Container(
                      width: 150,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Center(
                          child: Text("No Additional Images Selected"))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          // Navigation logic here
        },
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Center(child: Text('Menu'))),
          ListTile(title: const Text("Home")),
          ListTile(title: const Text("Order")),
          ListTile(title: const Text("Categories")),
          ListTile(title: const Text("Product")),
        ],
      ),
    );
  }
}*/
