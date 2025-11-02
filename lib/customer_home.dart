import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication for handling user login/logout.
import 'package:flutter/material.dart'; // Import Flutter's material design package for UI widgets.
import 'package:intl/intl.dart'; // Import intl for date and time formatting.
import 'package:provider/provider.dart'; // Import provider for state management.

import 'services/database_service.dart'; // Import custom DatabaseService for accessing Firebase Realtime Database.
import 'cart_page.dart'; // Import customer cart page widget.
import 'customer_profile_page.dart'; // Import customer profile page widget.
import 'pharmacy_browser.dart'; // Import pharmacy browsing page widget.
import 'models/order.dart'; // Import Order model to represent customer orders.
import 'widgets/order_card.dart'; // Import OrderCard widget to display order information.
import 'state/customer_app_state.dart'; // Import application state class for customer (cart, orders, etc.).
import 'login.dart'; // Import login page widget for redirection after logout.

class CustomerHome extends StatefulWidget { // Define a stateful widget for the customer’s main home screen.
  const CustomerHome({
    super.key,
    required this.onThemeChanged,
    required this.onLogout,
  });

  final Function(bool) onThemeChanged; // Callback function to toggle light/dark theme.
  final VoidCallback onLogout; // Callback function to handle logout action.

  @override
  State<CustomerHome> createState() => _CustomerHomeState(); // Create and return the state object for this widget.
}

class _CustomerHomeState extends State<CustomerHome> { // Define the state class for CustomerHome.
  int _currentIndex = 0; // Track the index of the currently selected bottom navigation tab.

