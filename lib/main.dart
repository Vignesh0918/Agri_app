import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-detect working backend URL
  try {
    await AuthService.testConnection();
  } catch (e) {
    debugPrint('Initial backend connection check failed: $e');
  }

  final bool loggedIn = await AuthService.isLoggedIn();
  User? user;
  if (loggedIn) {
    user = await AuthService.getCurrentUser();
  }

  runApp(MyApp(initialUser: user));
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agriculture Shop Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Green
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFEF6C00), // Orange
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default standard font
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: const Color(0xFF2E7D32), // Default primary
            foregroundColor: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      home: initialUser != null
          ? DashboardScreen(userName: initialUser!.fullName)
          : const LoginScreen(),
    );
  }
}
