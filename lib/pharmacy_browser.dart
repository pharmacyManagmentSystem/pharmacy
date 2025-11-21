import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'models/pharmacy.dart';
import 'models/product.dart';
import 'pharmacy_products_page.dart';
import 'product_detail_page.dart';
import 'localization/app_localizations.dart';

class PharmacyBrowser extends StatefulWidget {
  const PharmacyBrowser({super.key, required this.onThemeChanged});
  final Function(bool) onThemeChanged;

  @override
  State<PharmacyBrowser> createState() => _PharmacyBrowserState();
}

class _PharmacyBrowserState extends State<PharmacyBrowser> {
  final DatabaseReference _pharmaciesRef =
      DatabaseService.instance.ref('pharmacy/pharmacists');
  final DatabaseReference _productsRef =
      DatabaseService.instance.ref('products');
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _searchProducts = false; // Toggle between pharmacies and products

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _searchProducts 
                        ? (loc.isArabic ? 'ابحث عن المنتجات...' : 'Search products...')
                        : loc.searchPharmacies,
                    hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.black54),
                    prefixIcon: Icon(Icons.search,
                        color: isDarkMode ? Colors.grey[400] : Colors.black54),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: Icon(Icons.clear,
                                color: isDarkMode ? Colors.grey[400] : Colors.black54),
                          )
                        : null,
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [!_searchProducts, _searchProducts],
                onPressed: (index) {
                  setState(() {
                    _searchProducts = index == 1;
                    _query = '';
                    _searchController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: Colors.blue,
                color: Colors.blue,
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 80,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(loc.isArabic ? 'صيدليات' : 'Pharmacies'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(loc.isArabic ? 'منتجات' : 'Products'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _searchProducts
                ? _buildProductsSearch()
                : _buildPharmaciesList(            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmaciesList() {
    final loc = AppLocalizations.of(context)!;
    
    return StreamBuilder<DatabaseEvent>(
      stream: _pharmaciesRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(loc.somethingWentWrong));
        }
        if (!snapshot.hasData ||
            snapshot.data?.snapshot.value == null) {
          return Center(child: Text(loc.noPharmacies));
        }

        final raw = snapshot.data!.snapshot.value;
        if (raw is! Map) {
          return Center(child: Text(loc.error));
        }

        final pharmacies = raw.entries
            .map(
              (entry) => PharmacySummary.fromMap(
                entry.key.toString(),
                Map<dynamic, dynamic>.from(entry.value as Map),
              ),
            )
            .where(
              (p) => _query.isEmpty
                  ? true
                  : p.name
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      p.email
                          .toLowerCase()
                          .contains(_query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        if (pharmacies.isEmpty) {
          return Center(child: Text(loc.noResults));
        }

        return ListView.separated(
          itemCount: pharmacies.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _PharmacyCard(pharmacy: pharmacies[i]),
        );
      },
    );
  }

  Widget _buildProductsSearch() {
    final loc = AppLocalizations.of(context)!;
    
    return StreamBuilder<DatabaseEvent>(
      stream: _productsRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(loc.somethingWentWrong));
        }
        if (!snapshot.hasData ||
            snapshot.data?.snapshot.value == null) {
          return Center(child: Text(loc.noProducts));
        }

        final raw = snapshot.data!.snapshot.value;
        if (raw is! Map) {
          return Center(child: Text(loc.error));
        }

        final List<Map<String, dynamic>> allProducts = [];
        
        // Iterate through all pharmacies
        raw.forEach((pharmacyId, pharmacyProducts) {
          if (pharmacyProducts is Map) {
            pharmacyProducts.forEach((productId, productData) {
              if (productData is Map) {
                final productMap = Map<dynamic, dynamic>.from(productData);
                allProducts.add({
                  'pharmacyId': pharmacyId.toString(),
                  'productId': productId.toString(),
                  'data': productMap,
                });
              }
            });
          }
        });

        // Filter by search query
        final filtered = allProducts.where((item) {
          if (_query.isEmpty) return true;
          final name = item['data']['name']?.toString().toLowerCase() ?? '';
          final category = item['data']['category']?.toString().toLowerCase() ?? '';
          final queryLower = _query.toLowerCase();
          return name.contains(queryLower) || category.contains(queryLower);
        }).toList();

        // Filter out expired products
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        
        final validProducts = filtered.where((item) {
          final data = item['data'] as Map;
          
          // Check batches first
          if (data['batches'] != null && data['batches'] is Map) {
            final batches = data['batches'] as Map;
            if (batches.isNotEmpty) {
              bool hasNonExpired = false;
              batches.forEach((key, value) {
                if (value is Map) {
                  final batchExpiryStr = value['expiryDate']?.toString();
                  if (batchExpiryStr != null) {
                    final batchExpiry = DateTime.tryParse(batchExpiryStr);
                    if (batchExpiry != null) {
                      final batchExpiryOnly = DateTime(
                        batchExpiry.year, 
                        batchExpiry.month, 
                        batchExpiry.day
                      );
                      if (batchExpiryOnly.isAfter(todayOnly)) {
                        hasNonExpired = true;
                      }
                    }
                  }
                }
              });
              return hasNonExpired;
            }
          }
          
          // Legacy: check single expiryDate
          if (data['expiryDate'] != null) {
            final expiryDateStr = data['expiryDate']?.toString();
            if (expiryDateStr != null) {
              final expiryDate = DateTime.tryParse(expiryDateStr);
              if (expiryDate != null) {
                final expiryOnly = DateTime(
                  expiryDate.year, 
                  expiryDate.month, 
                  expiryDate.day
                );
                return expiryOnly.isAfter(todayOnly);
              }
            }
          }
          
          // No expiry date = valid
          return true;
        }).toList();

        if (validProducts.isEmpty) {
          return Center(child: Text(loc.noResults));
        }

        return ListView.separated(
          itemCount: validProducts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = validProducts[index];
            final productData = item['data'] as Map;
            final pharmacyId = item['pharmacyId'] as String;
            final productId = item['productId'] as String;
            
            try {
              final product = Product.fromMap(
                id: productId,
                ownerId: pharmacyId,
                data: productData,
              );
              
              return _ProductSearchCard(
                product: product,
                pharmacyId: pharmacyId,
              );
            } catch (e) {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}

class _ProductSearchCard extends StatelessWidget {
  const _ProductSearchCard({
    required this.product,
    required this.pharmacyId,
  });

  final Product product;
  final String pharmacyId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Get pharmacy name
          String pharmacyName = 'Pharmacy';
          try {
            final pharmacyRef = DatabaseService.instance
                .ref('pharmacy/pharmacists/$pharmacyId');
            final snapshot = await pharmacyRef.once();
            if (snapshot.snapshot.exists) {
              final data = snapshot.snapshot.value as Map?;
              pharmacyName = data?['name']?.toString() ?? 'Pharmacy';
            }
          } catch (e) {
            debugPrint('Error getting pharmacy name: $e');
          }
          
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: product,
                pharmacyName: pharmacyName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      )
                    : const Icon(Icons.image_not_supported),
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price} OMR',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // View Button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: () async {
                  // Get pharmacy name
                  String pharmacyName = 'Pharmacy';
                  try {
                    final pharmacyRef = DatabaseService.instance
                        .ref('pharmacy/pharmacists/$pharmacyId');
                    final snapshot = await pharmacyRef.once();
                    if (snapshot.snapshot.exists) {
                      final data = snapshot.snapshot.value as Map?;
                      pharmacyName = data?['name']?.toString() ?? 'Pharmacy';
                    }
                  } catch (e) {
                    debugPrint('Error getting pharmacy name: $e');
                  }
                  
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        product: product,
                        pharmacyName: pharmacyName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({required this.pharmacy});
  final PharmacySummary pharmacy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: pharmacy.imageUrl.isNotEmpty
                      ? (pharmacy.imageUrl.startsWith('data:')
                          ? MemoryImage(base64Decode(
                              pharmacy.imageUrl.split(',').length > 1
                                  ? pharmacy.imageUrl.split(',')[1]
                                  : ''))
                          : NetworkImage(pharmacy.imageUrl)) as ImageProvider
                      : null,
                  child: pharmacy.imageUrl.isEmpty
                      ? const Icon(Icons.local_pharmacy,
                          size: 30, color: Colors.blue)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pharmacy.name,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color)),
                      const SizedBox(height: 4),
                      Text(pharmacy.email,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color)),
                      if (pharmacy.address.isNotEmpty)
                        Text(pharmacy.address,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_basket_outlined),
                label: Text(loc.isArabic ? 'ابدأ التسوق' : 'Start shopping'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PharmacyProductsPage(
                        pharmacyId: pharmacy.uid,
                        pharmacyName: pharmacy.name,
                        pharmacyEmail: pharmacy.email,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
