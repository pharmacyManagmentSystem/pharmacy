// Import the Flutter Material package which provides UI components.
import 'package:flutter/material.dart';

// Import custom pages for navigation.
import 'login.dart';
import 'manage_pharmacy.dart';
import 'manage_customers.dart';
import 'manage_delivery.dart';

// A stateless widget representing the Admin Home screen.
class AdminHome extends StatelessWidget {
  // Callback function to handle theme changes (e.g., dark/light mode).
  final Function(bool) onThemeChanged;

  // Constructor requiring the onThemeChanged function.
  const AdminHome({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    // Builds the UI for the Admin Home page.
    return Scaffold(
      // Sets the background color of the entire screen (baby blue).
      backgroundColor: const Color(0xFFB3E5FC),

      // The top app bar of the page.
      appBar: AppBar(
        // Sets the app bar color (blue).
        backgroundColor: const Color(0xFF0288D1),
        // Adds shadow under the app bar.
        elevation: 4,

        // The title widget inside the AppBar (a Row containing image + text).
        title: Row(
          children: [
            // Pharmacy logo image displayed on the app bar.
            Image.asset(
              'assets/pharmacy.jpg',
              height: 40,
              width: 40,
            ),
            // Adds spacing between the logo and text.
            const SizedBox(width: 10),
            // Text displaying “Admin Panel” as the app bar title.
            const Text(
              "Admin Panel",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text on blue background.
              ),
            ),
          ],
        ),

        // Action buttons displayed on the right side of the app bar.
        actions: [
          // Logout icon button.
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            // When pressed, navigates back to the Login page.
            onPressed: () {
              Navigator.pushReplacement(
                context,
                // Replaces current page with Login screen. onThemeChanged for dark mode
                MaterialPageRoute(
                    builder: (context) =>
                        Login(onThemeChanged: onThemeChanged)),
              );
            },
          ),
        ],
      ),

      // The main body of the page.
      body: Padding(
        // Adds padding around the content.
        padding: const EdgeInsets.all(20.0),

        // A scrollable list to hold the admin cards.
        child: ListView(
          children: [
            // First card: Manage Pharmacy section.
            AdminCard(
              title: "Manage Pharmacy",
              imagePath: 'assets/manage_pharmacy.png',
              // Navigates to ManagePharmacistPage when tapped.
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManagePharmacistPage()),
                );
              },
            ),

            // Adds spacing between cards.
            const SizedBox(height: 20),

            // Second card: Manage Customers section.
            AdminCard(
              title: "Manage Customers",
              imagePath: 'assets/manage_customer.png',
              // Navigates to ManageCustomersPage when tapped.
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManageCustomersPage()),
                );
              },
            ),

            // Adds spacing between cards.
            const SizedBox(height: 20),

            // Third card: Manage Delivery Persons section.
            AdminCard(
              title: "Manage Delivery Persons",
              imagePath: 'assets/manage_delivery.png',
              // Navigates to ManageDeliveryPage when tapped.
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

// A reusable widget representing a card in the admin dashboard.
class AdminCard extends StatelessWidget {
  // Title text of the card.
  final String title;
  // Path to the image displayed on the card.
  final String imagePath;
  // Function executed when the card is tapped.
  final VoidCallback onTap;

  // Constructor requiring title, imagePath, and onTap function.
  const AdminCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The card’s visual structure.
    return GestureDetector(
      // Detects tap gestures and triggers the onTap function.
      onTap: onTap,
      // The card widget provides elevation and rounded corners.
      child: Card(
        color: const Color(0xFF0288D1), // Blue background for the card.
        elevation: 6, // Adds a drop shadow.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners.
        ),
        // The main container for the card content.
        child: Container(
          // Padding inside the card.
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          // Row layout: image + title text.
          child: Row(
            children: [
              // Image section of the card.
              ClipRRect(
                // Rounds the image corners slightly.
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  imagePath, // Uses the given image path.
                  width: 80, // Image width.
                  height: 80, // Image height.
                  fit: BoxFit.cover, // Ensures image fills the box.
                ),
              ),
              // Space between image and text.
              const SizedBox(width: 20),
              // Expands text to take remaining horizontal space.
              Expanded(
                child: Text(
                  title, // Displays the card title.
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white, // White text color.
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
