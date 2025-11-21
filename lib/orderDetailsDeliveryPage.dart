import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _showMap = false;

  final List<String> statusOptions = [
    'out_for_delivery',
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
          // Use deliveryStatus if available, otherwise fall back to status
          selectedStatus =
              orderData?['deliveryStatus'] ?? orderData?['status'] ?? '';
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

  // Update order delivery status (out_for_delivery / delivered)
  Future<void> updateStatus(String status) async {
    try {
      // Map old status to new deliveryStatus
      String deliveryStatus;
      if (status == 'delivering') {
        deliveryStatus = 'out_for_delivery';
      } else {
        deliveryStatus = status;
      }

      await DatabaseService.instance
          .ref('orders/${widget.orderId}')
          .update({'deliveryStatus': deliveryStatus});

      setState(() {
        selectedStatus = deliveryStatus;
        orderData?['deliveryStatus'] = deliveryStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to "$deliveryStatus"')),
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
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (orderData == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
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

            // Location map button
            if (orderData?['address'] != null &&
                orderData!['address']['latitude'] != null &&
                orderData!['address']['longitude'] != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showMap = !_showMap;
                        });
                      },
                      icon: Icon(_showMap ? Icons.map : Icons.map_outlined),
                      label: Text(
                          _showMap ? 'Hide Location Map' : 'Show Location Map'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final lat =
                          (orderData!['address']['latitude'] as num).toDouble();
                      final lng = (orderData!['address']['longitude'] as num)
                          .toDouble();

                      try {
                        // Create Google Maps navigation URL
                        final googleMapsUrl = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

                        // Try to launch Google Maps
                        final launched = await launchUrl(
                          googleMapsUrl,
                          mode: LaunchMode.externalApplication,
                        );

                        if (!launched && mounted) {
                          // If launch failed, try alternative method
                          final alternativeUrl =
                              Uri.parse('https://maps.google.com/?q=$lat,$lng');
                          await launchUrl(
                            alternativeUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } catch (e) {
                        debugPrint('Error opening maps: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'حدث خطأ في فتح الخريطة. تأكد من تثبيت تطبيق Google Maps.\nError: ${e.toString()}'),
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'حسناً',
                                onPressed: () {},
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_showMap) ...[
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate map height based on available space
                    final screenHeight = MediaQuery.of(context).size.height;
                    final screenWidth = MediaQuery.of(context).size.width;

                    // Calculate height based on screen size - leave space for other content
                    double mapHeight;
                    if (screenHeight > 800) {
                      mapHeight = 300.0;
                    } else if (screenHeight > 600) {
                      mapHeight = 250.0;
                    } else {
                      mapHeight = 200.0;
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: mapHeight,
                        maxWidth: screenWidth - 32, // Account for padding
                      ),
                      child: Container(
                        height: mapHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                (orderData!['address']['latitude'] as num)
                                    .toDouble(),
                                (orderData!['address']['longitude'] as num)
                                    .toDouble(),
                              ),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.pharm',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      (orderData!['address']['latitude'] as num)
                                          .toDouble(),
                                      (orderData!['address']['longitude']
                                              as num)
                                          .toDouble(),
                                    ),
                                    width: 60,
                                    height: 80,
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 1),
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 60,
                                            maxHeight: 35,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${orderData!['address']['houseNumber'] ?? ''}, ${orderData!['address']['roadNumber'] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],

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
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),

            const SizedBox(height: 20),

            // Show status dropdown only if accepted by me
            if (isAcceptedByMe) ...[
              const SizedBox(height: 10),
              const Text('Delivery Status',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: statusOptions.contains(selectedStatus)
                    ? selectedStatus
                    : null,
                hint: const Text('Select Delivery Status'),
                isExpanded: true,
                items: statusOptions.map((String value) {
                  String displayText = value == 'out_for_delivery'
                      ? 'Out for Delivery'
                      : 'Delivered';
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(displayText),
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
                child: const Text('Cancel Delivery'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
