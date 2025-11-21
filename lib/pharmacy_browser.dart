import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'models/pharmacy.dart';
import 'pharmacy_products_page.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: loc.searchPharmacies,
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
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.black54),
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
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
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
            ),
          ),
        ],
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
