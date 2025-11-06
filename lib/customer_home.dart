import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'cart_page.dart';
import 'customer_profile_page.dart';
import 'pharmacy_browser.dart';
import 'models/order.dart';
import 'widgets/order_card.dart';
import 'state/customer_app_state.dart';
import 'login.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({
    super.key,
    required this.onThemeChanged,
    required this.onLogout,
  });

  final Function(bool) onThemeChanged;
  final VoidCallback onLogout;

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pages = <Widget>[
      PharmacyBrowser(onThemeChanged: widget.onThemeChanged),
      const CustomerCartPage(),
      const _OrdersTab(),
      CustomerProfilePage(onThemeChanged: widget.onThemeChanged),
    ];

    final titles = <String>['Pharmacies', 'Cart', 'Orders', 'Profile'];

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFB3E5FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0288D1),
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_currentIndex != 1)
            Consumer<CustomerAppState>(
              builder: (context, state, _) {
                final count = state.cartItems
                    .fold<int>(0, (sum, item) => sum + item.quantity);
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => setState(() => _currentIndex = 1),
                );
              },
            ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => Login(onThemeChanged: (bool value) {}),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Consumer<CustomerAppState>(
        builder: (context, state, _) {
          final count =
              state.cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF0288D1),
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (count > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Orders',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  Stream<List<CustomerOrder>> _ordersStream(String userId) {
    final ref = DatabaseService.instance.ref('customer_orders/$userId');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return <CustomerOrder>[];
      return data.entries
          .map<CustomerOrder>((entry) => CustomerOrder.fromMap(
                entry.key.toString(),
                Map<dynamic, dynamic>.from(entry.value as Map),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _showOrderDetails(BuildContext context, CustomerOrder order) {
    final placedAt = DateFormat.yMMMd().add_jm().format(order.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OrderCard(
                  order: order,
                  showNotes: false,
                  borderColor: const Color(0xFF0288D1),
                ),
                const SizedBox(height: 16),
                Text('Placed on $placedAt',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(
                  'Items',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF0288D1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('Qty: ${item.quantity}'),
                      trailing: Text(
                        '${(item.product.price * item.quantity).toStringAsFixed(2)} OMR',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32),
                Text(
                  'Delivery address',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('House / Building: ${order.address['houseNumber'] ?? ''}'),
                Text('Road: ${order.address['roadNumber'] ?? ''}'),
                if ((order.address['additionalDirections'] ?? '')
                    .toString()
                    .isNotEmpty)
                  Text('Directions: ${order.address['additionalDirections']}'),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view your orders.'));
    }

    return StreamBuilder<List<CustomerOrder>>(
      stream: _ordersStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load orders.'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(
              child: Text('You have not placed any orders yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCard(
              order: order,
              showNotes: false,
              borderColor: const Color(0xFF0288D1),
              onTap: () => _showOrderDetails(context, order),
            );
          },
        );
      },
    );
  }
}
