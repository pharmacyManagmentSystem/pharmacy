import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:intl/intl.dart';

class PharmacyOrdersPage extends StatefulWidget {
  final String pharmacyId;
  const PharmacyOrdersPage({super.key, required this.pharmacyId});

  @override
  State<PharmacyOrdersPage> createState() => _PharmacyOrdersPageState();
}

class _PharmacyOrdersPageState extends State<PharmacyOrdersPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  TextEditingController searchController = TextEditingController();
  String filterStatus = 'all'; // all, pending, accepted, rejected

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      DatabaseReference ref = DatabaseService.instance.ref('orders');
      DataSnapshot snapshot = await ref.get();

      List<Map<String, dynamic>> tempOrders = [];

      if (snapshot.exists) {
        Map data = snapshot.value as Map;
        data.forEach((key, value) {
          final order = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
          if (order['pharmacyId'] == widget.pharmacyId) {
            order['orderId'] = key;
            // Initialize acceptStatus if not present
            if (!order.containsKey('acceptStatus')) {
              // If status is awaiting_confirmation, set acceptStatus to pending
              if (order['status'] == 'awaiting_confirmation') {
                order['acceptStatus'] = 'pending';
              } else {
                order['acceptStatus'] = 'accepted'; // Legacy orders
              }
            }
            tempOrders.add(order);
          }
        });

        // ترتيب من الجديد إلى القديم
        tempOrders.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
          final bDate =
              DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
          return bDate.compareTo(aDate);
        });
      }

      setState(() {
        orders = tempOrders;
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(orders);

    // فلتر البحث
    if (searchController.text.isNotEmpty) {
      temp = temp
          .where((order) => order['customerName']
              .toString()
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    }

    // فلتر الحالة
    if (filterStatus != 'all') {
      temp =
          temp.where((order) => order['acceptStatus'] == filterStatus).toList();
    }

    setState(() {
      filteredOrders = temp;
    });
  }

  String formatItems(dynamic items) {
    if (items == null) return '-';
    if (items is Map) {
      return items.entries.map((e) {
        final item = e.value;
        if (item is Map) {
          String name = item['name']?.toString() ?? 'Unknown';
          String qty = item['quantity']?.toString() ?? '1';
          return '$name x$qty';
        } else {
          return e.value.toString();
        }
      }).join('\n');
    } else if (items is List) {
      return items.map((e) => formatItems(e)).join('\n');
    } else {
      return items.toString();
    }
  }

  String formatAddress(Map<String, dynamic>? address) {
    if (address == null) return '-';
    String house = address['houseNumber'] ?? '';
    String road = address['roadNumber'] ?? '';
    String additional = address['additionalDirections'] ?? '';
    return '$house, $road${additional.isNotEmpty ? ', $additional' : ''}';
  }

  Future<void> updateAcceptStatus(String orderId, String status) async {
    try {
      await DatabaseService.instance
          .ref('orders/$orderId')
          .update({'acceptStatus': status});
      int index = orders.indexWhere((o) => o['orderId'] == orderId);
      if (index != -1) {
        orders[index]['acceptStatus'] = status;
      }
      applyFilters();
    } catch (e) {
      debugPrint('Error updating acceptStatus: $e');
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final createdAt = order['createdAt'] != null
        ? DateTime.tryParse(order['createdAt'].toString())
        : null;
    final formattedDate = createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt)
        : '-';

    final itemsText = formatItems(order['items']);
    final addressText =
        formatAddress(order['address'] as Map<String, dynamic>?);

    String acceptStatus = order['acceptStatus'] ?? 'pending';

    Color borderColor;
    switch (acceptStatus) {
      case 'accepted':
        borderColor = Colors.green;
        break;
      case 'rejected':
        borderColor = Colors.red;
        break;
      default:
        borderColor = Colors.orange;
    }

    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          order['customerName'] ?? 'Unknown Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Order Status: $acceptStatus'),
        children: [
          ListTile(
              title: const Text('Order ID'),
              subtitle: Text(order['orderId'] ?? '-')),
          ListTile(
              title: const Text('Email'),
              subtitle: Text(order['customerEmail'] ?? '-')),
          ListTile(title: const Text('Address'), subtitle: Text(addressText)),
          ListTile(
              title: const Text('Payment Method'),
              subtitle: Text(order['paymentMethod'] ?? '-')),
          ListTile(
              title: const Text('Total'),
              subtitle: Text(order['total']?.toString() ?? '-')),
          ListTile(
              title: const Text('Created At'), subtitle: Text(formattedDate)),
          ListTile(title: const Text('Items'), subtitle: Text(itemsText)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: acceptStatus == 'accepted'
                      ? null
                      : () => updateAcceptStatus(order['orderId'], 'accepted'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Accept')),
              ElevatedButton(
                  onPressed: acceptStatus == 'rejected'
                      ? null
                      : () => updateAcceptStatus(order['orderId'], 'rejected'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reject')),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buildStatusFilterButtons() {
    List<String> statuses = ['all', 'pending', 'accepted', 'rejected'];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        children: statuses.map((status) {
          String label;
          switch (status) {
            case 'pending':
              label = 'Pending';
              break;
            case 'accepted':
              label = 'Accepted';
              break;
            case 'rejected':
              label = 'Rejected';
              break;
            default:
              label = 'All';
          }
          bool isSelected = filterStatus == status;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                filterStatus = status;
              });
              applyFilters();
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Orders'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by customer name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => applyFilters(),
                  ),
                ),
                buildStatusFilterButtons(),
                Expanded(
                  child: filteredOrders.isEmpty
                      ? const Center(child: Text('No orders found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return buildOrderCard(filteredOrders[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
