import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';

class OrderDetailsDeliveryPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsDeliveryPage({super.key, required this.orderId});

  @override
  State<OrderDetailsDeliveryPage> createState() =>
      _OrderDetailsDeliveryPageState();
}

class _OrderDetailsDeliveryPageState extends State<OrderDetailsDeliveryPage> {
  bool isLoading = true;
  Map<String, dynamic>? orderData;
  String selectedStatus = '';
  String deliveryPersonId = FirebaseAuth.instance.currentUser!.uid;

  final List<String> statusOptions = [
    'delivering',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      DatabaseReference ref =
      DatabaseService.instance.ref('orders/${widget.orderId}');
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        setState(() {
          orderData = Map<String, dynamic>.from(snapshot.value as Map);
          selectedStatus = orderData?['status'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Accept order
  Future<void> acceptOrder() async {
    try {
      await DatabaseService.instance
          .ref('orders/${widget.orderId}')
          .update({'status': 'accept', 'assignedTo': deliveryPersonId});

      setState(() {
        selectedStatus = 'accept';
        orderData?['assignedTo'] = deliveryPersonId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting order: $e')),
      );
    }
  }

  // Reject order
  Future<void> rejectOrder() async {
    try {
      await DatabaseService.instance
          .ref('orders/${widget.orderId}')
          .update({'status': 'pending', 'assignedTo': null});

      setState(() {
        selectedStatus = 'pending';
        orderData?['assignedTo'] = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order rejected!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting order: $e')),
      );
    }
  }

  // Update order status (delivering / delivered)
  Future<void> updateStatus(String status) async {
    try {
      await DatabaseService.instance
          .ref('orders/${widget.orderId}')
          .update({'status': status});

      setState(() {
        selectedStatus = status;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to "$status"')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (orderData == null) {
      return const Scaffold(
          body: Center(child: Text('Order not found')));
    }

    // Block if assigned to someone else
    if (orderData?['assignedTo'] != null &&
        orderData?['assignedTo'] != deliveryPersonId &&
        selectedStatus != 'accept') {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(
          child: Text(
            'This order has already been assigned to another delivery person.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    bool isAcceptedByMe = orderData?['assignedTo'] == deliveryPersonId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInfoRow('Customer', orderData?['customerName'] ?? '-'),
            buildInfoRow('Email', orderData?['customerEmail'] ?? '-'),
            buildInfoRow(
                'Address',
                orderData?['address'] != null
                    ? '${orderData!['address']['houseNumber'] ?? ''}, ${orderData!['address']['roadNumber'] ?? ''}, ${orderData!['address']['additionalDirections'] ?? ''}'
                    : '-'),
            buildInfoRow('Total', orderData?['total']?.toString() ?? '-'),
            buildInfoRow('Payment', orderData?['paymentMethod'] ?? '-'),
            buildInfoRow('Created At', orderData?['createdAt'] ?? '-'),
            const SizedBox(height: 20),
            const Text('Order Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // Show Accept button if order is pending
            if (!isAcceptedByMe && selectedStatus != 'rejected')
              Center(
                child: ElevatedButton(
                  onPressed: acceptOrder,
                  child: const Text('Accept Order'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                ),
              ),

            const SizedBox(height: 20),

            // Show status dropdown and Reject button only if accepted by me
            if (isAcceptedByMe) ...[
              DropdownButton<String>(
                value: statusOptions.contains(selectedStatus)
                    ? selectedStatus
                    : null,
                hint: const Text('Update Status'),
                items: statusOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newStatus) {
                  if (newStatus != null) {
                    updateStatus(newStatus);
                  }
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: rejectOrder,
                child: const Text('Reject Order'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
