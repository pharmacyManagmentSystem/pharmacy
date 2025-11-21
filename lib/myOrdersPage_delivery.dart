import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'orderDetailsDeliveryPage.dart';
import 'services/database_service.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> myOrders = [];
  String deliveryPersonId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    fetchMyOrders();
  }

  Future<void> fetchMyOrders() async {
    try {
      DatabaseReference ref = DatabaseService.instance.ref('orders');
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> ordersMap = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> ordersList = [];

        ordersMap.forEach((key, value) {
          Map<String, dynamic> order = Map<String, dynamic>.from(value);
          order['id'] = key;
          if (order['assignedTo'] == deliveryPersonId) {
            ordersList.add(order);
          }
        });

        // ترتيب من الأحدث إلى الأقدم حسب createdAt
        ordersList.sort((a, b) {
          String aTime = a['createdAt'] ?? '';
          String bTime = b['createdAt'] ?? '';
          return bTime.compareTo(aTime);
        });

        setState(() {
          myOrders = ordersList;
          isLoading = false;
        });
      } else {
        setState(() {
          myOrders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching my orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    String status = order['status'] ?? 'pending';
    Color statusColor;

    switch (status) {
      case 'accept':
        statusColor = Colors.orange;
        break;
      case 'delivering':
        statusColor = Colors.blue;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        title: Text(order['customerName'] ?? 'Unknown Customer'),
        subtitle: Text('Total: ${order['total'] ?? '-'}\nStatus: $status'),
        trailing: Icon(Icons.arrow_forward, color: statusColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailsDeliveryPage(orderId: order['id']),
            ),
          ).then((_) => fetchMyOrders()); // تحديث القائمة بعد العودة
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myOrders.isEmpty
          ? const Center(child: Text('No orders assigned to you'))
          : RefreshIndicator(
        onRefresh: fetchMyOrders,
        child: ListView.builder(
          itemCount: myOrders.length,
          itemBuilder: (context, index) {
            return buildOrderCard(myOrders[index]);
          },
        ),
      ),
    );
  }
}
