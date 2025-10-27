import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'profile_page.dart';

class PharmacistHome extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  const PharmacistHome({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  State<PharmacistHome> createState() => _PharmacistHomeState();
}

class _PharmacistHomeState extends State<PharmacistHome> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference dbRef;
  final ImagePicker _picker = ImagePicker();
  String searchQuery = '';
  late bool _isDarkMode;

  final List<String> categories = [
    'Baby and family care',
    'Fitness & diet',
    'Personal care',
    'First aid',
    'Skin and beauty care',
    'Vitamins and supplements',
    'Medicines',
    'Sensual wellness',
    'Other',
  ];

  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    dbRef = DatabaseService.instance.ref("products/${user!.uid}");
    _isDarkMode = widget.isDarkMode;
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDarkMode ? Colors.blueGrey : const Color(0xFF0288D1),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  // ---------------- Add Product / Update / Delete / Show Dialog ----------------
  Future<void> addProduct(
      Map<String, dynamic> productData, {
        File? image,
        String? manualImageReference,
      }) async {
    final productId = DateTime.now().millisecondsSinceEpoch.toString();
    String? imageUrl;

    if (manualImageReference != null && manualImageReference.trim().isNotEmpty) {
      try {
        imageUrl = await _resolveManualImageReference(manualImageReference);
      } catch (e) {
        debugPrint('Manual image reference failed: $e');
      }
    }

    if (image != null && await image.exists()) {
      final storageService = StorageService();
      imageUrl = await storageService.uploadImageToDatabase(
        image,
        'product_images',
      );
    }

    imageUrl ??= 'assets/pharmacy.jpg';

    productData['imageUrl'] = imageUrl;
    productData['productId'] = productId;
    productData['ownerId'] = user!.uid;
    productData['createdAt'] = ServerValue.timestamp;

    await dbRef.child(productId).set(productData);
  }

  Future<void> updateProduct(
      String key,
      Map<String, dynamic> productData, {
        File? image,
        String? manualImageReference,
        required String oldImageUrl,
        dynamic existingCreatedAt,
      }) async {
    String? imageUrl;

    if (manualImageReference != null && manualImageReference.trim().isNotEmpty) {
      try {
        imageUrl = await _resolveManualImageReference(manualImageReference);
      } catch (e) {
        debugPrint('Manual image reference failed: $e');
      }
    }

    if (image != null && await image.exists()) {
      final storageService = StorageService();
      imageUrl = await storageService.uploadImageToDatabase(
        image,
        'product_images',
      );
    }

    imageUrl ??= (oldImageUrl.isNotEmpty ? oldImageUrl : 'assets/pharmacy.jpg');

    productData['imageUrl'] = imageUrl;
    productData['createdAt'] = existingCreatedAt ?? ServerValue.timestamp;
    productData['ownerId'] = user!.uid;

    await dbRef.child(key).update(productData);
  }

  Future<String?> _resolveManualImageReference(String? rawInput, {String? ownerId}) async {
    final trimmed = rawInput?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // If it's already an HTTP URL or a data URL, return it. Otherwise try assets.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('data:')) {
      return trimmed;
    }

    // Fallback: treat as asset or product image filename stored in assets
    return trimmed.startsWith('assets/') ? trimmed : 'assets/$trimmed';
  }

  Future<void> deleteProduct(String key) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await dbRef.child(key).remove();
    }
  }

  Future<void> showProductDialog({Map? product}) async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descriptionController =
    TextEditingController(text: product?['description'] ?? '');
    final priceController = TextEditingController(
      text: product?['price'] != null ? product!['price'].toString() : '',
    );
    final quantityController = TextEditingController(
      text: product?['quantity'] != null ? product!['quantity'].toString() : '',
    );

    String? selectedCategory = product?['category'] as String?;
    DateTime? expiryDate = product?['expiryDate'] != null
        ? DateTime.tryParse(product!['expiryDate'].toString())
        : null;
    bool requiresPrescription =
        (product?['requiresPrescription'] ?? false) == true;
    File? imageFile;
    final String oldImageUrl = product?['imageUrl']?.toString() ?? '';

    final imageReferenceController = TextEditingController(
      text: oldImageUrl.startsWith('http')
          ? oldImageUrl
          : oldImageUrl.replaceFirst('product_images/', ''),
    );

    String? previewUrl = oldImageUrl.isNotEmpty ? oldImageUrl : 'assets/pharmacy.jpg';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> refreshPreview(String value) async {
            final trimmed = value.trim();
            if (trimmed.isEmpty) {
              setDialogState(() {
                previewUrl = imageFile != null ? null : 'assets/pharmacy.jpg';
              });
              return;
            }
            final resolved = await _resolveManualImageReference(trimmed);
            if (!dialogContext.mounted) return;
            setDialogState(() {
              previewUrl = resolved;
              imageFile = null;
            });
          }

          return AlertDialog(
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setDialogState(() {
                        selectedCategory = val;
                      }),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                      validator: (value) {
                        if (value != null && value.length > 300) {
                          return 'Description too long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price (OMR)'),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final v = double.tryParse(value ?? '');
                        if (v == null || v <= 0) return 'Enter a valid price > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final v = int.tryParse(value ?? '');
                        if (v == null || v < 0) return 'Enter a valid quantity ≥ 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      title: const Text('Requires prescription'),
                      value: requiresPrescription,
                      onChanged: (val) =>
                          setDialogState(() => requiresPrescription = val),
                    ),
                    Row(
                      children: [
                        Text(
                          expiryDate == null
                              ? 'Expiry Date: Not selected'
                              : 'Expiry: ${DateFormat('yyyy-MM-dd').format(expiryDate!)}',
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: dialogContext,
                              initialDate: expiryDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                expiryDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (expiryDate == null)
                      const Text('Expiry date is required', style: TextStyle(color: Colors.red))
                    else if (expiryDate!.isBefore(DateTime.now()))
                      const Text('Expiry date must be today or later', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked =
                        await _picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setDialogState(() {
                            imageFile = File(picked.path);
                            previewUrl = null;
                            imageReferenceController.clear();
                          });
                        }
                      },
                      child: const Text('Select Image from Gallery'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: imageReferenceController,
                      decoration: const InputDecoration(
                        labelText: 'Image name or URL',
                        hintText: 'e.g. panadol.jpg or https://example.com/image.jpg',
                        helperText:
                        'Leave empty to keep the uploaded file. Non-URLs are looked up under product_images/.',
                      ),
                      onChanged: (value) => refreshPreview(value),
                    ),
                    const SizedBox(height: 10),
                    if (imageFile != null)
                      Image.file(imageFile!, height: 100)
                    else if (previewUrl != null)
                      Image.asset(
                        previewUrl!,
                        height: 100,
                        errorBuilder: (_, __, ___) =>
                        const Text('Unable to load preview'),
                      )
                    else
                      Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: const Text('No image selected'),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (expiryDate == null || expiryDate!.isBefore(DateTime.now())) {
                    setDialogState(() {}); // trigger error text
                    return;
                  }

                  final data = {
                    'name': nameController.text.trim(),
                    'category': selectedCategory ?? 'Other',
                    'description': descriptionController.text.trim(),
                    'price': double.tryParse(priceController.text.trim()) ?? 0,
                    'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
                    'requiresPrescription': requiresPrescription,
                    'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate!),
                  };

                  if (product == null) {
                    await addProduct(
                      data,
                      image: imageFile,
                      manualImageReference: imageReferenceController.text,
                    );
                  } else {
                    await updateProduct(
                      product['key'],
                      data,
                      image: imageFile,
                      manualImageReference: imageReferenceController.text,
                      oldImageUrl: oldImageUrl,
                      existingCreatedAt: product['createdAt'],
                    );
                  }
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = _isDarkMode ? Colors.grey[900]! : const Color(0xFFB3E5FC);
    Color appBarColor = _isDarkMode ? Colors.grey[850]! : const Color(0xFF0288D1);
    Color textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          "Pharmacist Products",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    isDarkMode: _isDarkMode, // pass current dark mode
                    onThemeChanged: (val) {
                      setState(() {
                        _isDarkMode = val; // update current page dark mode
                      });
                      widget.onThemeChanged(val); // notify app
                    },
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      Login(onThemeChanged: widget.onThemeChanged),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: buildButton("Add New Product", () => showProductDialog()),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                fillColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by name or category...",
                hintStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black45),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder(
              stream: dbRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data!.snapshot.value != null) {
                  Map data = (snapshot.data!.snapshot.value as Map);
                  List products = [];
                  data.forEach((key, value) {
                    value['key'] = key;
                    products.add(value);
                  });

                  products = products
                      .where((p) =>
                  p['name']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                      p['category']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .toList();

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final imageUrl = product['imageUrl'] ?? 'assets/pharmacy.jpg';
                      Widget imageWidget;

                      if (imageUrl.startsWith('data:')) {
                        try {
                          final base64Data = imageUrl.split(',').length > 1 ? imageUrl.split(',')[1] : '';
                          final bytes = base64Decode(base64Data);
                          imageWidget = Image.memory(bytes,
                              width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
                        } catch (_) {
                          imageWidget = const Icon(Icons.broken_image);
                        }
                      } else if (imageUrl.startsWith('assets/')) {
                        imageWidget = Image.asset(imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image));
                      } else if (imageUrl.startsWith('http')) {
                        imageWidget = Image.network(imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image));
                      } else {
                        imageWidget =
                        const Icon(Icons.image_not_supported, size: 50);
                      }

                      return Card(
                        color: _isDarkMode ? Colors.grey[800] : Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: _isDarkMode
                                  ? Colors.blueGrey
                                  : const Color(0xFF0288D1),
                              width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: imageWidget,
                          title: Text(product['name'], style: TextStyle(color: textColor)),
                          subtitle: Text(
                              "Category: ${product['category']}\nPrice: ${product['price']}\nQuantity: ${product['quantity']}\nExpiry: ${product['expiryDate']}",
                              style: TextStyle(color: textColor)),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => showProductDialog(product: product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteProduct(product['key']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(
                      child: Text("No products found.",
                          style: TextStyle(color: textColor)));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
