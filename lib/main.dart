import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'login.dart';
import 'state/customer_app_state.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerAppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final customerSnapshot = await DatabaseService.instance
            .ref('pharmacy/customers/${user.uid}')
            .get();
        
        if (customerSnapshot.exists && customerSnapshot.value is Map) {
          final data = customerSnapshot.value as Map;
          final darkMode = data['darkMode'] == true;
          if (mounted) {
            setState(() {
              _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
              _isLoading = false;
            });
          }
          return;
        }

        final pharmacistSnapshot = await DatabaseService.instance
            .ref('pharmacy/pharmacists/${user.uid}')
            .get();
        
        if (pharmacistSnapshot.exists && pharmacistSnapshot.value is Map) {
          final data = pharmacistSnapshot.value as Map;
          final darkMode = data['darkMode'] == true;
          if (mounted) {
            setState(() {
              _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
              _isLoading = false;
            });
          }
          return;
        }

        final deliverySnapshot = await DatabaseService.instance
            .ref('pharmacy/delivery_persons/${user.uid}')
            .get();
        
        if (deliverySnapshot.exists && deliverySnapshot.value is Map) {
          final data = deliverySnapshot.value as Map;
          final darkMode = data['darkMode'] == true;
          if (mounted) {
            setState(() {
              _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        debugPrint('Error loading theme mode: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy Management System ',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: Login(onThemeChanged: toggleTheme),
    );
  }
}
