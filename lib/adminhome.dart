import 'package:flutter/material.dart';
import 'login.dart';
import 'manage_pharmacy.dart';    // Create this file
import 'manage_customers.dart';   // Create this file
import 'manage_delivery.dart';    // Create this file

class AdminHome extends StatelessWidget {
  final Function(bool) onThemeChanged;
  const AdminHome({super.key,required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  Login(onThemeChanged: onThemeChanged)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdminButton(
              title: "Manage Pharmacy",
              icon: Icons.local_pharmacy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManagePharmacistPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            AdminButton(
              title: "Manage Customers",
              icon: Icons.people,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageCustomersPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            AdminButton(
              title: "Manage Delivery",
              icon: Icons.delivery_dining,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageDeliveryPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const AdminButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(title, style: const TextStyle(fontSize: 18)),
      ),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }
}
