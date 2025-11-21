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
        case 'Customer':
          path = 'pharmacy/customers/${user.uid}';
          break;
        case 'Pharmacist':
          path = 'pharmacy/pharmacists/${user.uid}';
          break;
        case 'Delivery Person':
          path = 'pharmacy/delivery_persons/${user.uid}';
          break;
        case 'Admin':
          path = 'pharmacy/admins/${user.uid}';
          break;
        default:
          showMessage('Invalid role selected');
          return;
      }

      final snapshot = await dbRef.child(path).get();

      if (!snapshot.exists) {
        if (selectedRole == 'Admin') {
          // للـ Admin، إذا لم يوجد السجل، ننشئه ونسمح بالدخول
          try {
            await dbRef.child(path).set({
              'email': user.email ?? '',
              'createdAt': DateTime.now().toIso8601String(),
              'role': 'admin',
            });
          } catch (e) {
            debugPrint('Error creating admin record: $e');
            // حتى لو فشل إنشاء السجل، نسمح بالدخول للـ Admin
          }
          // للـ Admin نسمح بالدخول حتى لو لم يكن موجود في قاعدة البيانات
        } else {
          await _auth.signOut();
          if (!mounted) return;
          showMessage(
              'User does not exist for the selected role. Please check your role selection.');
          debugPrint('Checking path: $path');
          debugPrint('User UID: ${user.uid}');
          return;
        }
      }

      if (!mounted) return;

      switch (selectedRole) {
        case 'Customer':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerHome(
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
              ),
            ),
          );
          break;
        case 'Pharmacist':
          final pharmacistSnapshot =
              await dbRef.child('pharmacy/pharmacists/${user.uid}').get();
          final pharmacistData = pharmacistSnapshot.value as Map?;
          final isDarkMode = pharmacistData?['darkMode'] == true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacistHome(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: isDarkMode,
              ),
            ),
          );
          break;
        case 'Delivery Person':
          final deliverySnapshot =
              await dbRef.child('pharmacy/delivery_persons/${user.uid}').get();
          final deliveryData = deliverySnapshot.value as Map?;
          final isDarkMode = deliveryData?['darkMode'] == true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryPersonHome(
                onThemeChanged: widget.onThemeChanged,
                isDarkMode: isDarkMode,
              ),
            ),
          );
          break;
        case 'Admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdminHome(onThemeChanged: widget.onThemeChanged),
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFB2F0F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/pharmacy_icon.png', width: 150, height: 150),
              const SizedBox(height: 16),
              Text(
                'Sign In',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black),
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
                child: Text('Forgot Password?',
                    style: TextStyle(
                        color: isDarkMode ? Colors.lightBlue : Colors.blue)),
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
                  child: Text("Didn't Have an account yet?",
                      style: TextStyle(
                          color: isDarkMode ? Colors.lightBlue : Colors.blue)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
