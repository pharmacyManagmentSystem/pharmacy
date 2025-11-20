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
          final aDate = DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
          final bDate = DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
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
    final createdAt = order['createdAt'] != null
        ? DateTime.tryParse(order['createdAt'].toString())
        : null;
    final formattedDate =
    createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt) : '-';

    Map<String, dynamic>? addressMap;
    if (order['address'] != null && order['address'] is Map) {
      addressMap = Map<String, dynamic>.from(order['address'] as Map);
    }

    final addressText = formatAddress(addressMap);

    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        onTap: () {
          // عند الضغط على الطلب
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsDeliveryPage(orderId: order['orderId']),
            ),
          );
        },
        title: Text(order['customerName'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: $addressText'),
            Text('Total: ${order['total'] ?? '-'}'),
            Text('Payment: ${order['paymentMethod'] ?? '-'}'),
            Text('Created at: $formattedDate'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  builder: (context) => Login(onThemeChanged: widget.onThemeChanged),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : acceptedOrders.isEmpty
          ? const Center(child: Text('No accepted orders'))
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
