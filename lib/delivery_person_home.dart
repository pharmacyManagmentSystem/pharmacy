import 'package:flutter/material.dart';
import 'login.dart';
import 'delivery_profile.dart'; // <-- make sure this file exists

class DeliveryPersonHome extends StatelessWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const DeliveryPersonHome({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Person Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Login(onThemeChanged: onThemeChanged),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "This is Delivery Person Home ",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryPersonProfilePage(
                      onThemeChanged: onThemeChanged,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text("Go to Profile"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
