import 'services/database_service.dart';
import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_database/firebase_database.dart";

import "adminhome.dart";
import "customer_home.dart";
import "delivery_person_home.dart";
import "forgotpassword.dart";
import "pharmacist_home.dart";
import "registration.dart";

class Login extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const Login({super.key, required this.onThemeChanged});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference dbRef = DatabaseService.instance.root();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'Customer';
  final List<String> roles = [
    'Customer',
    'Pharmacist',
    'Delivery Person',
    'Admin'
  ];

  Future<void> loginUser() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = userCredential.user;
      if (user == null) {
        showMessage('Login failed');
        return;
      }

      late final String path;
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
          path = 'admins';
          break;
        default:
          showMessage('Invalid role selected ');
          return;
      }

      final snapshot = await dbRef
          .child('pharmacy/$path')
          .orderByChild('email')
          .equalTo(email)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        if (selectedRole == 'Customer' && snapshot.value is Map) {
          final data = snapshot.value as Map;
          final userData = data.values.first;
          if (userData is Map) {
            final status =
                userData['status']?.toString().toLowerCase() ?? 'active';
            if (status == 'suspended') {
              showMessage(
                  'Your account has been suspended. Please contact support.');
              return;
            }
            if (status == 'deleted') {
              showMessage(
                  'Your account has been deleted. Please contact support.');
              return;
            }
          }
        }

        bool userDarkMode = false;
        if (snapshot.value is Map) {
          final allUsers = snapshot.value as Map;
          for (var userEntry in allUsers.entries) {
            final userData = userEntry.value;
            if (userData is Map && userData['email'] == email) {
              userDarkMode = userData['darkMode'] == true;
              break;
            }
          }
        }

        widget.onThemeChanged(userDarkMode);

        late final Widget destination;
        switch (selectedRole) {
          case 'Pharmacist':
            destination = PharmacistHome(
              onThemeChanged: widget.onThemeChanged,
              isDarkMode: userDarkMode,
            );
            break;
          case 'Delivery Person':
            destination = DeliveryPersonHome(
              onThemeChanged: widget.onThemeChanged,
              isDarkMode: userDarkMode,
            );
            break;
          case 'Customer':
            destination = CustomerHome(
              onThemeChanged: widget.onThemeChanged,
              onLogout: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Login(onThemeChanged: widget.onThemeChanged),
                  ),
                  (_) => false,
                );
              },
            );
            break;
          case 'Admin':
            destination = AdminHome(onThemeChanged: widget.onThemeChanged);
            break;
          default:
            destination = Login(onThemeChanged: widget.onThemeChanged);
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      } else {
        showMessage('No user data found for this role with this email');
      }
    } catch (e) {
      showMessage('Login failed: ${e.toString()}');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2F0F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/pharmacy_icon.png', width: 150, height: 150),
              const SizedBox(height: 16),
              const Text(
                'Sign In',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Select Your Role'),
                items: roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Sign In', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordScreen(),
                    ),
                  );
                },
                child: const Text('Forgot Password?',
                    style: TextStyle(color: Colors.blue)),
              ),
              if (selectedRole == 'Customer')
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Registration(onThemeChanged: widget.onThemeChanged),
                      ),
                    );
                  },
                  child: const Text("Didn't Have an account yet?",
                      style: TextStyle(color: Colors.blue)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
