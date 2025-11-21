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
import 'pharmacist_reports_page.dart';
import 'models/product.dart';

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
  bool _showAIPredictions = true;

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

  Widget _buildAIPredictionsWidget(List<Product> products) {
    // AI-driven analytics to predict high-demand products
    final predictedProducts = _getPredictedHighDemandProducts(products);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3949AB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Predictions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'High-demand products forecast',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showAIPredictions = !_showAIPredictions),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _showAIPredictions 
                          ? Icons.keyboard_arrow_up 
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showAIPredictions) ...[
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            if (predictedProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add products to see AI predictions...',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: predictedProducts.length,
                  itemBuilder: (context, index) {
                    final prediction = predictedProducts[index];
                    return Container(
                      width: 145,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: prediction['trend'] == 'high' 
                                        ? Colors.greenAccent 
                                        : Colors.amberAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${prediction['confidence']}%',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Qty: ${prediction['quantity']}',
                                style: TextStyle(
                                  color: (prediction['quantity'] as int) < 20 
                                      ? Colors.redAccent 
                                      : Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: Text(
                              prediction['name'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  prediction['demandLevel'] as String,
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  final productId = prediction['productId'] as String;
                                  final snapshot = await dbRef.child(productId).get();
                                  if (snapshot.exists && snapshot.value is Map) {
                                    final productData = Map<String, dynamic>.from(snapshot.value as Map);
                                    productData['key'] = productId;
                                    showBatchesDialog(productData);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Color(0xFF1A237E),
                                        size: 12,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Stock',
                                        style: TextStyle(
                                          color: Color(0xFF1A237E),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getPredictedHighDemandProducts(List<Product> products) {
    if (products.isEmpty) return [];
    
    // AI-driven demand prediction algorithm
    // Factors: price competitiveness, category trends, stock levels
    final List<Map<String, dynamic>> predictions = [];
    
    // Calculate average price per category for analysis
    final categoryPrices = <String, List<double>>{};
    for (final p in products) {
      categoryPrices.putIfAbsent(p.category, () => []).add(p.price);
    }
    
    final categoryAvg = categoryPrices.map((cat, prices) {
      final avg = prices.reduce((a, b) => a + b) / prices.length;
      return MapEntry(cat, avg);
    });
    
    // Analyze each product for demand prediction
    for (final product in products) {
      final avgPrice = categoryAvg[product.category] ?? product.price;
      
      // Demand score calculation (simplified AI model)
      double demandScore = 50.0;
      
      // Price competitiveness factor
      if (product.price < avgPrice) {
        demandScore += (avgPrice - product.price) / avgPrice * 30;
      }
      
      // Stock scarcity factor (lower stock = higher predicted demand)
      if (product.totalQuantity < 20) {
        demandScore += 15;
      } else if (product.totalQuantity < 50) {
        demandScore += 8;
      }
      
      // Category popularity boost
      final categoryPopularity = {
        'Medicines': 15,
        'Vitamins and supplements': 12,
        'First aid': 10,
        'Baby and family care': 10,
        'Personal care': 8,
        'Skin and beauty care': 7,
        'Fitness & diet': 6,
      };
      demandScore += categoryPopularity[product.category] ?? 5;
      
      // Normalize score
      demandScore = demandScore.clamp(0, 100);
      
      if (demandScore > 60) {
        predictions.add({
          'name': product.name,
          'productId': product.id,
          'quantity': product.totalQuantity,
          'confidence': demandScore.round(),
          'trend': demandScore > 80 ? 'high' : 'medium',
          'demandLevel': demandScore > 80 
              ? 'Very High' 
              : demandScore > 70 
                  ? 'High' 
                  : 'Moderate',
        });
      }
    }
    
    // Sort by confidence and return top predictions
    predictions.sort((a, b) => (b['confidence'] as int).compareTo(a['confidence'] as int));
    return predictions.take(5).toList();
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

    final quantity = productData['quantity'];
    if (quantity == null) {
      throw StateError('Product quantity must be specified.');
    }

    final productName = productData['name']?.toString().trim();
    if (productName == null || productName.isEmpty) {
      throw StateError('Product name is required.');
    }

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

    imageUrl ??= 'assets/pharmacy.jpg';

    // Check if product with same name exists
    final snapshot = await dbRef.get();
    String? existingProductId;
    Map<String, dynamic>? existingProductData;

    if (snapshot.exists && snapshot.value is Map) {
      final existingProducts = snapshot.value as Map;
      final productNameLower = productName.toLowerCase();

      for (var entry in existingProducts.entries) {
        final existingName =
            entry.value['name']?.toString().trim().toLowerCase();
        if (existingName == productNameLower) {
          existingProductId = entry.key.toString();
          existingProductData = Map<String, dynamic>.from(entry.value as Map);
          break;
        }
      }
    }

    if (existingProductId != null && existingProductData != null) {
      // Product exists - add a new batch
      // Get existing batches or create empty map
      Map<String, dynamic> batches = {};
      if (existingProductData['batches'] != null &&
          existingProductData['batches'] is Map) {
        batches =
            Map<String, dynamic>.from(existingProductData['batches'] as Map);
      }

      // Add new batch - ensure unique batch ID
      final now = DateTime.now();
      final uniqueBatchId =
          '${now.millisecondsSinceEpoch}_${(now.microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';

      batches[uniqueBatchId] = {
        'expiryDate': expiryDateStr,
        'quantity': quantity,
      };

      // Calculate total quantity
      int totalQuantity = 0;
      batches.values.forEach((batch) {
        if (batch is Map && batch['quantity'] != null) {
          final qty = batch['quantity'] is num
              ? (batch['quantity'] as num).toInt()
              : int.tryParse(batch['quantity'].toString()) ?? 0;
          totalQuantity += qty;
        }
      });

      // Update product with new batch
      await dbRef.child(existingProductId).update({
        'batches': batches,
        'quantity': totalQuantity, // For backward compatibility
        'status': totalQuantity > 0 ? 'in_stock' : 'out_of_stock',
      });
    } else {
      // New product - create with first batch
      final now = DateTime.now();
      final productId = now.millisecondsSinceEpoch.toString();
      // Use microseconds to ensure unique batch ID even if created at same millisecond
      final batchId =
          '${now.millisecondsSinceEpoch}_${(now.microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';

      productData['imageUrl'] = imageUrl;
      productData['productId'] = productId;
      productData['ownerId'] = user!.uid;
      productData['createdAt'] = ServerValue.timestamp;

      // Create first batch
      final batches = {
        batchId: {
          'expiryDate': expiryDateStr,
          'quantity': quantity,
        }
      };

      productData['batches'] = batches;
      productData['quantity'] = quantity; // For backward compatibility
      productData['status'] =
          (quantity is num && quantity > 0) ? 'in_stock' : 'out_of_stock';

      // Remove expiryDate from main product (it's now in batches)
      productData.remove('expiryDate');

      await dbRef.child(productId).set(productData);
    }
  }

  Future<void> updateProduct(
    String key,
    Map<String, dynamic> productData, {
    File? image,
    String? manualImageReference,
    required String oldImageUrl,
    dynamic existingCreatedAt,
    Map<String, dynamic>? preserveBatches,
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

    // Preserve existing batches if specified, otherwise use batches from productData
    Map<String, dynamic>? batchesToUse;
    if (preserveBatches != null) {
      batchesToUse = preserveBatches;
    } else if (productData['batches'] != null &&
        productData['batches'] is Map) {
      batchesToUse = Map<String, dynamic>.from(productData['batches'] as Map);
    } else {
      // Get existing batches from database
      final snapshot = await dbRef.child(key).get();
      if (snapshot.exists && snapshot.value is Map) {
        final existingData = snapshot.value as Map;
        if (existingData['batches'] != null && existingData['batches'] is Map) {
          batchesToUse =
              Map<String, dynamic>.from(existingData['batches'] as Map);
        }
      }
    }

    // Remove expiryDate and quantity from productData (they're in batches)
    productData.remove('expiryDate');
    productData.remove('quantity');

    // Calculate total quantity from batches
    int totalQuantity = 0;
    if (batchesToUse != null) {
      batchesToUse.values.forEach((batch) {
        if (batch is Map && batch['quantity'] != null) {
          final qty = batch['quantity'] is num
              ? (batch['quantity'] as num).toInt()
              : int.tryParse(batch['quantity'].toString()) ?? 0;
          totalQuantity += qty;
        }
      });
      productData['batches'] = batchesToUse;
    }

    productData['quantity'] = totalQuantity; // For backward compatibility
    productData['status'] = (totalQuantity > 0) ? 'in_stock' : 'out_of_stock';

    await dbRef.child(key).update(productData);
  }

  Future<void> deleteBatch(String productKey, String batchId) async {
    // Get existing product data
    final snapshot = await dbRef.child(productKey).get();
    if (!snapshot.exists || snapshot.value is! Map) {
      throw StateError('Product not found.');
    }

    final productData = Map<String, dynamic>.from(snapshot.value as Map);

    // Get batches map
    Map<String, dynamic> batches = {};
    if (productData['batches'] != null && productData['batches'] is Map) {
      batches = Map<String, dynamic>.from(productData['batches'] as Map);
    }

    // Remove batch
    batches.remove(batchId);

    // Calculate total quantity
    int totalQuantity = 0;
    batches.values.forEach((batch) {
      if (batch is Map && batch['quantity'] != null) {
        final qty = batch['quantity'] is num
            ? (batch['quantity'] as num).toInt()
            : int.tryParse(batch['quantity'].toString()) ?? 0;
        totalQuantity += qty;
      }
    });

    // Update product
    if (batches.isEmpty) {
      // If no batches left, delete the product entirely
      await deleteProduct(productKey);
    } else {
      await dbRef.child(productKey).update({
        'batches': batches,
        'quantity': totalQuantity, // For backward compatibility
        'status': totalQuantity > 0 ? 'in_stock' : 'out_of_stock',
      });
    }
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

  Future<void> showBatchesDialog(Map<dynamic, dynamic> product) async {
    final productKey = product['key'].toString();
    final productName = product['name']?.toString() ?? 'Product';

    // Get batches from product
    Map<String, dynamic> batches = {};
    if (product['batches'] != null && product['batches'] is Map) {
      batches = Map<String, dynamic>.from(product['batches'] as Map);
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Batches: $productName'),
        content: SingleChildScrollView(
          child: batches.isEmpty
              ? const Text('No batches found.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: batches.entries.map((entry) {
                    final batchId = entry.key.toString();
                    final batch = entry.value as Map;
                    final expiryDateStr = batch['expiryDate']?.toString();
                    final expiryDate = expiryDateStr != null
                        ? DateTime.tryParse(expiryDateStr)
                        : null;
                    final quantity = batch['quantity'] is num
                        ? (batch['quantity'] as num).toInt()
                        : int.tryParse(batch['quantity'].toString()) ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          expiryDate != null
                              ? DateFormat('yyyy-MM-dd').format(expiryDate)
                              : 'No expiry date',
                        ),
                        subtitle: Text('Quantity: $quantity'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                await showEditBatchDialog(
                                  productKey,
                                  batchId,
                                  expiryDate ?? DateTime.now(),
                                  quantity,
                                  Map<String, dynamic>.from(product),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Batch'),
                                    content: const Text(
                                        'Are you sure you want to delete this batch?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && dialogContext.mounted) {
                                  try {
                                    await deleteBatch(productKey, batchId);
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                      showBatchesDialog(
                                          Map<String, dynamic>.from(product));
                                    }
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to delete batch: ${e.toString().replaceAll('StateError: ', '')}')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await showAddBatchDialog(productKey, product);
            },
            child: const Text('Add Batch'),
          ),
        ],
      ),
    );
  }

  Future<void> showAddBatchDialog(
      String productKey, Map<dynamic, dynamic> product) async {
    final quantityController = TextEditingController();
    DateTime? expiryDate;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Batch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final v = int.tryParse(value ?? '');
                    if (v == null || v < 0) return 'Enter valid quantity ≥ 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                          context: ctx,
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
                      style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (expiryDate == null) {
                  setDialogState(() {});
                  return;
                }

                final quantity = int.tryParse(quantityController.text.trim());
                if (quantity == null || quantity < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter valid quantity')),
                  );
                  return;
                }

                final today = DateTime.now();
                final todayOnly = DateTime(today.year, today.month, today.day);
                final expiryOnly = DateTime(
                    expiryDate!.year, expiryDate!.month, expiryDate!.day);
                if (expiryOnly.isBefore(todayOnly) ||
                    expiryOnly.isAtSameMomentAs(todayOnly)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Expiry date must be a future date')),
                  );
                  return;
                }

                try {
                  await updateBatch(productKey, '', expiryDate!, quantity,
                      existingProductData: Map<String, dynamic>.from(product));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Batch added successfully')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to add batch: ${e.toString().replaceAll('StateError: ', '')}')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showEditBatchDialog(
    String productKey,
    String batchId,
    DateTime currentExpiryDate,
    int currentQuantity,
    Map<String, dynamic> product,
  ) async {
    final quantityController =
        TextEditingController(text: currentQuantity.toString());
    DateTime? expiryDate = currentExpiryDate;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Batch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final v = int.tryParse(value ?? '');
                    if (v == null || v < 0) return 'Enter valid quantity ≥ 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                          context: ctx,
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
                      style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (expiryDate == null) {
                  setDialogState(() {});
                  return;
                }

                final quantity = int.tryParse(quantityController.text.trim());
                if (quantity == null || quantity < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter valid quantity')),
                  );
                  return;
                }

                final today = DateTime.now();
                final todayOnly = DateTime(today.year, today.month, today.day);
                final expiryOnly = DateTime(
                    expiryDate!.year, expiryDate!.month, expiryDate!.day);
                if (expiryOnly.isBefore(todayOnly) ||
                    expiryOnly.isAtSameMomentAs(todayOnly)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Expiry date must be a future date')),
                  );
                  return;
                }

                try {
                  await updateBatch(productKey, batchId, expiryDate!, quantity,
                      existingProductData: Map<String, dynamic>.from(product));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Batch updated successfully')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to update batch: ${e.toString().replaceAll('StateError: ', '')}')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateBatch(
    String productKey,
    String batchId,
    DateTime expiryDate,
    int quantity, {
    Map<String, dynamic>? existingProductData,
  }) async {
    // Validate expiry date
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    if (expiryOnly.isBefore(todayOnly) ||
        expiryOnly.isAtSameMomentAs(todayOnly)) {
      throw StateError(
          'Expiry date must be a future date. Cannot use expired or today\'s date.');
    }

    // Get existing product data if not provided
    Map<String, dynamic>? productData = existingProductData;
    if (productData == null) {
      final snapshot = await dbRef.child(productKey).get();
      if (!snapshot.exists || snapshot.value is! Map) {
        throw StateError('Product not found.');
      }
      productData = Map<String, dynamic>.from(snapshot.value as Map);
    }

    // Get or create batches map
    Map<String, dynamic> batches = {};
    if (productData['batches'] != null && productData['batches'] is Map) {
      batches = Map<String, dynamic>.from(productData['batches'] as Map);
    }

    // If batchId is empty, create a new batch (used when adding batch from dialog)
    if (batchId.isEmpty) {
      final now = DateTime.now();
      batchId =
          '${now.millisecondsSinceEpoch}_${(now.microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    }

    // Update or add batch
    batches[batchId] = {
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
    };

    // Calculate total quantity
    int totalQuantity = 0;
    batches.values.forEach((batch) {
      if (batch is Map && batch['quantity'] != null) {
        final qty = batch['quantity'] is num
            ? (batch['quantity'] as num).toInt()
            : int.tryParse(batch['quantity'].toString()) ?? 0;
        totalQuantity += qty;
      }
    });

    // Update product
    await dbRef.child(productKey).update({
      'batches': batches,
      'quantity': totalQuantity, // For backward compatibility
      'status': totalQuantity > 0 ? 'in_stock' : 'out_of_stock',
    });
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
                    if (product != null) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.inventory),
                        label: const Text('Manage Batches'),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          showBatchesDialog(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'Edit Product Info',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                    ],
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
                    if (product == null) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: quantityController,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final v = int.tryParse(value ?? '');
                          if (v == null || v < 0)
                            return 'Enter a valid quantity ≥ 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
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
                    ] else ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Note: To edit quantity and expiry date, use "Manage Batches" above.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      title: const Text('Requires prescription'),
                      value: requiresPrescription,
                      onChanged: (val) =>
                          setDialogState(() => requiresPrescription = val),
                    ),
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

                  // Validate expiry date and quantity only for new products
                  if (product == null) {
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
                  }

                  final data = {
                    'name': nameController.text.trim(),
                    'category': selectedCategory ?? 'Other',
                    'description': descriptionController.text.trim(),
                    'price': double.tryParse(priceController.text.trim()) ?? 0,
                    'requiresPrescription': requiresPrescription,
                  };

                  // Only add quantity and expiryDate for new products
                  if (product == null) {
                    data['quantity'] =
                        int.tryParse(quantityController.text.trim()) ?? 0;
                    data['expiryDate'] =
                        DateFormat('yyyy-MM-dd').format(expiryDate!);
                  }

                  try {
                    if (product == null) {
                      await addProduct(
                        data,
                        image: imageFile,
                        manualImageReference: imageReferenceController.text,
                      );
                    } else {
                      // Check if product name changed
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

                      // Preserve existing batches when updating product info
                      Map<String, dynamic>? existingBatches;
                      if (product['batches'] != null &&
                          product['batches'] is Map) {
                        existingBatches = Map<String, dynamic>.from(
                            product['batches'] as Map);
                      }

                      await updateProduct(
                        product['key'],
                        data,
                        image: imageFile,
                        manualImageReference: imageReferenceController.text,
                        oldImageUrl: oldImageUrl,
                        existingCreatedAt: product['createdAt'],
                        preserveBatches: existingBatches,
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
        _isDarkMode ? Colors.grey[900]! : const Color(0xFFB3E5FC);
    Color appBarColor =
        _isDarkMode ? Colors.grey[850]! : const Color(0xFF0288D1);

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
            icon: const Icon(Icons.person),
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
            icon: const Icon(Icons.logout),
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
            child: Row(
              children: [
                Expanded(
                  child:
                      buildButton("Add New Product", () => showProductDialog()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buildButton("Reports & Analytics", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PharmacistReportsPage(),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by name or category...",
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(height: 10),
          // AI Predictions Widget
          StreamBuilder(
            stream: dbRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                Map data = (snapshot.data!.snapshot.value as Map);
                List<Product> productList = [];
                data.forEach((key, value) {
                  if (value is Map) {
                    final map = Map<dynamic, dynamic>.from(value);
                    final ownerId = map['ownerId']?.toString() ?? user!.uid;
                    productList.add(Product.fromMap(
                      id: key.toString(),
                      ownerId: ownerId,
                      data: map,
                    ));
                  }
                });
                return _buildAIPredictionsWidget(productList);
              }
              return _buildAIPredictionsWidget([]);
            },
          ),
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

                      final expiryDateString = product['expiryDate'];
                      bool isExpired = false;

                      if (expiryDateString != null) {
                        final expiryDate =
                            DateTime.tryParse(expiryDateString.toString());
                        if (expiryDate != null) {
                          final today = DateTime.now();
                          final todayOnly =
                              DateTime(today.year, today.month, today.day);
                          final expiryOnly = DateTime(expiryDate.year,
                              expiryDate.month, expiryDate.day);

                          if (expiryOnly.isBefore(todayOnly)) {
                            isExpired = true;
                          }
                        }
                      }

                      return Card(
                        color: isExpired
                            ? Colors.grey[400] // <-- EXPIRED color
                            : (_isDarkMode ? Colors.grey[800] : Colors.white),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isExpired
                                ? Colors.grey // <-- EXPIRED border color
                                : (_isDarkMode
                                    ? Colors.blueGrey
                                    : const Color(0xFF0288D1)),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: imageWidget,
                            ),
                          ),
                          title: Text(
                            product['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration:
                                  isExpired ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${product['category']}",
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Price: ${product['price']} OMR",
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Builder(
                                  builder: (_) {
                                    // Display batches info if available
                                    String quantityExpiryText = '';
                                    if (product['batches'] != null &&
                                        product['batches'] is Map) {
                                      final batches = product['batches'] as Map;
                                      if (batches.isNotEmpty) {
                                        final batchCount = batches.length;
                                        quantityExpiryText =
                                            'Total Qty: ${product['quantity']} | Batches: $batchCount';
                                      } else {
                                        quantityExpiryText =
                                            'Qty: ${product['quantity']}';
                                      }
                                    } else if (product['expiryDate'] != null) {
                                      quantityExpiryText =
                                          "Qty: ${product['quantity']} | Expiry: ${product['expiryDate']}";
                                    } else {
                                      quantityExpiryText =
                                          "Qty: ${product['quantity']}";
                                    }
                                    return Text(
                                      quantityExpiryText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isExpired ? Colors.red : null,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.inventory),
                                color: Colors.blue,
                                tooltip: 'Manage Batches',
                                onPressed: () => showBatchesDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Theme.of(context).colorScheme.primary,
                                tooltip: 'Edit Product',
                                onPressed: () =>
                                    showProductDialog(product: product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Theme.of(context).colorScheme.error,
                                tooltip: 'Delete Product',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No products found.",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
