import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/database_service.dart';

class PharmacistReportsPage extends StatefulWidget {
  const PharmacistReportsPage({super.key});

  @override
  State<PharmacistReportsPage> createState() => _PharmacistReportsPageState();
}

class _PharmacistReportsPageState extends State<PharmacistReportsPage> {
  final user = FirebaseAuth.instance.currentUser;
  String _selectedPeriod = 'Daily';
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  bool _loading = true;

  Map<String, dynamic> _orderStats = {};
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _nearExpiryProducts = [];
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _outOfStockProducts = [];
  List<Map<String, dynamic>> _cancelledOrders = [];
  List<Map<String, dynamic>> _fastMovingProducts = []; // Products selling fast - need restock

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (user == null) return;
    setState(() => _loading = true);

    try {
      await Future.wait([
        _loadOrderReports(),
        _loadProductReports(),
      ]);
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  DateTime? _parseCreatedAt(dynamic createdAtValue) {
    if (createdAtValue == null) return null;

    // If it's a number (timestamp), convert it
    if (createdAtValue is num) {
      // Check if it's milliseconds (13 digits) or seconds (10 digits)
      if (createdAtValue > 1000000000000) {
        // Milliseconds
        return DateTime.fromMillisecondsSinceEpoch(createdAtValue.toInt());
      } else {
        // Seconds
        return DateTime.fromMillisecondsSinceEpoch(
            (createdAtValue * 1000).toInt());
      }
    }

    // If it's a string, try to parse it
    if (createdAtValue is String) {
      return DateTime.tryParse(createdAtValue);
    }

    return null;
  }

  Future<void> _loadOrderReports() async {
    if (user == null) return;

    final ordersRef = DatabaseService.instance.pharmacyOrdersRef(user!.uid);
    final snapshot = await ordersRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        _orderStats = {
          'total': 0,
          'pending': 0,
          'readyForDelivery': 0,
          'completed': 0,
          'cancelled': 0,
          'revenue': 0.0,
          'periodTotal': 0,
          'periodPending': 0,
          'periodReadyForDelivery': 0,
          'periodCompleted': 0,
          'periodCancelled': 0,
          'periodRevenue': 0.0,
        };
        _cancelledOrders = [];
      });
      return;
    }

    final orders = snapshot.value as Map;
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    int totalAll = 0;
    int pendingAll = 0;
    int readyAll = 0;
    int completedAll = 0;
    int cancelledAll = 0;
    double revenueAll = 0.0;

    int totalPeriod = 0;
    int pendingPeriod = 0;
    int readyPeriod = 0;
    int completedPeriod = 0;
    int cancelledPeriod = 0;
    double revenuePeriod = 0.0;
    List<Map<String, dynamic>> cancelledOrdersList = [];

    for (var entry in orders.entries) {
      final orderData = entry.value;
      if (orderData is! Map) continue;

      final status = orderData['status']?.toString() ?? '';
      final totalAmount = orderData['total'] is num
          ? (orderData['total'] as num).toDouble()
          : double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0;

      totalAll++;
      switch (status) {
        case 'awaiting_confirmation':
        case 'processing':
          pendingAll++;
          break;
        case 'ready_for_pickup':
          readyAll++;
          break;
        case 'delivered':
          completedAll++;
          revenueAll += totalAmount;
          break;
        case 'cancelled':
          cancelledAll++;
          break;
      }

      final createdAt = _parseCreatedAt(orderData['createdAt']);
      if (createdAt != null && !createdAt.isBefore(startDate)) {
        totalPeriod++;
        switch (status) {
          case 'awaiting_confirmation':
          case 'processing':
            pendingPeriod++;
            break;
          case 'ready_for_pickup':
            readyPeriod++;
            break;
          case 'delivered':
            completedPeriod++;
            revenuePeriod += totalAmount;
            break;
          case 'cancelled':
            cancelledPeriod++;
            final cancellationReason =
                orderData['cancellationReason']?.toString() ??
                    orderData['notes']?.toString() ??
                    'No reason provided';
            cancelledOrdersList.add({
              'orderId': entry.key.toString(),
              'customerName':
                  orderData['customerName']?.toString() ?? 'Unknown',
              'total': totalAmount,
              'createdAt': createdAt,
              'reason': cancellationReason,
            });
            break;
        }
      }
    }

    cancelledOrdersList.sort((a, b) =>
        (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

    setState(() {
      _orderStats = {
        'total': totalAll,
        'pending': pendingAll,
        'readyForDelivery': readyAll,
        'completed': completedAll,
        'cancelled': cancelledAll,
        'revenue': revenueAll,
        'periodTotal': totalPeriod,
        'periodPending': pendingPeriod,
        'periodReadyForDelivery': readyPeriod,
        'periodCompleted': completedPeriod,
        'periodCancelled': cancelledPeriod,
        'periodRevenue': revenuePeriod,
      };
      _cancelledOrders = cancelledOrdersList;
    });
  }

  Future<void> _loadProductReports() async {
    if (user == null) return;

    final productsRef =
        DatabaseService.instance.pharmacistProductsRef(user!.uid);
    final snapshot = await productsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        _lowStockProducts = [];
        _nearExpiryProducts = [];
        _outOfStockProducts = [];
      });
      return;
    }

    final products = snapshot.value as Map;
    final now = DateTime.now();
    final lowStockThreshold = 10;
    final nearExpiryDays = 30;

    List<Map<String, dynamic>> lowStock = [];
    List<Map<String, dynamic>> nearExpiry = [];
    List<Map<String, dynamic>> outOfStock = [];

    for (var entry in products.entries) {
      final product = entry.value;
      if (product is! Map) continue;

      final quantity = product['quantity'] is num
          ? (product['quantity'] as num).toInt()
          : int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

      if (quantity == 0) {
        outOfStock.add({
          'id': entry.key.toString(),
          'name': product['name']?.toString() ?? 'Unknown',
          'quantity': quantity,
        });
      } else if (quantity <= lowStockThreshold) {
        lowStock.add({
          'id': entry.key.toString(),
          'name': product['name']?.toString() ?? 'Unknown',
          'quantity': quantity,
        });
      }

      final expiryDateStr = product['expiryDate']?.toString();
      if (expiryDateStr != null && expiryDateStr.isNotEmpty) {
        final expiryDate = DateTime.tryParse(expiryDateStr);
        if (expiryDate != null) {
          final daysUntilExpiry = expiryDate.difference(now).inDays;
          if (daysUntilExpiry >= 0 && daysUntilExpiry <= nearExpiryDays) {
            nearExpiry.add({
              'id': entry.key.toString(),
              'name': product['name']?.toString() ?? 'Unknown',
              'expiryDate': expiryDate,
              'daysUntilExpiry': daysUntilExpiry,
            });
          }
        }
      }
    }

    lowStock
        .sort((a, b) => (a['quantity'] as int).compareTo(b['quantity'] as int));
    nearExpiry.sort((a, b) =>
        (a['daysUntilExpiry'] as int).compareTo(b['daysUntilExpiry'] as int));

    final topSelling = await _getTopSellingProducts();
    final fastMoving = await _getFastMovingProducts();

    setState(() {
      _lowStockProducts = lowStock;
      _nearExpiryProducts = nearExpiry;
      _outOfStockProducts = outOfStock;
      _topSellingProducts = topSelling;
      _fastMovingProducts = fastMoving;
    });
  }

  Future<List<Map<String, dynamic>>> _getFastMovingProducts() async {
    if (user == null) return [];

    // Get sales data from orders
    final ordersRef = DatabaseService.instance.pharmacyOrdersRef(user!.uid);
    final ordersSnapshot = await ordersRef.get();

    if (!ordersSnapshot.exists || ordersSnapshot.value == null) return [];

    final orders = ordersSnapshot.value as Map;
    final productSales = <String, Map<String, dynamic>>{};

    // Calculate sales in the selected period
    final now = DateTime.now();
    DateTime startDate;
    switch (_selectedPeriod) {
      case 'Daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    for (var entry in orders.entries) {
      final orderData = entry.value;
      if (orderData is! Map) continue;

      final status = orderData['status']?.toString() ?? '';
      if (status != 'delivered') continue;

      final createdAt = _parseCreatedAt(orderData['createdAt']);
      if (createdAt == null || createdAt.isBefore(startDate)) continue;

      final items = orderData['items'];
      if (items is! Map) continue;

      for (var itemEntry in items.entries) {
        final item = itemEntry.value;
        if (item is! Map) continue;

        final productId = item['productId']?.toString() ?? itemEntry.key.toString();
        final productName = item['name']?.toString() ?? 'Unknown';
        final quantity = item['quantity'] is num
            ? (item['quantity'] as num).toInt()
            : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

        if (productSales.containsKey(productId)) {
          productSales[productId]!['sales'] = 
              (productSales[productId]!['sales'] as int) + quantity;
        } else {
          productSales[productId] = {
            'id': productId,
            'name': productName,
            'sales': quantity,
          };
        }
      }
    }

    // Get current stock for each product
    final productsRef = DatabaseService.instance.pharmacistProductsRef(user!.uid);
    final productsSnapshot = await productsRef.get();

    if (!productsSnapshot.exists || productsSnapshot.value == null) {
      return [];
    }

    final products = productsSnapshot.value as Map;
    final fastMoving = <Map<String, dynamic>>[];

    for (var entry in productSales.entries) {
      final productId = entry.key;
      final salesData = entry.value;
      final sales = salesData['sales'] as int;

      // Get current stock
      final product = products[productId];
      if (product == null || product is! Map) continue;

      final currentStock = product['quantity'] is num
          ? (product['quantity'] as num).toInt()
          : int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
      
      final productName = product['name']?.toString() ?? salesData['name'];

      // Calculate days of stock remaining based on sales velocity
      int daysOfStockLeft = 999;
      if (sales > 0) {
        // Calculate average daily sales based on period
        double dailySales;
        switch (_selectedPeriod) {
          case 'Daily':
            dailySales = sales.toDouble();
            break;
          case 'Weekly':
            dailySales = sales / 7;
            break;
          case 'Monthly':
            dailySales = sales / 30;
            break;
          case 'Yearly':
            dailySales = sales / 365;
            break;
          default:
            dailySales = sales.toDouble();
        }
        
        if (dailySales > 0) {
          daysOfStockLeft = (currentStock / dailySales).floor();
        }
      }

      // Add to fast moving if:
      // - Has any sales AND (stock will run out soon OR stock is low compared to sales)
      if (sales >= 1 && (daysOfStockLeft < 30 || currentStock < sales * 3)) {
        fastMoving.add({
          'id': productId,
          'name': productName,
          'sales': sales,
          'currentStock': currentStock,
          'daysOfStockLeft': daysOfStockLeft,
          'urgency': daysOfStockLeft < 7 ? 'high' : (daysOfStockLeft < 14 ? 'medium' : 'low'),
        });
      }
    }

    // Sort by urgency (days of stock left)
    fastMoving.sort((a, b) => 
        (a['daysOfStockLeft'] as int).compareTo(b['daysOfStockLeft'] as int));

    return fastMoving.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> _getTopSellingProducts() async {
    if (user == null) return [];

    final ordersRef = DatabaseService.instance.pharmacyOrdersRef(user!.uid);
    final snapshot = await ordersRef.get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final orders = snapshot.value as Map;
    final productSales = <String, int>{};

    for (var entry in orders.entries) {
      final orderData = entry.value;
      if (orderData is! Map) continue;

      final status = orderData['status']?.toString() ?? '';
      if (status != 'delivered') continue;

      final items = orderData['items'];
      if (items is! Map) continue;

      for (var itemEntry in items.entries) {
        final item = itemEntry.value;
        if (item is! Map) continue;

        final productId =
            item['productId']?.toString() ?? itemEntry.key.toString();
        final quantity = item['quantity'] is num
            ? (item['quantity'] as num).toInt()
            : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

        productSales[productId] = (productSales[productId] ?? 0) + quantity;
      }
    }

    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final productsRef =
        DatabaseService.instance.pharmacistProductsRef(user!.uid);
    final productsSnapshot = await productsRef.get();

    if (!productsSnapshot.exists || productsSnapshot.value == null) {
      return sortedProducts
          .take(10)
          .map((e) => {
                'id': e.key,
                'name': 'Unknown Product',
                'sales': e.value,
              })
          .toList();
    }

    final products = productsSnapshot.value as Map;
    final topSelling = <Map<String, dynamic>>[];

    for (var entry in sortedProducts.take(10)) {
      final product = products[entry.key];
      final productName =
          product is Map ? product['name']?.toString() ?? 'Unknown' : 'Unknown';

      topSelling.add({
        'id': entry.key,
        'name': productName,
        'sales': entry.value,
      });
    }

    return topSelling;
  }

  void _showExpandedChart(String title, Widget chart) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedPeriod,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Chart
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: chart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpandedOrdersChart() {
    final pending = _orderStats['periodPending'] ?? 0;
    final readyForDelivery = _orderStats['periodReadyForDelivery'] ?? 0;
    final completed = _orderStats['periodCompleted'] ?? 0;
    final cancelled = _orderStats['periodCancelled'] ?? 0;
    final total = pending + readyForDelivery + completed + cancelled;

    _showExpandedChart(
      'Orders Status - $_selectedPeriod',
      Column(
        children: [
          Expanded(
            flex: 2,
            child: total == 0
                ? const Center(child: Text('No data available'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: pending.toDouble(),
                          title: pending > 0 ? 'Pending\n$pending' : '',
                          color: Colors.orange[400]!,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: readyForDelivery.toDouble(),
                          title: readyForDelivery > 0 ? 'Ready\n$readyForDelivery' : '',
                          color: Colors.green[400]!,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: completed.toDouble(),
                          title: completed > 0 ? 'Completed\n$completed' : '',
                          color: Colors.teal[400]!,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: cancelled.toDouble(),
                          title: cancelled > 0 ? 'Cancelled\n$cancelled' : '',
                          color: Colors.red[400]!,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // Detailed stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Total Orders', '$total', Colors.blue),
                const Divider(),
                _buildDetailRow('Pending', '$pending', Colors.orange),
                _buildDetailRow('Ready for Delivery', '$readyForDelivery', Colors.green),
                _buildDetailRow('Completed', '$completed', Colors.teal),
                _buildDetailRow('Cancelled', '$cancelled', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExpandedRevenueChart() {
    final periodRevenue = _orderStats['periodRevenue'] ?? 0.0;
    final totalRevenue = _orderStats['revenue'] ?? 0.0;
    final periodCompleted = _orderStats['periodCompleted'] ?? 0;
    final totalCompleted = _orderStats['completed'] ?? 0;

    _showExpandedChart(
      'Revenue Analytics - $_selectedPeriod',
      Column(
        children: [
          // Big revenue display
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    '${periodRevenue.toStringAsFixed(2)} OMR',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_selectedPeriod Revenue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Stats comparison
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('$_selectedPeriod Revenue', '${periodRevenue.toStringAsFixed(2)} OMR', Colors.purple),
                const Divider(),
                _buildDetailRow('All Time Revenue', '${totalRevenue.toStringAsFixed(2)} OMR', Colors.blue),
                const Divider(),
                _buildDetailRow('$_selectedPeriod Orders', '$periodCompleted', Colors.green),
                _buildDetailRow('All Time Orders', '$totalCompleted', Colors.teal),
                if (periodCompleted > 0) ...[
                  const Divider(),
                  _buildDetailRow(
                    'Avg Order Value',
                    '${(periodRevenue / periodCompleted).toStringAsFixed(2)} OMR',
                    Colors.orange,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExpandedInventoryAlerts(String type) {
    List<Map<String, dynamic>> items;
    String title;
    Color color;
    IconData icon;

    switch (type) {
      case 'lowStock':
        items = _lowStockProducts;
        title = 'Low Stock Products';
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case 'nearExpiry':
        items = _nearExpiryProducts;
        title = 'Near Expiry Products';
        color = Colors.red;
        icon = Icons.schedule;
        break;
      case 'outOfStock':
        items = _outOfStockProducts;
        title = 'Out of Stock Products';
        color = Colors.red[700]!;
        icon = Icons.inventory_2_outlined;
        break;
      case 'fastMoving':
        items = _fastMovingProducts;
        title = 'Fast Moving Products - Restock Soon!';
        color = Colors.deepOrange;
        icon = Icons.local_fire_department;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$title (${items.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // List
              Flexible(
                child: items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No items found'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: type == 'fastMoving'
                                ? _buildFastMovingListItem(item, index, color)
                                : Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: color.withOpacity(0.1),
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'] as String,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  type == 'nearExpiry'
                                                      ? Text(
                                                          'Expires in ${item['daysUntilExpiry']} days - ${DateFormat('yyyy-MM-dd').format(item['expiryDate'] as DateTime)}',
                                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                        )
                                                      : Text(
                                                          'Quantity: ${item['quantity']}',
                                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                        ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                type == 'nearExpiry'
                                                    ? '${item['daysUntilExpiry']}d'
                                                    : '${item['quantity']}',
                                                style: TextStyle(
                                                  color: color,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Add Stock Button
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _showAddStockDialog(
                                                item['id'] as String, 
                                                item['name'] as String, 
                                                item['quantity'] as int? ?? 0,
                                              );
                                            },
                                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                                            label: const Text('Add Stock'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                              side: const BorderSide(color: Colors.green),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpandedTopProducts() {
    _showExpandedChart(
      'Top Selling Products',
      _topSellingProducts.isEmpty
          ? const Center(child: Text('No sales data available'))
          : ListView.builder(
              itemCount: _topSellingProducts.length,
              itemBuilder: (context, index) {
                final product = _topSellingProducts[index];
                final maxSales = _topSellingProducts.isNotEmpty
                    ? (_topSellingProducts.first['sales'] as int)
                    : 1;
                final sales = product['sales'] as int;
                final percentage = sales / maxSales;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: index < 3 ? Colors.amber : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: index < 3 ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$sales sales',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              index < 3 ? Colors.green : Colors.blue,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Add Stock Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddStockDialog(
                                product['id'] as String, 
                                product['name'] as String, 
                                0, // We don't have current stock here
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('Add Stock'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFastMovingListItem(Map<String, dynamic> item, int index, Color color) {
    final sales = item['sales'] as int;
    final currentStock = item['currentStock'] as int;
    final daysOfStockLeft = item['daysOfStockLeft'] as int;
    final urgency = item['urgency'] as String;
    final isUrgent = urgency == 'high';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isUrgent ? Icons.priority_high : Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Text(
                          'Sold $_selectedPeriod: $sales',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Current Stock', '$currentStock', 
                    currentStock < 10 ? Colors.red : Colors.blue),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildMiniStat('$_selectedPeriod Sales', '$sales', Colors.green),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildMiniStat('Days Left', 
                    daysOfStockLeft > 100 ? '∞' : '$daysOfStockLeft', 
                    daysOfStockLeft < 7 ? Colors.red : Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Add Stock Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddStockDialog(item['id'] as String, item['name'] as String, currentStock);
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Add Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Recommendation
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isUrgent ? Colors.red[200]! : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: isUrgent ? Colors.red[700] : Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrgent
                        ? 'Restock immediately! Running out in $daysOfStockLeft days'
                        : 'Consider restocking soon to meet demand',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUrgent ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddStockDialog(String productId, String productName, int currentStock) async {
    final quantityController = TextEditingController();
    DateTime? expiryDate;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_shopping_cart, color: Colors.green[700]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Stock', style: TextStyle(fontSize: 18)),
                    Text(
                      productName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current stock info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Current Stock: $currentStock',
                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity input
                TextFormField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity to Add',
                    hintText: 'Enter quantity',
                    prefixIcon: const Icon(Icons.add),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // Expiry date picker
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expiryDate == null
                            ? 'Expiry Date: Not selected'
                            : 'Expiry: ${DateFormat('yyyy-MM-dd').format(expiryDate!)}',
                        style: TextStyle(
                          color: expiryDate == null ? Colors.red : Colors.grey[700],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.blue),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            expiryDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (expiryDate == null)
                  const Text(
                    'Expiry date is required',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (expiryDate == null) {
                  setDialogState(() {});
                  return;
                }

                final quantity = int.tryParse(quantityController.text.trim());
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter valid quantity')),
                  );
                  return;
                }

                // Add the batch to the product
                try {
                  final productRef = DatabaseService.instance
                      .pharmacistProductsRef(user!.uid)
                      .child(productId);
                  
                  final snapshot = await productRef.get();
                  if (!snapshot.exists) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Product not found')),
                      );
                    }
                    return;
                  }

                  final productData = Map<String, dynamic>.from(snapshot.value as Map);
                  
                  // Get existing batches
                  Map<String, dynamic> batches = {};
                  if (productData['batches'] != null && productData['batches'] is Map) {
                    batches = Map<String, dynamic>.from(productData['batches'] as Map);
                  }

                  // Add new batch
                  final now = DateTime.now();
                  final batchId = '${now.millisecondsSinceEpoch}_${(now.microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
                  
                  batches[batchId] = {
                    'expiryDate': expiryDate!.toIso8601String(),
                    'quantity': quantity,
                  };

                  // Calculate total quantity
                  int totalQuantity = 0;
                  batches.values.forEach((batch) {
                    if (batch is Map && batch['quantity'] != null) {
                      final qty = batch['quantity'] is num
                          ? (batch['quantity'] as num).toInt()
                          : int.tryParse(batch['quantity'].toString()) ?? 0;
                      totalQuantity += qty;
                    }
                  });

                  // Update product
                  await productRef.update({
                    'batches': batches,
                    'quantity': totalQuantity,
                    'status': totalQuantity > 0 ? 'in_stock' : 'out_of_stock',
                  });

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 10),
                            Text('Added $quantity units to $productName'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    // Reload reports
                    _loadReports();
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue[50]!,
                      Colors.white,
                    ],
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildDashboardHeader(),
                    const SizedBox(height: 20),
                    _buildMainStatsGrid(),
                    const SizedBox(height: 20),
                    _buildChartsRow(),
                    const SizedBox(height: 20),
                    _buildInventoryAlerts(),
                    const SizedBox(height: 20),
                    _buildTopProductsSection(),
                    const SizedBox(height: 20),
                    _buildCancelledOrdersSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('Period:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<String>(
                segments: _periods
                    .map((p) => ButtonSegment(value: p, label: Text(p)))
                    .toList(),
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedPeriod = newSelection.first;
                  });
                  _loadReports();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.dashboard, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Pharmacy Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Period: $_selectedPeriod | Your pharmacy data only',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 600 ? 4 : 2;
            final childAspectRatio = width > 600 ? 1.4 : 1.2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              children: [
                _buildModernStatCard(
                  'Total Orders',
                  '${_orderStats['total'] ?? 0}',
                  Icons.shopping_cart_outlined,
                  Colors.blue,
                  Colors.blue[50]!,
                ),
                _buildModernStatCard(
                  'Revenue',
                  '${(_orderStats['revenue'] ?? 0.0).toStringAsFixed(2)} OMR',
                  Icons.attach_money,
                  Colors.green,
                  Colors.green[50]!,
                ),
                _buildModernStatCard(
                  'Completed',
                  '${_orderStats['completed'] ?? 0}',
                  Icons.check_circle_outline,
                  Colors.teal,
                  Colors.teal[50]!,
                ),
                _buildModernStatCard(
                  'Pending',
                  '${_orderStats['pending'] ?? 0}',
                  Icons.pending_outlined,
                  Colors.orange,
                  Colors.orange[50]!,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showExpandedOrdersChart,
                child: _buildCompactOrderChart(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _showExpandedRevenueChart,
                child: _buildCompactRevenueCard(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactOrderChart() {
    final pending = _orderStats['periodPending'] ?? 0;
    final readyForDelivery = _orderStats['periodReadyForDelivery'] ?? 0;
    final completed = _orderStats['periodCompleted'] ?? 0;
    final cancelled = _orderStats['periodCancelled'] ?? 0;
    final total = pending + readyForDelivery + completed + cancelled;

    if (total == 0) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child:
              Text('No data available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orders Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Icon(Icons.open_in_full, size: 16, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: [
                        PieChartSectionData(
                          value: pending.toDouble(),
                          title: pending > 0
                              ? '${((pending / total) * 100).toStringAsFixed(0)}%'
                              : '',
                          color: Colors.orange[400]!,
                          radius: 55,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: readyForDelivery.toDouble(),
                          title: readyForDelivery > 0
                              ? '${((readyForDelivery / total) * 100).toStringAsFixed(0)}%'
                              : '',
                          color: Colors.green[400]!,
                          radius: 55,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: completed.toDouble(),
                          title: completed > 0
                              ? '${((completed / total) * 100).toStringAsFixed(0)}%'
                              : '',
                          color: Colors.teal[400]!,
                          radius: 55,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: cancelled.toDouble(),
                          title: cancelled > 0
                              ? '${((cancelled / total) * 100).toStringAsFixed(0)}%'
                              : '',
                          color: Colors.red[400]!,
                          radius: 55,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.orange[400]!, 'Pending', pending),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                          Colors.green[400]!, 'Ready', readyForDelivery),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                          Colors.teal[400]!, 'Completed', completed),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                          Colors.red[400]!, 'Cancelled', cancelled),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label ($value)',
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactRevenueCard() {
    final revenue = _orderStats['periodRevenue'] ?? 0.0;
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedPeriod,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Icon(Icons.open_in_full, size: 16, color: Colors.white.withOpacity(0.6)),
            ],
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${revenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'OMR Revenue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Inventory Alerts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_lowStockProducts.isNotEmpty)
          GestureDetector(
            onTap: () => _showExpandedInventoryAlerts('lowStock'),
            child: _buildAlertCard(
              'Low Stock',
              '${_lowStockProducts.length} products - Tap to view',
              Icons.warning_amber_rounded,
              Colors.orange,
              _lowStockProducts.length,
            ),
          ),
        if (_lowStockProducts.isNotEmpty) const SizedBox(height: 12),
        if (_nearExpiryProducts.isNotEmpty)
          GestureDetector(
            onTap: () => _showExpandedInventoryAlerts('nearExpiry'),
            child: _buildAlertCard(
              'Near Expiry',
              '${_nearExpiryProducts.length} products - Tap to view',
              Icons.schedule,
              Colors.red,
              _nearExpiryProducts.length,
            ),
          ),
        if (_nearExpiryProducts.isNotEmpty) const SizedBox(height: 12),
        if (_outOfStockProducts.isNotEmpty)
          GestureDetector(
            onTap: () => _showExpandedInventoryAlerts('outOfStock'),
            child: _buildAlertCard(
              'Out of Stock',
              '${_outOfStockProducts.length} products - Tap to view',
              Icons.inventory_2_outlined,
              Colors.red[700]!,
              _outOfStockProducts.length,
            ),
          ),
        if (_outOfStockProducts.isNotEmpty) const SizedBox(height: 12),
        // Fast Moving Products - Need Restock
        if (_fastMovingProducts.isNotEmpty)
          GestureDetector(
            onTap: () => _showExpandedInventoryAlerts('fastMoving'),
            child: _buildAlertCard(
              '🔥 Fast Moving - Restock Soon',
              '${_fastMovingProducts.length} products selling fast - Tap to view',
              Icons.local_fire_department,
              Colors.deepOrange,
              _fastMovingProducts.length,
            ),
          ),
        if (_fastMovingProducts.isNotEmpty) const SizedBox(height: 12),
        // Top Selling Products - for restocking reference
        if (_topSellingProducts.isNotEmpty)
          GestureDetector(
            onTap: _showExpandedTopProducts,
            child: _buildAlertCard(
              '⭐ Top Selling Products',
              '${_topSellingProducts.length} best sellers - Tap to view',
              Icons.star,
              Colors.amber[700]!,
              _topSellingProducts.length,
            ),
          ),
        if (_topSellingProducts.isNotEmpty) const SizedBox(height: 12),
        if (_lowStockProducts.isEmpty &&
            _nearExpiryProducts.isEmpty &&
            _outOfStockProducts.isEmpty &&
            _fastMovingProducts.isEmpty &&
            _topSellingProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No inventory alerts',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection() {
    if (_topSellingProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: _showExpandedTopProducts,
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showExpandedTopProducts,
          child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._topSellingProducts
                  .take(5)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final product = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          product['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product['sales']} sales',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildCancelledOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Cancelled Orders Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_cancelledOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No cancelled orders found',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._cancelledOrders.take(10).map((order) => Card(
                        color: Colors.red[50],
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.cancel, color: Colors.red),
                          title: Text(
                            'Order #${order['orderId'].toString().substring(0, 8)}...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: ${order['customerName']}'),
                              Text(
                                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(order['createdAt'] as DateTime)}',
                              ),
                              Text(
                                'Amount: ${(order['total'] as double).toStringAsFixed(2)} OMR',
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Reason: ${order['reason']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                if (_cancelledOrders.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... and ${_cancelledOrders.length - 10} more cancelled orders',
                      style: TextStyle(
                          color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
