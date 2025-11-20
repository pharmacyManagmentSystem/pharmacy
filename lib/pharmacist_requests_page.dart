import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PharmacistRequestsPage extends StatefulWidget {
  const PharmacistRequestsPage({super.key, required this.pharmacyId});

  final String pharmacyId;

  @override
  State<PharmacistRequestsPage> createState() => _PharmacistRequestsPageState();
}

class _PharmacistRequestsPageState extends State<PharmacistRequestsPage> {
  late final DatabaseReference _requestsRef;

  @override
  void initState() {
    super.initState();
    _requestsRef =
        DatabaseService.instance.ref('product_requests/${widget.pharmacyId}');
  }

  Future<void> _rejectRequest(_ProductRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject request'),
        content: const Text('Are you sure you want to reject this request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _requestsRef.child(request.id).remove();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: $e')),
      );
    }
  }

  void _addProductFromRequest(_ProductRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddRequestedProductPage(
          pharmacyId: widget.pharmacyId,
          request: request,
          requestsRef: _requestsRef,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requested products')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DatabaseEvent>(
          stream: _requestsRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Unable to load requests.'));
            }

            final data = snapshot.data?.snapshot.value;
            if (data == null) {
              return const Center(child: Text('No requests yet.'));
            }

            final requests = _parseRequests(data);
            if (requests.isEmpty) {
              return const Center(child: Text('No requests yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final displayIndex = index + 1;
                return _RequestCard(
                  indexLabel: '${_ordinal(displayIndex)} Request',
                  request: request,
                  onReject: () => _rejectRequest(request),
                  onAddProduct: () => _addProductFromRequest(request),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.indexLabel,
    required this.request,
    required this.onReject,
    required this.onAddProduct,
  });

  final String indexLabel;
  final _ProductRequest request;
  final VoidCallback onReject;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1976D2), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              indexLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Form: ${request.id.substring(0, request.id.length > 6 ? 6 : request.id.length)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _DetailLine(label: 'Product', value: request.productName),
            _DetailLine(label: 'Customer', value: request.customerName),
            _DetailLine(label: 'Email', value: request.customerEmail),
            _DetailLine(label: 'Quantity', value: request.quantity),
            if (request.notes.isNotEmpty)
              _DetailLine(label: 'Notes', value: request.notes),
            if (request.createdAt != null)
              _DetailLine(
                label: 'Requested',
                value: DateFormat.yMMMd()
                    .add_jm()
                    .format(request.createdAt!.toLocal()),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onAddProduct,
                    child: const Text('Add the Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        value.isEmpty ? label : '$label: $value',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

List<_ProductRequest> _parseRequests(Object raw) {
  final items = <_ProductRequest>[];

  void add(Map<dynamic, dynamic> map, String id) {
    items.add(
      _ProductRequest.fromMap(
        id: id,
        data: map,
      ),
    );
  }

  if (raw is Map) {
    raw.forEach((key, value) {
      if (value is Map) {
        add(Map<dynamic, dynamic>.from(value), key.toString());
      }
    });
  } else if (raw is List) {
    for (var i = 0; i < raw.length; i++) {
      final value = raw[i];
      if (value is Map) {
        add(Map<dynamic, dynamic>.from(value), i.toString());
      }
    }
  }

  items.sort((a, b) => b.createdAtValue.compareTo(a.createdAtValue));
  return items;
}

String _ordinal(int number) {
  if (number >= 11 && number <= 13) {
    return '${number}th';
  }
  switch (number % 10) {
    case 1:
      return '${number}st';
    case 2:
      return '${number}nd';
    case 3:
      return '${number}rd';
    default:
      return '${number}th';
  }
}

class _ProductRequest {
  const _ProductRequest({
    required this.id,
    required this.productName,
    required this.customerName,
    required this.customerEmail,
    required this.quantity,
    required this.notes,
    required this.createdAt,
    required this.createdAtValue,
  });

  factory _ProductRequest.fromMap({
    required String id,
    required Map<dynamic, dynamic> data,
  }) {
    DateTime? createdAt;
    int createdAtValue = 0;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is num) {
      createdAtValue = rawCreatedAt.toInt();
      createdAt =
          DateTime.fromMillisecondsSinceEpoch(createdAtValue, isUtc: true);
    } else if (rawCreatedAt is String) {
      final parsedNumber = int.tryParse(rawCreatedAt);
      if (parsedNumber != null) {
        createdAtValue = parsedNumber;
        createdAt =
            DateTime.fromMillisecondsSinceEpoch(createdAtValue, isUtc: true);
      } else {
        createdAt = DateTime.tryParse(rawCreatedAt);
        createdAtValue = createdAt?.millisecondsSinceEpoch ?? 0;
      }
    }

    return _ProductRequest(
      id: id,
      productName: data['productName']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      customerEmail: data['customerEmail']?.toString() ?? '',
      quantity: data['quantity']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      createdAt: createdAt,
      createdAtValue: createdAtValue,
    );
  }

  final String id;
  final String productName;
  final String customerName;
  final String customerEmail;
  final String quantity;
  final String notes;
  final DateTime? createdAt;
  final int createdAtValue;
}

class _AddRequestedProductPage extends StatefulWidget {
  const _AddRequestedProductPage({
    required this.pharmacyId,
    required this.request,
    required this.requestsRef,
  });

  final String pharmacyId;
  final _ProductRequest request;
  final DatabaseReference requestsRef;

  @override
  State<_AddRequestedProductPage> createState() =>
      _AddRequestedProductPageState();
}

class _AddRequestedProductPageState extends State<_AddRequestedProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _requiresPrescription = false;
  String _category = 'Other';
  bool _submitting = false;

  static const _categories = [
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.request.productName);
    _quantityController.text = widget.request.quantity;
    _descriptionController.text = widget.request.notes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final price = double.parse(_priceController.text.trim());
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
      final productId = DateTime.now().millisecondsSinceEpoch.toString();
      final productName = _nameController.text.trim();

      final productsRef =
          DatabaseService.instance.ref('products/${widget.pharmacyId}');
      final snapshot = await productsRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final existingProducts = snapshot.value as Map;
        for (var entry in existingProducts.entries) {
          final existingName =
              entry.value['name']?.toString().trim().toLowerCase();
          if (existingName == productName.toLowerCase()) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'A product with the name "$productName" already exists. Duplicate product names are not allowed.')),
            );
            setState(() => _submitting = false);
            return;
          }
        }
      }

      final productData = {
        'name': productName,
        'description': _descriptionController.text.trim(),
        'category': _category,
        'price': price,
        'quantity': quantity,
        'requiresPrescription': _requiresPrescription,
        'imageUrl': '',
        'ownerId': widget.pharmacyId,
        'createdAt': ServerValue.timestamp,
        'status': quantity > 0 ? 'in_stock' : 'out_of_stock',
      };

      await DatabaseService.instance
          .ref('products/${widget.pharmacyId}/$productId')
          .set(productData);

      await widget.requestsRef.child(widget.request.id).remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add requested product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter product name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (OMR)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter product price';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categories.contains(_category) ? _category : 'Other',
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Requires prescription'),
                value: _requiresPrescription,
                onChanged: (value) =>
                    setState(() => _requiresPrescription = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