  @override
  Widget build(BuildContext context) { // Build method to describe how the UI should look.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Check if the current theme is dark mode.

    final pages = <Widget>[ // List of pages for navigation.
      PharmacyBrowser(onThemeChanged: widget.onThemeChanged), // Pharmacy browsing page.
      const CustomerCartPage(), // Customer cart page.
      const _OrdersTab(), // Orders tab showing order history.
      CustomerProfilePage(onThemeChanged: widget.onThemeChanged), // Customer profile page.
    ];

    final titles = <String>['Pharmacies', 'Cart', 'Orders', 'Profile']; // Titles for each page shown in AppBar.

    return Scaffold( // Main screen layout structure.
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFB3E5FC), // Background color changes with theme.
      appBar: AppBar( // Top AppBar for navigation and actions.
        backgroundColor: const Color(0xFF0288D1), // Blue AppBar background.
        title: Text(
          titles[_currentIndex], // Display title matching current page.
          style: const TextStyle(color: Colors.white), // Title text color set to white.
        ),
        actions: [ // Define action buttons in AppBar.
          if (_currentIndex != 1) // Only show cart icon if not already on the cart page.
            Consumer<CustomerAppState>( // Listen to changes in CustomerAppState (for cart updates).
              builder: (context, state, _) {
                final count = state.cartItems.fold<int>(0, (sum, item) => sum + item.quantity); // Calculate total quantity in cart.
                return IconButton( // Create a clickable cart icon.
                  icon: Stack( // Stack allows layering of widgets (icon + badge).
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, color: Colors.white), // Main cart icon.
                      if (count > 0) // If there are items in cart, show a red badge.
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container( // Red circular badge showing item count.
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count', // Display number of items in cart.
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
                  onPressed: () => setState(() => _currentIndex = 1), // Switch to the cart page when pressed.
                );
              },
            ),
          IconButton( // Logout button in the AppBar.
            tooltip: 'Log out', // Tooltip shown when hovering.
            icon: const Icon(Icons.logout, color: Colors.white), // Logout icon.
            onPressed: () async { // Define logout logic.
              await FirebaseAuth.instance.signOut(); // Sign out the current Firebase user.
              if (!mounted) return; // Prevent further actions if widget is not mounted.(اذا الصفحة موجوده ,بيسوي اي اكشن موجود)
              Navigator.of(context).pushReplacement( // Navigate to login page, replacing current page.
                MaterialPageRoute(
                  builder: (context) => Login(onThemeChanged: (bool value) {}), // Go to Login page.
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack( // IndexedStack keeps all pages alive and shows only the selected one.
        index: _currentIndex, // Display page based on current index.
        children: pages, // The list of all pages.
      ),
      bottomNavigationBar: Consumer<CustomerAppState>( // Bottom navigation bar, also reacts to cart updates.
        builder: (context, state, _) {
          final count = state.cartItems.fold<int>(0, (sum, item) => sum + item.quantity); // Count total cart items.
          return BottomNavigationBar( // Create a navigation bar.
            currentIndex: _currentIndex, // Highlight current tab.
            onTap: (index) => setState(() => _currentIndex = index), // Update index when tapped.
            type: BottomNavigationBarType.fixed, // Fixed layout for all items.
            selectedItemColor: const Color(0xFF0288D1), // Blue color for selected item.
            unselectedItemColor: Colors.grey, // Grey for unselected items.
            items: [ // Define navigation items.
              const BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined), // Home icon.
                label: 'Home', // Label for home tab.
              ),
              BottomNavigationBarItem(
                icon: Stack( // Cart icon with optional badge.
                  clipBehavior: Clip.none, //to make the red circle(items count) outside the icon
                  children: [
                    const Icon(Icons.shopping_cart_outlined), // Cart icon.
                    if (count > 0) // Show badge if there are items.
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container( // Red circular badge.
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count', // Show count number.
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
                label: 'Cart', // Label for cart tab.
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined), // Orders icon.
                label: 'Orders', // Label for orders tab.
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), // Profile icon.
                label: 'Profile', // Label for profile tab.
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget { // Private widget class for the Orders tab.
  const _OrdersTab();

  Stream<List<CustomerOrder>> _ordersStream(String userId) { // Create a stream of orders for the given user.
    final ref = DatabaseService.instance.ref('customer_orders/$userId'); // Reference to the user's orders in database.
    return ref.onValue.map((event) { // Listen for real-time changes in Firebase Realtime Database.
      final data = event.snapshot.value; // Get snapshot data.
      if (data is! Map) return <CustomerOrder>[]; // Return empty list if data is invalid.
      return data.entries
          .map<CustomerOrder>((entry) => CustomerOrder.fromMap( // Convert each entry to a CustomerOrder object.
        entry.key.toString(),
        Map<dynamic, dynamic>.from(entry.value as Map),
      ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort orders by date (newest first).
    });
  }

  void _showOrderDetails(BuildContext context, CustomerOrder order) { // Show a bottom sheet with order details.
    final placedAt = DateFormat.yMMMd().add_jm().format(order.createdAt); // Format the order date and time.

    showModalBottomSheet( // Display modal bottom sheet.
      context: context,
      isScrollControlled: true, // Allow scrolling if content is long.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // Rounded top corners.
      ),
      builder: (context) {
        return Padding( // Add padding to bottom sheet content.
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20, // Add padding for safe area.
          ),
          child: SingleChildScrollView( // Make content scrollable.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OrderCard( // Display main order summary card.
                  order: order,
                  showNotes: false,
                  borderColor: const Color(0xFF0288D1),
                ),
                const SizedBox(height: 16),
                Text('Placed on $placedAt', style: Theme.of(context).textTheme.bodyMedium), // Show order date.
                const SizedBox(height: 16),
                Text(
                  'Items', // Section title.
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map( // Loop through items and create a list card for each.
                      (item) => Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF0288D1)), // Blue border.
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile( // List tile for item info.
                      title: Text(item.product.name), // Product name.
                      subtitle: Text('Qty: ${item.quantity}'), // Quantity.
                      trailing: Text(
                        '${(item.product.price * item.quantity).toStringAsFixed(2)} OMR', // Total price for item.
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32), // Divider before address section.
                Text(
                  'Delivery address', // Section title.
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('House / Building: ${order.address['houseNumber'] ?? ''}'), // Display house/building info.
                Text('Road: ${order.address['roadNumber'] ?? ''}'), // Display road info.
                if ((order.address['additionalDirections'] ?? '').toString().isNotEmpty)
                  Text('Directions: ${order.address['additionalDirections']}'), // Display additional directions if any.
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context), // Close button to dismiss modal.
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
  Widget build(BuildContext context) { // Build method for Orders tab.
    final user = FirebaseAuth.instance.currentUser; // Get the currently logged-in user.
    if (user == null) { // If user is not logged in.
      return const Center(child: Text('Please sign in to view your orders.')); // Show message prompting login.
    }

    return StreamBuilder<List<CustomerOrder>>( // Build UI based on order stream.
      stream: _ordersStream(user.uid), // Connect to order data stream.
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { // Show loading spinner while waiting.
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) { // If there's an error loading data.
          return const Center(child: Text('Unable to load orders.'));
        }

        final orders = snapshot.data ?? []; // Get list of orders or empty list.
        if (orders.isEmpty) { // If no orders found.
          return const Center(child: Text('You have not placed any orders yet.')); // Show empty message.
        }

        return ListView.separated( // Display orders in a scrollable list.
          padding: const EdgeInsets.all(16),
          itemCount: orders.length, // Number of orders.
          separatorBuilder: (_, __) => const SizedBox(height: 12), // Spacing between items.
          itemBuilder: (context, index) {
            final order = orders[index]; // Current order item.
            return OrderCard( // Create an OrderCard for each order.
              order: order,
              showNotes: false,
              borderColor: const Color(0xFF0288D1),
              onTap: () => _showOrderDetails(context, order), // Show details when tapped.
            );
          },
        );
      },
    );
  }
}
