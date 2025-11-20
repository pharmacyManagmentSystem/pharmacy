import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/database_service.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  String _selectedPeriod = 'Daily';
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly'];
  bool _loading = true;

  Map<String, dynamic> _globalOrderStats = {};
  Map<String, dynamic> _pharmacyStats = {};
  Map<String, dynamic> _customerStats = {};
  List<Map<String, dynamic>> _topPharmacies = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _pharmacyDetails = [];
  Map<String, Map<String, dynamic>> _pharmacyInventoryStatus = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);

    try {
      await Future.wait([
        _loadGlobalOrderReports(),
        _loadPharmacyStats(),
        _loadCustomerStats(),
        _loadPharmacyDetails(),
        _loadPharmacyInventoryStatus(),
      ]);
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadGlobalOrderReports() async {
    final ordersRef = DatabaseService.instance.ordersRef();
    final snapshot = await ordersRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        _globalOrderStats = {
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

      final createdAtStr = orderData['createdAt']?.toString();
      final createdAt = DateTime.tryParse(createdAtStr ?? '');
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
            break;
        }
      }
    }

    setState(() {
      _globalOrderStats = {
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
    });
  }

  Future<void> _loadPharmacyStats() async {
    final pharmacistsRef = DatabaseService.instance.pharmacistsRef();
    final snapshot = await pharmacistsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        _pharmacyStats = {
          'total': 0,
          'active': 0,
        };
        _topPharmacies = [];
      });
      return;
    }

    final pharmacists = snapshot.value as Map;
    int total = 0;
    int active = 0;
    final pharmacyRevenues = <String, double>{};
    final pharmacyNames = <String, String>{};

    for (var entry in pharmacists.entries) {
      final pharmacist = entry.value;
      if (pharmacist is! Map) continue;

      total++;
      final name = pharmacist['name']?.toString() ?? 'Unknown';
      pharmacyNames[entry.key.toString()] = name;

      final ordersRef =
          DatabaseService.instance.pharmacyOrdersRef(entry.key.toString());
      final ordersSnapshot = await ordersRef.get();

      if (ordersSnapshot.exists && ordersSnapshot.value is Map) {
        final orders = ordersSnapshot.value as Map;
        double revenue = 0.0;
        bool hasActiveOrders = false;

        for (var orderEntry in orders.entries) {
          final orderData = orderEntry.value;
          if (orderData is! Map) continue;

          final status = orderData['status']?.toString() ?? '';
          if (status == 'delivered') {
            final totalAmount = orderData['total'] is num
                ? (orderData['total'] as num).toDouble()
                : double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0;
            revenue += totalAmount;
          }
          if (status != 'cancelled' && status != 'delivered') {
            hasActiveOrders = true;
          }
        }

        pharmacyRevenues[entry.key.toString()] = revenue;
        if (hasActiveOrders || revenue > 0) {
          active++;
        }
      }
    }

    final sortedPharmacies = pharmacyRevenues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _pharmacyStats = {
        'total': total,
        'active': active,
      };
      _topPharmacies = sortedPharmacies
          .take(10)
          .map((e) => {
                'id': e.key,
                'name': pharmacyNames[e.key] ?? 'Unknown',
                'revenue': e.value,
              })
          .toList();
    });
  }

  Future<void> _loadCustomerStats() async {
    final customersRef = DatabaseService.instance.customersRef();
    final snapshot = await customersRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        _customerStats = {
          'total': 0,
          'active': 0,
        };
        _topCustomers = [];
      });
      return;
    }

    final customers = snapshot.value as Map;
    int total = 0;
    int active = 0;
    final customerOrders = <String, int>{};
    final customerNames = <String, String>{};

    for (var entry in customers.entries) {
      final customer = entry.value;
      if (customer is! Map) continue;

      total++;
      final name = customer['fullName']?.toString() ?? 'Unknown';
      customerNames[entry.key.toString()] = name;

      final status = customer['status']?.toString().toLowerCase() ?? 'active';
      if (status == 'active') {
        active++;
      }

      final ordersRef =
          DatabaseService.instance.customerOrdersRef(entry.key.toString());
      final ordersSnapshot = await ordersRef.get();

      if (ordersSnapshot.exists && ordersSnapshot.value is Map) {
        final orders = ordersSnapshot.value as Map;
        customerOrders[entry.key.toString()] = orders.length;
      }
    }

    final sortedCustomers = customerOrders.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _customerStats = {
        'total': total,
        'active': active,
      };
      _topCustomers = sortedCustomers
          .take(10)
          .map((e) => {
                'id': e.key,
                'name': customerNames[e.key] ?? 'Unknown',
                'orders': e.value,
              })
          .toList();
    });
  }

  Future<void> _loadPharmacyDetails() async {
    final pharmacistsRef = DatabaseService.instance.pharmacistsRef();
    final snapshot = await pharmacistsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        _pharmacyDetails = [];
      });
      return;
    }

    final pharmacists = snapshot.value as Map;
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

    final pharmacyDetailsList = <Map<String, dynamic>>[];

    for (var entry in pharmacists.entries) {
      final pharmacist = entry.value;
      if (pharmacist is! Map) continue;

      final pharmacyId = entry.key.toString();
      final pharmacyName = pharmacist['name']?.toString() ?? 'Unknown';

      final ordersRef = DatabaseService.instance.pharmacyOrdersRef(pharmacyId);
      final ordersSnapshot = await ordersRef.get();

      int totalOrders = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double revenue = 0.0;
      List<Map<String, dynamic>> cancelledReasons = [];

      if (ordersSnapshot.exists && ordersSnapshot.value is Map) {
        final orders = ordersSnapshot.value as Map;

        for (var orderEntry in orders.entries) {
          final orderData = orderEntry.value;
          if (orderData is! Map) continue;

          final createdAtStr = orderData['createdAt']?.toString();
          if (createdAtStr == null) continue;

          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt == null || createdAt.isBefore(startDate)) continue;

          totalOrders++;
          final status = orderData['status']?.toString() ?? '';
          final totalAmount = orderData['total'] is num
              ? (orderData['total'] as num).toDouble()
              : double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0;

          if (status == 'awaiting_confirmation' || status == 'processing') {
            pendingOrders++;
          } else if (status == 'delivered') {
            completedOrders++;
            revenue += totalAmount;
          } else if (status == 'cancelled') {
            cancelledOrders++;
            final reason = orderData['cancellationReason']?.toString() ??
                orderData['notes']?.toString() ??
                'No reason provided';
            cancelledReasons.add({
              'orderId': orderEntry.key.toString(),
              'reason': reason,
              'amount': totalAmount,
            });
          }
        }
      }

      pharmacyDetailsList.add({
        'id': pharmacyId,
        'name': pharmacyName,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'revenue': revenue,
        'cancelledReasons': cancelledReasons,
      });
    }

    pharmacyDetailsList.sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    setState(() {
      _pharmacyDetails = pharmacyDetailsList;
    });
  }

  Future<void> _loadPharmacyInventoryStatus() async {
    final pharmacistsRef = DatabaseService.instance.pharmacistsRef();
    final snapshot = await pharmacistsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      setState(() {
        _pharmacyInventoryStatus = {};
      });
      return;
    }

    final pharmacists = snapshot.value as Map;
    final inventoryStatus = <String, Map<String, dynamic>>{};
    final now = DateTime.now();
    final lowStockThreshold = 10;
    final nearExpiryDays = 30;

    for (var entry in pharmacists.entries) {
      final pharmacyId = entry.key.toString();
      final productsRef =
          DatabaseService.instance.pharmacistProductsRef(pharmacyId);
      final productsSnapshot = await productsRef.get();

      int lowStock = 0;
      int nearExpiry = 0;
      int outOfStock = 0;
      int totalProducts = 0;

      if (productsSnapshot.exists && productsSnapshot.value is Map) {
        final products = productsSnapshot.value as Map;

        for (var productEntry in products.entries) {
          final product = productEntry.value;
          if (product is! Map) continue;

          totalProducts++;
          final quantity = product['quantity'] is num
              ? (product['quantity'] as num).toInt()
              : int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

          if (quantity == 0) {
            outOfStock++;
          } else if (quantity <= lowStockThreshold) {
            lowStock++;
          }

          final expiryDateStr = product['expiryDate']?.toString();
          if (expiryDateStr != null && expiryDateStr.isNotEmpty) {
            final expiryDate = DateTime.tryParse(expiryDateStr);
            if (expiryDate != null) {
              final daysUntilExpiry = expiryDate.difference(now).inDays;
              if (daysUntilExpiry >= 0 && daysUntilExpiry <= nearExpiryDays) {
                nearExpiry++;
              }
            }
          }
        }
      }

      inventoryStatus[pharmacyId] = {
        'totalProducts': totalProducts,
        'lowStock': lowStock,
        'nearExpiry': nearExpiry,
        'outOfStock': outOfStock,
      };
    }

    setState(() {
      _pharmacyInventoryStatus = inventoryStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports & Analytics'),
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
                    _buildPharmacyDetailsSection(),
                    const SizedBox(height: 20),
                    _buildInventoryStatusSection(),
                    const SizedBox(height: 20),
                    _buildTopPerformersSection(),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Period: $_selectedPeriod | All pharmacies overview',
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
            'System Overview',
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
                  '${_globalOrderStats['total'] ?? 0}',
                  Icons.shopping_cart_outlined,
                  Colors.blue,
                  Colors.blue[50]!,
                ),
                _buildModernStatCard(
                  'Total Revenue',
                  '${(_globalOrderStats['revenue'] ?? 0.0).toStringAsFixed(2)} OMR',
                  Icons.attach_money,
                  Colors.green,
                  Colors.green[50]!,
                ),
                _buildModernStatCard(
                  'Pharmacies',
                  '${_pharmacyStats['total'] ?? 0}',
                  Icons.local_pharmacy,
                  Colors.purple,
                  Colors.purple[50]!,
                ),
                _buildModernStatCard(
                  'Customers',
                  '${_customerStats['total'] ?? 0}',
                  Icons.people_outline,
                  Colors.teal,
                  Colors.teal[50]!,
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
    final pending = _globalOrderStats['periodPending'] ?? 0;
    final readyForDelivery = _globalOrderStats['periodReadyForDelivery'] ?? 0;
    final completed = _globalOrderStats['periodCompleted'] ?? 0;
    final cancelled = _globalOrderStats['periodCancelled'] ?? 0;
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
    final revenue = _globalOrderStats['periodRevenue'] ?? 0.0;
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

  Widget _buildPharmacyDetailsSection() {
    if (_pharmacyDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Pharmacy Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._pharmacyDetails.map((pharmacy) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.local_pharmacy,
                          color: Colors.blue[700], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy['name'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'ID: ${pharmacy['id'].toString().substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Total Orders',
                        '${pharmacy['totalOrders']}',
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailItem(
                        'Pending',
                        '${pharmacy['pendingOrders']}',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailItem(
                        'Completed',
                        '${pharmacy['completedOrders']}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailItem(
                        'Cancelled',
                        '${pharmacy['cancelledOrders']}',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Revenue: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${(pharmacy['revenue'] as double).toStringAsFixed(2)} OMR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if ((pharmacy['cancelledReasons'] as List).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Cancelled Orders Reasons:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(pharmacy['cancelledReasons'] as List)
                      .take(3)
                      .map((reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reason['reason'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatusSection() {
    if (_pharmacyInventoryStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Inventory Status by Pharmacy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._pharmacyDetails.map((pharmacy) {
          final inventory = _pharmacyInventoryStatus[pharmacy['id']] ?? {};
          if (inventory.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      pharmacy['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInventoryBadge(
                        'Total',
                        '${inventory['totalProducts'] ?? 0}',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInventoryBadge(
                        'Low Stock',
                        '${inventory['lowStock'] ?? 0}',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInventoryBadge(
                        'Near Expiry',
                        '${inventory['nearExpiry'] ?? 0}',
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInventoryBadge(
                        'Out of Stock',
                        '${inventory['outOfStock'] ?? 0}',
                        Colors.red[700]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInventoryBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Top Performers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_topPharmacies.isNotEmpty) ...[
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_pharmacy, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Top Pharmacies',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._topPharmacies.take(5).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final pharmacy = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pharmacy['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${(pharmacy['revenue'] as double).toStringAsFixed(2)} OMR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_topCustomers.isNotEmpty)
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.purple[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Top Customers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._topCustomers.take(5).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final customer = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.purple[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            customer['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${customer['orders']} orders',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
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
}
