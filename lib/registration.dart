import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'customer_home.dart';
import 'login.dart';

class Registration extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const Registration({super.key,required this.onThemeChanged});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final DatabaseReference dbRef = DatabaseService.instance.root();

  String fullName = '';
  String email = '';
  String phoneNumber = '';
  String password = '';
  String confirmPassword = '';

  final _formKey = GlobalKey<FormState>();

  void _registerCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String uid = credential.user!.uid;

        await dbRef.child('pharmacy/customers/$uid').set({
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerHome(
              onThemeChanged: widget.onThemeChanged,
              onLogout: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Login(onThemeChanged: widget.onThemeChanged),
                  ),
                  (_) => false,
                );
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2F0F6),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/pharmacy_icon.png',
                    height: 120,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your full name.' : null,
                    onChanged: (value) => fullName = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email address.';
                      if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,}$').hasMatch(value)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                    onChanged: (value) => email = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your phone number.';
                      if (!RegExp(r'^[97][0-9]{7}$').hasMatch(value)) {
                        return 'Please enter a valid 8-digit phone number. starting with 9 or 7 only';
                      }
                      return null;
                    },
                    onChanged: (value) => phoneNumber = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password.';
                      }
                      if (value.length < 6 || value.length > 20) {
                        return 'Password must be 6-20 characters long.';
                      }
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                        return 'Password must contain at least one lowercase letter.';
                      }
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                        return 'Password must contain at least one uppercase letter.';
                      }
                      if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                        return 'Password must contain at least one number.';
                      }
                      if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
                        return 'Password must contain at least one special character.';
                      }
                      return null;
                    },
                    onChanged: (value) => password = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm your password.';
                      if (value != password) return 'Passwords do not match.';
                      return null;
                    },
                    onChanged: (value) => confirmPassword = value.trim(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(45),
                    ),
                    onPressed: _registerCustomer,
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,

                        MaterialPageRoute(builder: (context) =>  Login(onThemeChanged: widget.onThemeChanged)),
                      );
                    },
                    child: const Text(
                      'Already Have an Account?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

