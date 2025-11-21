import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'state/customer_app_state.dart';
import 'services/database_service.dart';
import 'services/product_recommendations_service.dart';
import 'models/product.dart';
import 'product_detail_page.dart';
import 'location_capture_page.dart';
import 'localization/app_localizations.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({super.key});

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  List<Product> _recommendations = [];
  bool _loadingRecommendations = false;
  String? _lastCartHash; // Track cart state to avoid reloading unnecessarily

  String _getCartHash(List<Product> cartProducts) {
    if (cartProducts.isEmpty) return 'empty';
    return cartProducts.map((p) => p.id).join(',');
  }

  Future<void> _loadRecommendations(List<Product> cartProducts) async {
    if (cartProducts.isEmpty) {
      setState(() {
        _recommendations = [];
        _loadingRecommendations = false;
        _lastCartHash = 'empty';
      });
      return;
    }

    // Check if cart hasn't changed
    final currentHash = _getCartHash(cartProducts);
    if (_lastCartHash == currentHash && _recommendations.isNotEmpty) {
      return; // Don't reload if cart hasn't changed
    }

    setState(() {
      _loadingRecommendations = true;
      _lastCartHash = currentHash;
    });

    // Get recommendations based on the last added product or most recent product
    final lastProduct = cartProducts.last;
    final recommendations = await ProductRecommendationsService.getRecommendations(
      addedProduct: lastProduct,
      maxRecommendations: 3,
    );

    // Filter out products already in cart
    final cartProductIds = cartProducts.map((p) => p.id).toSet();
    final filteredRecommendations = recommendations
        .where((p) => !cartProductIds.contains(p.id))
        .take(3)
        .toList();

    if (mounted) {
      setState(() {
        _recommendations = filteredRecommendations;
        _loadingRecommendations = false;
      });
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
        path.endsWith('.png') ||
        path.endsWith('.jpeg')) {
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


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    return Consumer<CustomerAppState>(
      builder: (context, state, _) {
        final items = state.cartItems;
        final hasItems = items.isNotEmpty;
        final pharmacyId = state.currentPharmacyId ?? '';
        final pharmacyName = state.currentPharmacyName ?? '';
        final cartProducts = items.map((item) => item.product).toList();

        // Load recommendations when cart changes (only if cart actually changed)
        final currentHash = _getCartHash(cartProducts);
        if (_lastCartHash != currentHash) {
          // Use a small delay to avoid rapid reloading
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _getCartHash(cartProducts) == currentHash) {
              _loadRecommendations(cartProducts);
            }
          });
        }

        return Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[900] : null,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: hasItems
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length + (_recommendations.isNotEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show recommendations section after cart items
                            if (index == items.length) {
                              return _buildRecommendationsSection(
                                context,
                                loc,
                                state,
                                pharmacyName,
                              );
                            }
                            final item = items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.blue.shade900
                                                .withOpacity(0.3)
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: item.product.imageUrl.isNotEmpty
                                            ? _buildProductImage(item.product.imageUrl)
                                            : const Center(
                                                child: Icon(
                                                    Icons.medication_outlined)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item.product.price.toStringAsFixed(2)} OMR',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (item.prescriptionUrl != null)
                                            Text(
                                              loc.prescriptionAttached,
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (item.requestId != null)
                                            StreamBuilder<DatabaseEvent>(
                                              stream: DatabaseService.instance
                                                  .customerCartRef(context
                                                          .read<
                                                              CustomerAppState>()
                                                          .currentUserId ??
                                                      '')
                                                  .child(item.requestId!)
                                                  .onValue,
                                              builder: (context, snapshot) {
                                                bool isApproved = false;
                                                if (snapshot.hasData &&
                                                    snapshot.data!.snapshot
                                                        .value is Map) {
                                                  final data = snapshot.data!
                                                      .snapshot.value as Map;
                                                  isApproved = data[
                                                              'approved'] ==
                                                          true ||
                                                      data['status'] ==
                                                          'approved' ||
                                                      data['pendingApproval'] ==
                                                          false;
                                                }
                                                return Text(
                                                  isApproved
                                                      ? loc.approved
                                                      : loc.pendingApproval,
                                                  style: TextStyle(
                                                    color: isApproved
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () async {
                                                final success =
                                                    await state.updateQuantity(
                                                  item.product.id,
                                                  item.quantity - 1,
                                                );
                                                if (!success) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Unable to update quantity')),
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                  Icons.remove_circle_outline),
                                              iconSize: 20,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                final success =
                                                    await state.updateQuantity(
                                                  item.product.id,
                                                  item.quantity + 1,
                                                );
                                                if (!success) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          '${loc.insufficientStock}. ${loc.availableStock(item.product.totalQuantity)}'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                  Icons.add_circle_outline),
                                              iconSize: 20,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.red),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: GestureDetector(
                                            onTap: () => state
                                                .removeItem(item.product.id),
                                            child: Text(
                                              loc.remove,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                loc.emptyCart,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                loc.addItemsToCart,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.total,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.cartTotal.toStringAsFixed(2)} OMR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.greenAccent
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: hasItems
                              ? () async {
                                  final isApproved =
                                      await state.verifyApprovalStatus();
                                  if (!isApproved) {
                                    if (!context.mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(loc.pendingApproval),
                                        content: Text(
                                            loc.isArabic 
                                              ? 'بعض العناصر في سلتك تحتاج موافقة الصيدلي. يرجى الانتظار قبل المتابعة.'
                                              : 'Some items in your cart require pharmacist approval. Please wait for approval before proceeding to checkout.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(loc.ok)),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LocationCapturePage(
                                        pharmacyId: pharmacyId,
                                        pharmacyName: pharmacyName,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasItems
                                ? (isDarkMode
                                    ? Colors.blue.shade700
                                    : Colors.blue)
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            loc.checkout,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    AppLocalizations loc,
    CustomerAppState state,
    String pharmacyName,
  ) {
    if (_loadingRecommendations) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('recommendations_section'),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(thickness: 1, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              loc.isArabic ? 'قد يعجبك أيضاً' : 'You might also like',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _recommendations.length,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final recommendedProduct = _recommendations[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            product: recommendedProduct,
                            pharmacyName: pharmacyName,
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
                                    final added = await state.addProductToCart(
                                      recommendedProduct,
                                      pharmacyName: pharmacyName,
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
        const SizedBox(height: 16),
        ],
      ),
    );
  }
}
