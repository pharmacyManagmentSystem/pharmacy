import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
import 'localization/app_localizations.dart';
import 'chatbot_page.dart';
import 'notifications_page.dart';

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
    final loc = AppLocalizations.of(context)!;

    final pages = <Widget>[
      PharmacyBrowser(onThemeChanged: widget.onThemeChanged),
      const CustomerCartPage(),
      const _OrdersTab(),
      CustomerProfilePage(onThemeChanged: widget.onThemeChanged),
    ];

    final titles = <String>[loc.pharmacies, loc.cart, loc.orders, loc.profile];

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFB3E5FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0288D1),
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Notifications Icon
          StreamBuilder<DatabaseEvent>(
            stream: DatabaseService.instance
                .customerNotificationsRef(FirebaseAuth.instance.currentUser?.uid ?? '')
                .onValue,
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData && snapshot.data?.snapshot.value is Map) {
                final data = snapshot.data!.snapshot.value as Map;
                unreadCount = data.values
                    .where((n) => n is Map && (n['read'] != true))
                    .length;
              }
              
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: loc.isArabic ? 'الإشعارات' : 'Notifications',
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsPage(
                              userId: user.uid,
                              isPharmacist: false,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.chatbotTitle,
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatBotPage()),
              );
            },
          ),
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
            tooltip: loc.logout,
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
              BottomNavigationBarItem(
                icon: const Icon(Icons.storefront_outlined),
                label: loc.home,
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
                label: loc.cart,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_outlined),
                label: loc.orders,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: loc.profile,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {

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

  bool _canCancelOrder(OrderStatus status) {
    // Customer can only cancel orders that are not yet ready for pickup
    return status == OrderStatus.awaitingConfirmation || 
           status == OrderStatus.processing;
  }

  Future<void> _cancelOrder(BuildContext context, CustomerOrder order) async {
    final loc = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cancel_outlined, color: Colors.red[700]),
            ),
            const SizedBox(width: 12),
            Text(loc.cancelOrderTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.cancelOrderConfirm,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${loc.total}: ${order.total.toStringAsFixed(2)} OMR',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: loc.cancelReason,
                hintText: loc.cancelReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.comment_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.keepOrder),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.cancel, size: 18),
            label: Text(loc.cancelOrder),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final reason = reasonController.text.trim().isEmpty 
          ? 'Cancelled by customer' 
          : reasonController.text.trim();

      // Update customer_orders
      await DatabaseService.instance
          .ref('customer_orders/${user.uid}/${order.id}')
          .update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancelledBy': 'customer',
      });

      // Update pharmacy_orders
      await DatabaseService.instance
          .ref('pharmacy_orders/${order.pharmacyId}/${order.id}')
          .update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancelledBy': 'customer',
      });

      if (context.mounted) {
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(loc.orderCancelledSuccess),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetails(BuildContext context, CustomerOrder order) {
    final loc = AppLocalizations.of(context)!;
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
                Text('${loc.orderDate}: $placedAt',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(
                  loc.products,
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
                      subtitle: Text('${loc.quantity}: ${item.quantity}'),
                      trailing: Text(
                        '${(item.product.price * item.quantity).toStringAsFixed(2)} OMR',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32),
                Text(
                  loc.deliveryAddress,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${loc.houseNumber}: ${order.address['houseNumber'] ?? ''}'),
                Text('${loc.roadNumber}: ${order.address['roadNumber'] ?? ''}'),
                if ((order.address['additionalDirections'] ?? '')
                    .toString()
                    .isNotEmpty)
                  Text('${loc.additionalDirections}: ${order.address['additionalDirections']}'),
                const SizedBox(height: 24),
                // Cancel Order Button (only if order can be cancelled)
                if (_canCancelOrder(order.status)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red[700], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              loc.changedYourMind,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.canCancelMessage,
                          style: TextStyle(color: Colors.red[600], fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _cancelOrder(context, order),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: Text(loc.cancelOrder),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (order.status == OrderStatus.cancelled) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          loc.orderAlreadyCancelled,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (order.status == OrderStatus.readyForPickup || 
                           order.status == OrderStatus.outForDelivery) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.cannotCancelMessage,
                            style: TextStyle(color: Colors.blue[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.close),
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
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(loc.sessionExpired));
    }

    return StreamBuilder<List<CustomerOrder>>(
      stream: _ordersStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loc.loading),
            ],
          ));
        }
        if (snapshot.hasError) {
          return Center(child: Text(loc.somethingWentWrong));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(child: Text(loc.noOrders));
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
