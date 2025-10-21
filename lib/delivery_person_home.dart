import 'package:flutter/material.dart';
import 'login.dart';
class DeliveryPersonHome extends StatelessWidget {
  final Function(bool) onThemeChanged;
  const DeliveryPersonHome({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("delivery Person Home"),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) =>  Login(onThemeChanged: onThemeChanged)),
                );
              }
          ),
        ],
      ),
      body: const Center(
        child: Text("This is delivery person Home"),
      ),
    );
  }
}
