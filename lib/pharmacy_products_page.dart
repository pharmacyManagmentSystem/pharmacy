import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'services/ai_shopping_list_service.dart';
import 'package:flutter/material.dart';
import 'models/product.dart';
import 'product_detail_page.dart';
import 'request_product_page.dart';
import 'localization/app_localizations.dart';

class PharmacyProductsPage extends StatefulWidget {
  const PharmacyProductsPage({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.pharmacyEmail,
  });

  final String pharmacyId;
  final String pharmacyName;
  final String pharmacyEmail;

  @override
  State<PharmacyProductsPage> createState() => _PharmacyProductsPageState();
}

class _PharmacyProductsPageState extends State<PharmacyProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  late DatabaseReference _productsRef;
  
  // AI Shopping List
  List<Product> _aiRecommendedProducts = [];
  bool _isLoadingAI = false;
  bool _showShoppingList = false;

  @override
  void initState() {
    super.initState();
    _productsRef =
        DatabaseService.instance.ref('products/${widget.pharmacyId}');
    _loadAIShoppingList();
  }
  
  Future<void> _loadAIShoppingList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isLoadingAI = true);
    
    try {
      // Load customer orders
      final ordersRef = DatabaseService.instance.ref('customer_orders/${user.uid}');
      final ordersSnapshot = await ordersRef.get();
      
      if (!ordersSnapshot.exists || ordersSnapshot.value is! Map) {
        setState(() => _isLoadingAI = false);
        return;
      }

      final ordersData = ordersSnapshot.value as Map;
      final List<Map<String, dynamic>> ordersList = [];
      
      ordersData.forEach((orderId, orderData) {
        if (orderData is Map) {
          ordersList.add({
            'orderId': orderId.toString(),
            'createdAt': orderData['createdAt']?.toString() ?? '',
            'items': orderData['items'] ?? {},
            'total': orderData['total'] ?? 0,
          });
        }
      });

      // Call AI Service
      final aiAnalysis = await _callAIService(user.uid, ordersList);
      
      if (aiAnalysis != null) {
        final frequentlyBought = aiAnalysis['frequently_bought'] as List? ?? [];
        final List<Product> recommendedProducts = [];
        
        // Load products that match AI recommendations and are in this pharmacy
        for (final item in frequentlyBought.take(5)) {
          if (item is Map) {
            final pharmacyId = item['pharmacyId']?.toString() ?? '';
            final productId = item['productId']?.toString() ?? '';
            
            // Only show products from this pharmacy
            if (pharmacyId == widget.pharmacyId && productId.isNotEmpty) {
              try {
                final productRef = DatabaseService.instance
                    .ref('products/$pharmacyId/$productId');
                final productSnapshot = await productRef.get();
                
                if (productSnapshot.exists && productSnapshot.value is Map) {
                  final productData = Map<dynamic, dynamic>.from(
                      productSnapshot.value as Map);
                  final product = Product.fromMap(
                    id: productId,
                    ownerId: pharmacyId,
                    data: productData,
                  );
                  
                  if (product.hasNonExpiredBatches && product.totalQuantity > 0) {
                    recommendedProducts.add(product);
                  }
                }
              } catch (e) {
                debugPrint('Error loading AI product: $e');
              }
            }
          }
        }
        
        setState(() {
          _aiRecommendedProducts = recommendedProducts;
          _isLoadingAI = false;
          _showShoppingList = recommendedProducts.isNotEmpty;
        });
      } else {
        setState(() => _isLoadingAI = false);
      }
    } catch (e) {
      debugPrint('Error loading AI shopping list: $e');
      setState(() => _isLoadingAI = false);
    }
  }
  
  Future<Map<String, dynamic>?> _callAIService(
    String customerId,
    List<Map<String, dynamic>> orders,
  ) async {
    // Use local AI service (works without Python)
    try {
      final analysis = await AIShoppingListService.analyzePurchaseHistory(
        customerId,
        orders,
      );
      return analysis;
    } catch (e) {
      debugPrint('Error calling AI service: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildProductImage(String path) {
    if (path.startsWith('data:')) {
      try {
        final parts = path.split(',');
        final base64Data = parts.length > 1 ? parts[1] : '';
        final bytes = base64Decode(base64Data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      }
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    } else {
      final fixedPath = path.startsWith('assets/') ? path : 'assets/$path';
      return Image.asset(
        fixedPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        actions: [
          IconButton(
            tooltip: loc.requestProduct,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestProductPage(
                    pharmacyId: widget.pharmacyId,
                    pharmacyName: widget.pharmacyName,
                    customerEmail: user.email ?? '',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            // AI Shopping List Card
            if (_isLoadingAI || _aiRecommendedProducts.isNotEmpty) ...[
              _buildShoppingListCard(loc),
              const SizedBox(height: 12),
            ],
            StreamBuilder<DatabaseEvent>(
              stream: _productsRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return Expanded(
                      child: Center(child: Text(loc.noProducts)));
                }

                final raw = snapshot.data!.snapshot.value;
                final List<Product> products = [];

                if (raw is Map) {
                  raw.forEach((key, value) {
                    if (value is Map) {
                      final map = Map<dynamic, dynamic>.from(value);
                      final ownerId =
                          map['ownerId']?.toString() ?? widget.pharmacyId;
                      products.add(Product.fromMap(
                        id: key.toString(),
                        ownerId: ownerId,
                        data: map,
                      ));
                    }
                  });
                }

                final categories = <String>{'All'}..addAll(products
                    .map((p) => p.category)
                    .where((c) => c.isNotEmpty)
                    .toSet());

                final filtered = products.where((p) {
                  final matchQuery = _query.isEmpty ||
                      p.name.toLowerCase().contains(_query.toLowerCase());
                  final matchCategory = _selectedCategory == 'All' ||
                      p.category == _selectedCategory;
                  final isAvailable = p.totalQuantity > 0;
                  // Hide expired products - only show products with non-expired batches
                  final isNotExpired = p.hasNonExpiredBatches;
                  return matchQuery && matchCategory && isAvailable && isNotExpired;
                }).toList()
                  ..sort((a, b) {
                    // Priority 1: Products expiring soon appear first
                    final aExpiringSoon = a.isExpiringSoon;
                    final bExpiringSoon = b.isExpiringSoon;
                    
                    if (aExpiringSoon && !bExpiringSoon) return -1;
                    if (!aExpiringSoon && bExpiringSoon) return 1;
                    
                    // Priority 2: Among expiring soon, sort by days until expiry (soonest first)
                    if (aExpiringSoon && bExpiringSoon) {
                      return a.daysUntilExpiry.compareTo(b.daysUntilExpiry);
                    }
                    
                    // Priority 3: Other products sorted alphabetically
                    return a.name.compareTo(b.name);
                  });

                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categories.map((category) {
                            final selected = category == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: selected,
                                onSelected: (_) => setState(
                                    () => _selectedCategory = category),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailPage(
                                      product: p,
                                      pharmacyName: widget.pharmacyName,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                                color: p.isExpiringSoon 
                                    ? Colors.orange.shade50 
                                    : null,
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: _buildProductImage(p.imageUrl),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            p.category,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${p.price.toStringAsFixed(2)} OMR',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (p.isExpiringSoon)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    loc.isArabic 
                                                        ? 'قريب من الانتهاء'
                                                        : 'Expiring Soon',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (p.isExpiringSoon)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.warning,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShoppingListCard(AppLocalizations loc) {
    if (_isLoadingAI) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.blue.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (_aiRecommendedProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          setState(() {
            _showShoppingList = !_showShoppingList;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic ? 'قائمة التسوق الذكية' : 'Smart Shopping List',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          loc.isArabic 
                              ? 'منتجات اشتريتها من قبل'
                              : 'Products you bought before',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showShoppingList 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
              if (_showShoppingList) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _aiRecommendedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _aiRecommendedProducts[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(
                                  product: product,
                                  pharmacyName: widget.pharmacyName,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    child: _buildProductImage(product.imageUrl),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${product.price.toStringAsFixed(2)} OMR',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
