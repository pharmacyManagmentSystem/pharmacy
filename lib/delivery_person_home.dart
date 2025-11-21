import 'package:flutter/material.dart';
import 'login.dart';
import 'delivery_profile.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'package:intl/intl.dart';

import 'orderDetailsDeliveryPage.dart';

class DeliveryPersonHome extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const DeliveryPersonHome({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<DeliveryPersonHome> createState() => _DeliveryPersonHomeState();
}

class _DeliveryPersonHomeState extends State<DeliveryPersonHome> {
  bool isLoading = true;
  List<Map<String, dynamic>> acceptedOrders = [];

  @override
  void initState() {
    super.initState();
    fetchAcceptedOrders();
  }

  Future<void> fetchAcceptedOrders() async {
    try {
      DatabaseReference ref = DatabaseService.instance.ref('orders');
      DataSnapshot snapshot = await ref.get();

      List<Map<String, dynamic>> tempOrders = [];

      if (snapshot.exists) {
        Map data = snapshot.value as Map;
        data.forEach((key, value) {
          final orderMap = Map<String, dynamic>.from(value as Map);
          orderMap['orderId'] = key;
          // فقط الطلبات المقبولة
          if (orderMap['acceptStatus'] == 'accepted') {
            tempOrders.add(orderMap);
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
        acceptedOrders = tempOrders;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching accepted orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatAddress(Map<String, dynamic>? address) {
    if (address == null) return '-';
    String house = address['houseNumber'] ?? '';
    String road = address['roadNumber'] ?? '';
    String additional = address['additionalDirections'] ?? '';
    return '$house, $road${additional.isNotEmpty ? ', $additional' : ''}';
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final createdAt = order['createdAt'] != null
        ? DateTime.tryParse(order['createdAt'].toString())
        : null;
    final formattedDate = createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt)
        : '-';

    Map<String, dynamic>? addressMap;
    if (order['address'] != null && order['address'] is Map) {
      addressMap = Map<String, dynamic>.from(order['address'] as Map);
    }

    final addressText = formatAddress(addressMap);

    return Card(
      color: isDarkMode ? Colors.grey[800] : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDarkMode ? Colors.green.shade700 : Colors.green,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        onTap: () {
          // عند الضغط على الطلب
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailsDeliveryPage(orderId: order['orderId']),
            ),
          );
        },
        title: Text(
          order['customerName'] ?? 'Unknown',
          style: TextStyle(color: isDarkMode ? Colors.white : null),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address: $addressText',
              style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
            ),
            Text(
              'Total: ${order['total'] ?? '-'}',
              style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
            ),
            Text(
              'Payment: ${order['paymentMethod'] ?? '-'}',
              style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
            ),
            Text(
              'Created at: $formattedDate',
              style: TextStyle(color: isDarkMode ? Colors.grey[300] : null),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : null,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? Colors.grey[850] : const Color(0xFF0288D1),
        title: const Text("Delivery Person Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryPersonProfilePage(
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : acceptedOrders.isEmpty
              ? Center(
                  child: Text(
                    'No accepted orders',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: acceptedOrders.length,
                  itemBuilder: (context, index) {
                    return buildOrderCard(acceptedOrders[index]);
                  },
                ),
    );
  }
}
