// Import custom database service to interact with Firebase Realtime Database
import 'services/database_service.dart';

// Import Flutter material package for UI components
import "package:flutter/material.dart";

// Import Firebase Authentication package to handle auth-related tasks
import "package:firebase_auth/firebase_auth.dart";

// Import Firebase Realtime Database package
import "package:firebase_database/firebase_database.dart";

// Define a stateful widget for the reset password screen
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key}); // Constructor

  @override
  State<ResetPasswordScreen> createState() => ResetPasswordScreenState();
// Create the mutable state for this widget
}

// State class for ResetPasswordScreen
class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Controller to manage the text input for email
  final TextEditingController emailController = TextEditingController();

  // Key to manage and validate the form
  final formKey = GlobalKey<FormState>();

  // Reference to the root of Firebase Realtime Database
  final DatabaseReference dbRef = DatabaseService.instance.root();

  // Boolean to indicate loading state while performing async tasks
  bool loading = false;

  // Selected user role initialized to 'Customer'
  String selectedRole = 'Customer';

  // List of possible user roles
  final List<String> roles = ['Customer', 'Pharmacist', 'Delivery Person', 'Admin'];

  // Function to handle password reset logic
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;
    // Validate form and exit if invalid

    setState(() => loading = true);
    // Set loading to true to show progress indicator

    final email = emailController.text.trim();
    // Get trimmed email input
    late final String path;
    // Path in database for the selected role

    // Determine database path based on role
    switch (selectedRole) {
      case 'Pharmacist':
        path = 'pharmacists';
        break;
      case 'Delivery Person':
        path = 'delivery_persons';
        break;
      case 'Customer':
        path = 'customers';
        break;
      case 'Admin':
        path = 'admin';
        break;
      default:
        showSnack('Invalid role selected');
        // Show error if role is not valid
        setState(() => loading = false);
        return;
    }

    try {
      // Retrieve data from database under selected role
      final event = await dbRef.child('pharmacy/$path').once();

      if (!mounted) return;
      // Ensure widget is still mounted before updating state

      bool emailExists = false;
      final data = event.snapshot.value;
      // Get snapshot of database node

      if (data is Map) {
        // Check if data is a map
        emailExists = data.values.any(
              (user) => user is Map && user['email'] == email,
          // Check if any user email matches
        );
      }

      if (!emailExists) {
        // If email does not exist in DB
        showSnack('Email not found under selected role');
        setState(() => loading = false);
        return;
      }

      // Send password reset email via FirebaseAuth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      // Ensure widget still exists

      showSnack('Password reset email sent! Check your inbox.');
      Navigator.pop(context);
      // Notify user and return to previous screen
    } catch (e) {
      showSnack('Error: ${e.toString()}');
      // Catch and display any error
    } finally {
      if (mounted) {
        setState(() => loading = false);
        // Reset loading state
      }
    }
  }

  // Helper function to display a SnackBar message
  void showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    // Dispose controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main scaffold for page
      backgroundColor: const Color(0xFFB2F0F6),
      // Light background color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/pharmacy_icon.png',
                width: 150,
                height: 150,
              ), // App icon image
              const SizedBox(height: 16),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ), // Title text
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                    // Update selected role on change
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Your Role',
                  border: OutlineInputBorder(),
                ),
                items: roles
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                // Dropdown list of roles
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter your email to receive password reset link',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ), // Instruction text
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                  // Validate email format
                },
              ),
              const SizedBox(height: 20),
              if (loading)
                const CircularProgressIndicator()
              // Show loader if processing
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: resetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Send Reset Email',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ), // Button to trigger password reset
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Cancel button to go back
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
