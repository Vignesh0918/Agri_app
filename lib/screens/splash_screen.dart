import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Brief delay for branding/splash effect
    await Future.delayed(const Duration(milliseconds: 1500));

    // 2. Test Connection (Non-blocking or with timeout)
    try {
      // Try to connect to backend, but don't wait forever if it's already working
      AuthService.testConnection().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Splash connection check timed out/failed: $e');
    }

    // 3. Check Login Status
    final bool loggedIn = await AuthService.isLoggedIn();

    if (loggedIn) {
      try {
        final user = await AuthService.getCurrentUser();
        if (user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(userName: user.fullName),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Failed to get current user in splash: $e');
      }
    }

    // 4. Default to Login
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, size: 80, color: primaryGreen),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              "Agri Shop Manager",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Modern Stock & Sale Solution",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}
