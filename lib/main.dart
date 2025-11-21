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

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0288D1),
        secondary: const Color(0xFF03A9F4),
        surface: Colors.white,
        background: const Color(0xFFB3E5FC),
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFB3E5FC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0288D1),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF03A9F4),
        secondary: const Color(0xFF0288D1),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: Colors.red.shade400,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF03A9F4),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF03A9F4), width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade700,
        thickness: 1,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmacy Management System',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      home: Login(onThemeChanged: toggleTheme),
    );
  }
}
