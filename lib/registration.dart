import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';
import 'customer_home.dart';
import 'login.dart';
import 'localization/app_localizations.dart';

class Registration extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const Registration({super.key, required this.onThemeChanged});

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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();

  void _registerCustomer() async {
    final loc = AppLocalizations.of(context)!;
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
          'status': 'active',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.registrationSuccessful)),
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
                    builder: (context) =>
                        Login(onThemeChanged: widget.onThemeChanged),
                  ),
                  (_) => false,
                );
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.registrationFailed}: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFB2F0F6),
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
                  Text(
                    loc.signUp,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.lightBlue : Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: loc.fullName,
                      border: const OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0600-\u06FF\s]')),
                    ],
                    validator: (value) => value == null || value.isEmpty
                        ? loc.enterFullName
                        : null,
                    onChanged: (value) => fullName = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: loc.emailAddress,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.enterEmail;
                      }
                      if (!RegExp(
                              r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,}$')
                          .hasMatch(value)) {
                        return loc.invalidEmail;
                      }
                      return null;
                    },
                    onChanged: (value) => email = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: loc.phoneNumber,
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 8,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.enterPhoneNumber;
                      }
                      if (value.length != 8) {
                        return loc.isArabic 
                            ? 'يجب أن يكون رقم الهاتف 8 أرقام'
                            : 'Phone number must be 8 digits';
                      }
                      if (!RegExp(r'^[97]').hasMatch(value)) {
                        return loc.isArabic 
                            ? 'يجب أن يبدأ الرقم بـ 9 أو 7'
                            : 'Phone number must start with 9 or 7';
                      }
                      return null;
                    },
                    onChanged: (value) => phoneNumber = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: loc.password,
                      border: const OutlineInputBorder(),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    maxLength: 18,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.enterPassword;
                      }
                      if (value.length < 6 || value.length > 18) {
                        return loc.isArabic 
                            ? 'كلمة المرور يجب أن تكون بين 6 و 18 حرف'
                            : 'Password must be between 6 and 18 characters';
                      }
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                        return loc.isArabic 
                            ? 'كلمة المرور يجب أن تحتوي على حرف صغير'
                            : 'Password must contain at least one lowercase letter.';
                      }
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                        return loc.isArabic 
                            ? 'كلمة المرور يجب أن تحتوي على حرف كبير'
                            : 'Password must contain at least one uppercase letter.';
                      }
                      if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                        return loc.isArabic 
                            ? 'كلمة المرور يجب أن تحتوي على رقم'
                            : 'Password must contain at least one number.';
                      }
                      if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])')
                          .hasMatch(value)) {
                        return loc.isArabic 
                            ? 'كلمة المرور يجب أن تحتوي على رمز خاص'
                            : 'Password must contain at least one special character.';
                      }
                      return null;
                    },
                    onChanged: (value) => password = value.trim(),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: loc.confirmPassword,
                      border: const OutlineInputBorder(),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    maxLength: 18,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.confirmPassword;
                      }
                      if (value != password) {
                        return loc.isArabic 
                            ? 'كلمات المرور غير متطابقة'
                            : 'Passwords do not match.';
                      }
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
                    child: Text(loc.signUp),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                Login(onThemeChanged: widget.onThemeChanged)),
                      );
                    },
                    child: Text(
                      loc.haveAccount,
                      style: TextStyle(
                          color: isDarkMode ? Colors.lightBlue : Colors.blue),
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
