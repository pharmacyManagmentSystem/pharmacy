import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/storage_service.dart';
import 'services/product_recommendations_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'models/product.dart';
import 'models/cart_item.dart';
import 'state/customer_app_state.dart';
import 'localization/app_localizations.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.pharmacyName,
  });

  final Product product;
  final String pharmacyName;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ImagePicker _picker = ImagePicker();
  String? _prescriptionUrl;
  bool _uploading = false;
  List<Product> _recommendations = [];
  bool _loadingRecommendations = false;
  int _quantity = 1;
  int _availableQuantity = 999; // Initialize with high value to allow adding until real value is loaded

  int _getAvailableQuantity(Product product) {
    final now = DateTime.now();
    if (product.batches != null && product.batches!.isNotEmpty) {
      // Sum only non-expired batches
      final nonExpiredBatches = product.batches!
          .where((batch) => batch.expiryDate.isAfter(now))
          .toList();
      final total = nonExpiredBatches.fold(0, (sum, batch) => sum + batch.quantity);
      // If total is 0, check if there are any batches at all (even expired)
      // This handles cases where product might have batches but all expired
      if (total == 0 && product.batches!.isNotEmpty) {
        // All batches expired, return 0
        return 0;
      }
      return total > 0 ? total : 999; // Default to 999 if somehow 0
    }
    // Legacy: check if expiry date is in the future
    if (product.expiryDate != null) {
      if (product.expiryDate!.isAfter(now)) {
        final qty = product.quantity ?? 0;
        return qty > 0 ? qty : 999; // Default to 999 if 0
      } else {
        // Expired
        return 0;
      }
    }
    // If no expiry date, return total quantity
    final totalQty = product.totalQuantity;
    return totalQty > 0 ? totalQty : 999; // If no quantity info, allow adding
  }

  Future<void> _uploadPrescription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      final storageService = StorageService();
      final dataUrl = await storageService.uploadImageToDatabase(
        file,
        'prescriptions/${user.uid}',
      );
      setState(() => _prescriptionUrl = dataUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  Widget _buildProductImage(String path) {
    if (path.startsWith('data:')) {
      try {
        final parts = path.split(',');
        final base64Data = parts.length > 1 ? parts[1] : '';
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 60);
      }
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
      );
    } else if (path.contains('assets/') ||
        path.endsWith('.jpg') ||
        path.endsWith('.png')) {
      final fixedPath = path.startsWith('assets/') ? path : 'assets/$path';
      return Image.asset(
        fixedPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 60),
      );
    } else {
      return const Icon(Icons.image_not_supported, size: 60);
    }
  }

  void _loadCurrentQuantityFromCart(BuildContext context) {
    final state = Provider.of<CustomerAppState>(context, listen: false);
    CartItem? existingItem;
    try {
      existingItem = state.cartItems
          .firstWhere((item) => item.product.id == widget.product.id);
    } catch (_) {
      existingItem = null;
    }
    
    // Calculate available quantity
    final availableQty = _getAvailableQuantity(widget.product);
    final finalAvailableQty = availableQty > 0 ? availableQty : 999; // Default to 999 if 0
    
    if (existingItem != null) {
      setState(() {
        _quantity = existingItem!.quantity;
        _availableQuantity = finalAvailableQty;
      });
    } else {
      setState(() {
        _quantity = 1;
        _availableQuantity = finalAvailableQty;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize available quantity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final availableQty = _getAvailableQuantity(widget.product);
        final finalAvailableQty = availableQty > 0 ? availableQty : 999;
        setState(() {
          _availableQuantity = finalAvailableQty;
        });
        _loadCurrentQuantityFromCart(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildProductImage(p.imageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${loc.category}: ${p.category}'),
          const SizedBox(height: 8),
          Text(
            '${loc.price}: ${p.price.toStringAsFixed(2)} OMR',
            style: const TextStyle(color: Colors.green, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(p.description.isNotEmpty
              ? p.description
              : (loc.isArabic ? 'لا يوجد وصف متاح.' : 'No description available.')),
          const SizedBox(height: 20),
          if (p.requiresPrescription)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prescriptionUrl == null
                      ? loc.prescriptionRequired
                      : (loc.isArabic ? 'تم رفع الوصفة.' : 'Prescription uploaded.'),
                  style: TextStyle(
                    color: _prescriptionUrl == null ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _uploadPrescription,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(_prescriptionUrl == null
                      ? loc.uploadPrescription
                      : (loc.isArabic ? 'استبدال' : 'Replace')),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Quantity Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.isArabic ? 'الكمية:' : 'Quantity:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                      icon: const Icon(Icons.remove),
                      color: _quantity > 1 ? Colors.blue : Colors.grey,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Recalculate available quantity in case it changed
                        final availableQty = _getAvailableQuantity(widget.product);
                        final finalAvailableQty = availableQty > 0 ? availableQty : 999;
                        
                        // Update available quantity
                        setState(() {
                          _availableQuantity = finalAvailableQty;
                        });
                        
                        // Check if we can increment
                        if (_quantity < finalAvailableQty) {
                          setState(() {
                            _quantity++;
                          });
                        } else {
                          // Show message if at limit
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.isArabic
                                    ? 'الكمية المتاحة: $finalAvailableQty'
                                    : 'Available quantity: $finalAvailableQty',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                      color: _quantity < _availableQuantity
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<CustomerAppState>(
            builder: (context, state, _) => FilledButton(
              onPressed: () async {
                if (p.requiresPrescription && _prescriptionUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(loc.isArabic 
                            ? 'يرجى رفع الوصفة الطبية أولاً.'
                            : 'Please upload a prescription first.')),
                  );
                  return;
                }

                if (state.currentPharmacyId != null &&
                    state.currentPharmacyId != p.ownerId) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(loc.isArabic ? 'بدء سلة جديدة؟' : 'Start new cart?'),
                      content: Text(
                        loc.isArabic
                            ? 'سلتك الحالية تحتوي على منتجات من "${state.currentPharmacyName}".\nهل تريد بدء سلة جديدة من "${widget.pharmacyName}"؟'
                            : 'Your current cart has items from "${state.currentPharmacyName}".\nDo you want to start a new cart from "${widget.pharmacyName}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(loc.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(loc.isArabic ? 'ابدأ' : 'Start'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  state.clearCart();
                }

                // Check if product already exists in cart
                CartItem? existingItem;
                try {
                  existingItem = state.cartItems
                      .firstWhere((item) => item.product.id == p.id);
                } catch (_) {
                  existingItem = null;
                }
                
                bool added = false;
                if (existingItem != null) {
                  // Product exists in cart - update to the selected quantity
                  added = await state.updateQuantity(p.id, _quantity);
                } else {
                  // Add new product to cart
                  added = await state.addProductToCart(
                    p,
                    prescriptionUrl: _prescriptionUrl,
                    pharmacyName: widget.pharmacyName,
                  );
                  
                  if (added && _quantity > 1) {
                    // Update quantity if more than 1
                    added = await state.updateQuantity(p.id, _quantity);
                  }
                }

                if (added) {
                  // Load recommendations after adding to cart
                  setState(() => _loadingRecommendations = true);
                  final recommendations = await ProductRecommendationsService
                      .getRecommendations(addedProduct: p, maxRecommendations: 3);
                  setState(() {
                    _recommendations = recommendations;
                    _loadingRecommendations = false;
                  });
                  
                  // Don't reset quantity - keep it as the current quantity in cart
                  // This way if user comes back, they see the updated quantity
                }

                if (mounted) {
                  final quantityAdded = _quantity;
                  final wasExisting = existingItem != null;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added
                            ? (wasExisting
                                ? (loc.isArabic 
                                    ? 'تم إضافة $quantityAdded إلى السلة' 
                                    : 'Added $quantityAdded to cart')
                                : (loc.isArabic 
                                    ? 'تم إضافة $quantityAdded ${p.name} إلى السلة' 
                                    : '$quantityAdded ${p.name} added to cart'))
                            : (loc.isArabic ? 'تعذر إضافة المنتج إلى السلة.' : 'Could not add product to cart.'),
                      ),
                    ),
                  );
                }
              },
              child: Text(loc.addToCart),
            ),
          ),
          // Product Recommendations Section
          if (_recommendations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(thickness: 1, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              loc.isArabic ? 'قد يعجبك أيضاً' : 'You might also like',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  final recommendedProduct = _recommendations[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(
                                product: recommendedProduct,
                                pharmacyName: widget.pharmacyName,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: _buildProductImage(recommendedProduct.imageUrl),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recommendedProduct.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${recommendedProduct.price.toStringAsFixed(2)} OMR',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final state = Provider.of<CustomerAppState>(
                                          context,
                                          listen: false,
                                        );
                                        final added = await state.addProductToCart(
                                          recommendedProduct,
                                          pharmacyName: widget.pharmacyName,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                added
                                                    ? (loc.isArabic
                                                        ? 'تمت الإضافة'
                                                        : 'Added to cart')
                                                    : (loc.isArabic
                                                        ? 'فشلت الإضافة'
                                                        : 'Failed to add'),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                                      label: Text(
                                        loc.isArabic ? 'أضف' : 'Add',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (_loadingRecommendations) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
