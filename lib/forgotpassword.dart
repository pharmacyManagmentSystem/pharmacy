import 'services/database_service.dart';
import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_database/firebase_database.dart";
import 'localization/app_localizations.dart';
import 'localization/language_switcher.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final DatabaseReference dbRef = DatabaseService.instance.root();
  bool loading = false;
  String selectedRole = 'Customer';
  final List<String> roles = [
    'Customer',
    'Pharmacist',
    'Delivery Person',
    'Admin'
  ];

  static const String _resetPasswordUrl = 
      'https://pharm-e6550.web.app/reset-password.html';

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final email = emailController.text.trim();
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
        path = 'admin';
        break;
      default:
        showSnack('Invalid role selected');
        setState(() => loading = false);
        return;
    }

    try {
      final event = await dbRef.child('pharmacy/$path').once();

      if (!mounted) return;

      bool emailExists = false;
      final data = event.snapshot.value;

      if (data is Map) {
        emailExists = data.values.any(
          (user) => user is Map && user['email'] == email,
        );
      }

      if (!emailExists) {
        showSnack('Email not found under selected role');
        setState(() => loading = false);
        return;
      }

      // ActionCodeSettings for custom reset password page
      final actionCodeSettings = ActionCodeSettings(
        url: _resetPasswordUrl,
        handleCodeInApp: false, // Reset happens in web page, not in Flutter app
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      if (!mounted) return;

      showSnack('Password reset email sent! Check your inbox.');
      Navigator.pop(context);
    } catch (e) {
      showSnack('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String _getLocalizedRole(AppLocalizations loc, String role) {
    switch (role) {
      case 'Customer':
        return loc.customer;
      case 'Pharmacist':
        return loc.pharmacist;
      case 'Delivery Person':
        return loc.deliveryPerson;
      case 'Admin':
        return loc.admin;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFB2F0F6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Language Switcher
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: LanguageToggleButton(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/pharmacy_icon.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              Text(
                loc.resetPassword,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: loc.selectRole,
                  border: const OutlineInputBorder(),
                ),
                items: roles
                    .map((role) => DropdownMenuItem(
                        value: role, child: Text(_getLocalizedRole(loc, role))))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                loc.isArabic 
                    ? 'أدخل بريدك الإلكتروني لاستلام رابط إعادة تعيين كلمة المرور'
                    : 'Enter your email to receive password reset link',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: loc.email,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.enterEmail;
                  }
                  if (!value.contains('@')) {
                    return loc.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (loading)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(loc.pleaseWait),
                  ],
                )
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
                      child: Text(
                        loc.sendResetEmail,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        loc.cancel,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
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
