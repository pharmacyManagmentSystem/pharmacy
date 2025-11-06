import 'package:flutter/material.dart';
import 'login.dart';
import 'manage_pharmacy.dart';
import 'manage_customers.dart';
import 'manage_delivery.dart';

class AdminHome extends StatelessWidget {
  final Function(bool) onThemeChanged;
  const AdminHome({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC), // Baby blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0288D1), // White app bar
        elevation: 4,
        title: Row(
          children: [
            Image.asset(
              'assets/pharmacy.jpg', // pharmacy logo
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              "Admin Panel",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Black text on white background
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Login(onThemeChanged: onThemeChanged)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            AdminCard(
              title: "Manage Pharmacy",
              imagePath: 'assets/manage_pharmacy.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManagePharmacistPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            AdminCard(
              title: "Manage Customers",
              imagePath: 'assets/manage_customer.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManageCustomersPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            AdminCard(
              title: "Manage Delivery Persons",
              imagePath: 'assets/manage_delivery.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManageDeliveryPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const AdminCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF0288D1), // Blue card
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
