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
  const PharmacistHome(
      {super.key, required this.onThemeChanged, required this.isDarkMode});

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
          backgroundColor:
          _isDarkMode ? Colors.blueGrey : const Color(0xFF0288D1),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> addProduct(
      Map<String, dynamic> productData, {
        File? image,
        String? manualImageReference,
      }) async {
    final expiryDateStr = productData['expiryDate']?.toString();
    if (expiryDateStr == null || expiryDateStr.isEmpty) {
      throw StateError('Expiry date is required.');
    }

    final expiryDate = DateTime.tryParse(expiryDateStr);
    if (expiryDate == null) {
      throw StateError('Invalid expiry date format.');
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly =
    DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    if (expiryOnly.isBefore(todayOnly) ||
        expiryOnly.isAtSameMomentAs(todayOnly)) {
      throw StateError(
          'Expiry date must be a future date. Cannot add expired or today\'s products.');
    }

    final productName = productData['name']?.toString().trim();
    if (productName == null || productName.isEmpty) {
      throw StateError('Product name must not be empty.');
    }

    final quantity = productData['quantity'];
    if (quantity == null) {
      throw StateError('Product quantity must be specified.');
    }

    // 🔹 رفع الصورة
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

    // 🔹 تحقق إن كان المنتج موجود مسبقًا لنفس المستخدم
    final existingSnapshot =
    await dbRef.get();

    String? existingProductKey;
    Map<String, dynamic>? existingProduct;
    if (existingSnapshot.exists && existingSnapshot.value is Map) {
      final existingProducts = Map<String, dynamic>.from(existingSnapshot.value as Map);
      for (var entry in existingProducts.entries) {
        final existing = Map<String, dynamic>.from(entry.value);
        final existingName =
            existing['name']?.toString().trim().toLowerCase() ?? '';
        if (existingName == productName.toLowerCase()) {
          existingProductKey = entry.key.toString();
          existingProduct = existing;
          break;
        }
      }
    }

    // 🔹 إذا المنتج موجود مسبقًا → أضف Batch جديدة
    if (existingProductKey != null) {
      final batchId = DateTime.now().millisecondsSinceEpoch.toString();
      final batchData = {
        'batchId': batchId,
        'expiryDate': expiryDateStr,
        'quantity': quantity,
        'addedAt': ServerValue.timestamp,
      };

      await dbRef
          .child(existingProductKey)
          .child('batches')
          .child(batchId)
          .set(batchData);

      // ✅ حدث الكمية الكلية بناءً على كل الـ batches وحدث expiryDate إلى أقرب تاريخ صالح
      await _updateTotalQuantity(existingProductKey);

      return; // ⬅️ انتهى التحديث، لا تضف منتج جديد
    }

    // 🔹 المنتج جديد كليًا → أنشئ منتج رئيسي مع أول batch
    final productId = DateTime.now().millisecondsSinceEpoch.toString();
    final batchId = '${productId}_batch1';

    productData['imageUrl'] = imageUrl;
    productData['productId'] = productId;
    productData['ownerId'] = user!.uid;
    productData['createdAt'] = ServerValue.timestamp;
    productData['status'] =
    (quantity is num && quantity > 0) ? 'in_stock' : 'out_of_stock';

    // إضافة الـ batch الأولى
    final batchData = {
      'batchId': batchId,
      'expiryDate': expiryDateStr,
      'quantity': quantity,
      'addedAt': ServerValue.timestamp,
    };
    productData['batches'] = {batchId: batchData};

    await dbRef.child(productId).set(productData);

    // 🔹 حذف الباتشات المنتهية الصلاحية تلقائيًا (لكل منتجات هذا المالك)
    final allProducts =
    await dbRef.get();
    if (allProducts.exists && allProducts.value is Map) {
      final data = Map<String, dynamic>.from(allProducts.value as Map);
      for (var entry in data.entries) {
        final product = Map<String, dynamic>.from(entry.value);
        final batches = product['batches'];
        if (batches is Map) {
          for (var bEntry in (batches as Map).entries) {
            final batch = Map<String, dynamic>.from(bEntry.value);
            final expiryStr = batch['expiryDate']?.toString();
            if (expiryStr != null && expiryStr.isNotEmpty) {
              final expiry = DateTime.tryParse(expiryStr);
              if (expiry != null && expiry.isBefore(DateTime.now())) {
                await dbRef
                    .child(entry.key)
                    .child('batches')
                    .child(bEntry.key)
                    .remove();
              }
            }
          }
        }
      }
    }
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

    if (manualImageReference != null &&
        manualImageReference.trim().isNotEmpty) {
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
    final quantity = productData['quantity'];
    productData['status'] =
    (quantity is num && quantity > 0) ? 'in_stock' : 'out_of_stock';

    await dbRef.child(key).update(productData);

    // بعد تحديث بيانات المنتج العام (مثلاً الاسم/الوصف/سعر)، نفرّش كمية/expiry من الباتشات إن وجدت
    await _updateTotalQuantity(key);
  }

  Future<String?> _resolveManualImageReference(String? rawInput) async {
    final trimmed = rawInput?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('data:')) {
      return trimmed;
    }

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

  // ===================== batch management dialogs & helpers =====================

  Future<void> _editBatchDialog(BuildContext context, String productKey, String batchKey, Map<String, dynamic> batch) async {
    final qtyController = TextEditingController(text: batch['quantity']?.toString() ?? '0');
    DateTime? expiryDate = batch['expiryDate'] != null ? DateTime.tryParse(batch['expiryDate']) : null;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dctx, setDState) {
            return AlertDialog(
              title: const Text('Edit Batch'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(expiryDate == null
                          ? 'Expiry: Not selected'
                          : 'Expiry: ${DateFormat('yyyy-MM-dd').format(expiryDate!)}'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dctx,
                            initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDState(() => expiryDate = picked);
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                    if (expiryDate == null) {
                      ScaffoldMessenger.of(dctx).showSnackBar(const SnackBar(content: Text('Please choose expiry date')));
                      return;
                    }
                    final expiryOnly = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
                    final todayOnly = DateTime.now();
                    final todayOnlyNormalized = DateTime(todayOnly.year, todayOnly.month, todayOnly.day);
                    if (expiryOnly.isBefore(todayOnlyNormalized) || expiryOnly.isAtSameMomentAs(todayOnlyNormalized)) {
                      ScaffoldMessenger.of(dctx).showSnackBar(const SnackBar(content: Text('Expiry must be a future date')));
                      return;
                    }

                    await dbRef.child(productKey).child('batches').child(batchKey).update({
                      'quantity': qty,
                      'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate!),
                    });

                    await _updateTotalQuantity(productKey);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch updated')));
                    }
                    Navigator.pop(dctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBatchDialog(BuildContext context, String productKey, String batchKey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Batch'),
        content: const Text('Are you sure you want to delete this batch?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await dbRef.child(productKey).child('batches').child(batchKey).remove();
      await _updateTotalQuantity(productKey);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch deleted')));
    }
  }

  Future<void> _addNewBatchDialog(BuildContext context, String productKey) async {
    final qtyController = TextEditingController();
    DateTime? expiryDate;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dctx, setDState) {
            return AlertDialog(
              title: const Text('Add New Batch'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(expiryDate == null
                          ? 'Expiry: Not selected'
                          : 'Expiry: ${DateFormat('yyyy-MM-dd').format(expiryDate!)}'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dctx,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setDState(() => expiryDate = picked);
                        },
                      )
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                    if (expiryDate == null) {
                      ScaffoldMessenger.of(dctx).showSnackBar(const SnackBar(content: Text('Please choose expiry date')));
                      return;
                    }
                    final expiryOnly = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
                    final todayOnly = DateTime.now();
                    final todayOnlyNormalized = DateTime(todayOnly.year, todayOnly.month, todayOnly.day);
                    if (expiryOnly.isBefore(todayOnlyNormalized) || expiryOnly.isAtSameMomentAs(todayOnlyNormalized)) {
                      ScaffoldMessenger.of(dctx).showSnackBar(const SnackBar(content: Text('Expiry must be a future date')));
                      return;
                    }

                    final batchId = DateTime.now().millisecondsSinceEpoch.toString();
                    await dbRef.child(productKey).child('batches').child(batchId).set({
                      'batchId': batchId,
                      'quantity': qty,
                      'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate!),
                      'addedAt': ServerValue.timestamp,
                    });

                    await _updateTotalQuantity(productKey);

                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch added')));
                    Navigator.pop(dctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTotalQuantity(String productKey) async {
    final batchesRef = dbRef.child(productKey).child('batches');
    final snapshot = await batchesRef.get();

    int totalQty = 0;
    DateTime? nearestExpiry;
    if (snapshot.exists && snapshot.value is Map) {
      final batches = Map<String, dynamic>.from(snapshot.value as Map);
      for (var bEntry in batches.entries) {
        final batch = Map<String, dynamic>.from(bEntry.value);
        final qty = int.tryParse(batch['quantity']?.toString() ?? '0') ?? 0;
        totalQty += qty;
        final expiryStr = batch['expiryDate']?.toString();
        if (expiryStr != null && expiryStr.isNotEmpty) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null) {
            if (nearestExpiry == null || expiry.isBefore(nearestExpiry)) {
              nearestExpiry = expiry;
            }
          }
        }
      }
    }

    final updateData = {
      'quantity': totalQty,
      'status': totalQty > 0 ? 'in_stock' : 'out_of_stock',
    };

    if (nearestExpiry != null) {
      updateData['expiryDate'] = DateFormat('yyyy-MM-dd').format(nearestExpiry);
    } else {
      updateData['expiryDate'] = '';
    }

    await dbRef.child(productKey).update(updateData);
  }

  // ===================== showProductDialog (edit/add) - تم إضافة عرض الباتشات + إدارة الباتشات =====================
  Future<void> _manageBatchesDialog(BuildContext context, String productKey) async {
    final batchesRef = dbRef.child(productKey).child('batches');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dctx, setDState) {
            return AlertDialog(
              title: const Text('Manage Batches'),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder(
                  stream: batchesRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      final Map<String, dynamic> batches =
                      Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                      final sorted = batches.entries.toList()
                        ..sort((a, b) => b.value['addedAt']?.compareTo(a.value['addedAt']) ?? 0);

                      return ListView(
                        shrinkWrap: true,
                        children: sorted.map((entry) {
                          final batchKey = entry.key;
                          final batch = Map<String, dynamic>.from(entry.value);
                          final expiry = batch['expiryDate'] ?? 'Unknown';
                          final qty = batch['quantity']?.toString() ?? '0';
                          final isExpired = (() {
                            final d = DateTime.tryParse(expiry);
                            if (d == null) return false;
                            final today = DateTime.now();
                            final todayOnly = DateTime(today.year, today.month, today.day);
                            return d.isBefore(todayOnly) || d.isAtSameMomentAs(todayOnly);
                          })();

                          return Card(
                            color: isExpired ? Colors.red[50] : null,
                            child: ListTile(
                              title: Text('Batch ID: $batchKey'),
                              subtitle: Text('Expiry: $expiry\nQuantity: $qty'),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _editBatchDialog(context, productKey, batchKey, batch),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteBatchDialog(context, productKey, batchKey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return const Center(child: Text('No batches found'));
                    }
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _addNewBatchDialog(context, productKey);
                    setDState(() {}); // refresh
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Batch'),
                ),
              ],
            );
          },
        );
      },
    );
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

    String? previewUrl =
    oldImageUrl.isNotEmpty ? oldImageUrl : 'assets/pharmacy.jpg';

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
                      decoration:
                      const InputDecoration(labelText: 'Product Name'),
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
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
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
                      decoration:
                      const InputDecoration(labelText: 'Description'),
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
                      decoration:
                      const InputDecoration(labelText: 'Price (OMR)'),
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final v = double.tryParse(value ?? '');
                        if (v == null || v <= 0)
                          return 'Enter a valid price > 0';
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
                        if (v == null || v < 0)
                          return 'Enter a valid quantity ≥ 0';
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
                      const Text('Expiry date is required',
                          style: TextStyle(color: Colors.red))
                    else ...[
                      Builder(
                        builder: (_) {
                          final today = DateTime.now();
                          final todayOnly =
                          DateTime(today.year, today.month, today.day);
                          final expiryOnly = DateTime(expiryDate!.year,
                              expiryDate!.month, expiryDate!.day);
                          if (expiryOnly.isBefore(todayOnly) ||
                              expiryOnly.isAtSameMomentAs(todayOnly)) {
                            return const Text(
                                'Expiry date must be a future date (cannot be today or past)',
                                style: TextStyle(color: Colors.red));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                            source: ImageSource.gallery);
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
                        hintText:
                        'e.g. panadol.jpg or https://example.com/image.jpg',
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

                    // ---------------- show batches when editing an existing product ----------------
                    if (product != null && product['batches'] != null && product['batches'] is Map) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Batches:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Colors.grey[900] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: (product['batches'] as Map).entries.map<Widget>((entry) {
                            final batch = Map<String, dynamic>.from(entry.value);
                            final expiry = batch['expiryDate'] ?? 'Unknown';
                            final qty = batch['quantity']?.toString() ?? '0';
                            final isExpired = (() {
                              try {
                                final d = DateTime.tryParse(expiry);
                                if (d == null) return false;
                                final today = DateTime.now();
                                final todayOnly = DateTime(today.year, today.month, today.day);
                                return d.isBefore(todayOnly) || d.isAtSameMomentAs(todayOnly);
                              } catch (_) {
                                return false;
                              }
                            })();

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              color: isExpired ? (_isDarkMode ? Colors.red[900] : Colors.red[50]) : null,
                              child: ListTile(
                                title: Text('Batch ID: ${entry.key}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Expiry: $expiry\nQuantity: $qty'),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                      onPressed: () => _editBatchDialog(
                                        context,
                                        product['key'],
                                        entry.key,
                                        batch,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteBatchDialog(
                                        context,
                                        product['key'],
                                        entry.key,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Batch'),
                          onPressed: () => _addNewBatchDialog(context, product['key']),
                        ),
                      ),
                    ],
                    // ---------------- end batches section ----------------
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
                  final today = DateTime.now();
                  final todayOnly =
                  DateTime(today.year, today.month, today.day);

                  if (expiryDate == null) {
                    setDialogState(() {}); // trigger error text
                    return;
                  }

                  final expiryOnly = DateTime(
                      expiryDate!.year, expiryDate!.month, expiryDate!.day);
                  if (expiryOnly.isBefore(todayOnly) ||
                      expiryOnly.isAtSameMomentAs(todayOnly)) {
                    setDialogState(() {}); // trigger error text
                    return;
                  }

                  final data = {
                    'name': nameController.text.trim(),
                    'category': selectedCategory ?? 'Other',
                    'description': descriptionController.text.trim(),
                    'price': double.tryParse(priceController.text.trim()) ?? 0,
                    'quantity':
                    int.tryParse(quantityController.text.trim()) ?? 0,
                    'requiresPrescription': requiresPrescription,
                    'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate!),
                  };

                  try {
                    if (product == null) {
                      await addProduct(
                        data,
                        image: imageFile,
                        manualImageReference: imageReferenceController.text,
                      );
                    } else {
                      final newName =
                      data['name'].toString().trim().toLowerCase();
                      final oldName =
                      product['name']?.toString().trim().toLowerCase();
                      if (newName != oldName) {
                        final snapshot = await dbRef.get();
                        if (snapshot.exists && snapshot.value is Map) {
                          final existingProducts = snapshot.value as Map;
                          for (var entry in existingProducts.entries) {
                            if (entry.key.toString() !=
                                product['key'].toString()) {
                              final existingName = entry.value['name']
                                  ?.toString()
                                  .trim()
                                  .toLowerCase();
                              if (existingName == newName) {
                                if (!dialogContext.mounted) return;
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'A product with the name "${data['name']}" already exists.')),
                                );
                                return;
                              }
                            }
                          }
                        }
                      }
                      await updateProduct(
                        product['key'],
                        data,
                        image: imageFile,
                        manualImageReference: imageReferenceController.text,
                        oldImageUrl: oldImageUrl,
                        existingCreatedAt: product['createdAt'],
                      );
                    }
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  } catch (e) {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              e.toString().replaceAll('StateError: ', ''))),
                    );
                  }
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
    Color backgroundColor =
    _isDarkMode ? Colors.grey[900]! : const Color(0xFFB3EFC);
    Color appBarColor =
    _isDarkMode ? Colors.grey[850]! : const Color(0xFF0288D1);
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
                hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black45),
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
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
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
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final imageUrl =
                          product['imageUrl'] ?? 'assets/pharmacy.jpg';
                      Widget imageWidget;

                      if (imageUrl.startsWith('data:')) {
                        try {
                          final base64Data = imageUrl.split(',').length > 1
                              ? imageUrl.split(',')[1]
                              : '';
                          final bytes = base64Decode(base64Data);
                          imageWidget = Image.memory(bytes,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image));
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
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
                          title: Text(product['name'],
                              style: TextStyle(color: textColor)),
                          subtitle: Text(
                              "Category: ${product['category']}\nPrice: ${product['price']}\nQuantity: ${product['quantity']}\nExpiry: ${product['expiryDate'] ?? ''}",
                              style: TextStyle(color: textColor)),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _manageBatchesDialog(context, product['key']),
                              ),

                              IconButton(
                                icon:
                                const Icon(Icons.delete, color: Colors.red),
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
