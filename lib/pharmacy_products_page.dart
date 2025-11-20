import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'models/product.dart';
import 'product_detail_page.dart';
import 'request_product_page.dart';

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

  @override
  void initState() {
    super.initState();
    _productsRef =
        DatabaseService.instance.ref('products/${widget.pharmacyId}');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        actions: [
          IconButton(
            tooltip: 'Request unavailable product',
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
                hintText: 'Search products...',
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
            StreamBuilder<DatabaseEvent>(
              stream: _productsRef.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Expanded(
                      child: Center(child: Text('No products available.')));
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
                  final isAvailable = p.quantity > 0;
                  return matchQuery && matchCategory && isAvailable;
                }).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

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
                                child: Padding(
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
                                      ),
                                      Text(
                                        p.category,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      Text(
                                        '${p.price.toStringAsFixed(2)} OMR',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
