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
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly'];
  bool _loading = true;

  Map<String, dynamic> _orderStats = {};
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _nearExpiryProducts = [];
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _outOfStockProducts = [];
  List<Map<String, dynamic>> _cancelledOrders = [];

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

    setState(() {
      _lowStockProducts = lowStock;
      _nearExpiryProducts = nearExpiry;
      _outOfStockProducts = outOfStock;
      _topSellingProducts = topSelling;
    });
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
            Expanded(child: _buildCompactOrderChart()),
            const SizedBox(width: 16),
            Expanded(child: _buildCompactRevenueCard()),
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
          Text(
            'Orders Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
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
      height: 200,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            '${revenue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
          _buildAlertCard(
            'Low Stock',
            '${_lowStockProducts.length} products',
            Icons.warning_amber_rounded,
            Colors.orange,
            _lowStockProducts.length,
          ),
        if (_lowStockProducts.isNotEmpty) const SizedBox(height: 12),
        if (_nearExpiryProducts.isNotEmpty)
          _buildAlertCard(
            'Near Expiry',
            '${_nearExpiryProducts.length} products',
            Icons.schedule,
            Colors.red,
            _nearExpiryProducts.length,
          ),
        if (_nearExpiryProducts.isNotEmpty) const SizedBox(height: 12),
        if (_outOfStockProducts.isNotEmpty)
          _buildAlertCard(
            'Out of Stock',
            '${_outOfStockProducts.length} products',
            Icons.inventory_2_outlined,
            Colors.red[700]!,
            _outOfStockProducts.length,
          ),
        if (_lowStockProducts.isEmpty &&
            _nearExpiryProducts.isEmpty &&
            _outOfStockProducts.isEmpty)
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
          child: Text(
            'Top Selling Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
