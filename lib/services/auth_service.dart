import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class User {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? json['fullName'],
      isActive: json['is_active'] ?? json['isActive'],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class AuthService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      final response = await ApiService.getCurrentUser();
      final user = User.fromJson(response);

      // Cache user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));

      return user;
    } catch (e) {
      // Try to get cached user data
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
      return null;
    }
  }

  // Login
  static Future<User> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);

      // Set logged in status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);

      // Get user data
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Failed to get user data after login');
      }

      return user;
    } catch (e) {
      // Make sure login status is false on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      rethrow;
    }
  }

  // Signup
  static Future<User> signup(String email, String fullName, String password) async {
    try {
      final response = await ApiService.signup(email, fullName, password);

      // Set logged in status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);

      // Get user data
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Failed to get user data after signup');
      }

      return user;
    } catch (e) {
      // Make sure login status is false on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      rethrow;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      // Even if API call fails, clear local data
      print('API logout failed: $e');
    }

    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Check backend connection
  static Future<bool> checkBackendConnection() async {
    try {
      await ApiService.healthCheck();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get detailed connection status
  static Future<String> getConnectionStatus() async {
    try {
      final health = await ApiService.healthCheck();
      return '✅ Connected to backend\n'
             'URL: ${ApiService.getCurrentBackendUrl()}\n'
             'Database: ${health['database']}\n'
             'Status: ${health['status']}';
    } catch (e) {
      return '❌ Connection Failed\n'
             'Error: ${e.toString()}\n'
             'Current URL: ${ApiService.getCurrentBackendUrl()}\n\n'
             '🔧 Troubleshooting Steps:\n\n'
             '1. Backend Server:\n'
             '   • Run: cd backend && python run.py\n'
             '   • Check: Server shows "Application startup complete"\n\n'
             '2. Network Connection:\n'
             '   • Ensure mobile device and laptop are on same WiFi\n'
             '   • Try different IP addresses\n'
             '   • Check if firewall blocks port 8000\n\n'
             '3. Test Connection:\n'
             '   • Open browser: http://[IP]:8000/docs\n'
             '   • Should show FastAPI documentation\n\n'
             '4. Alternative Solutions:\n'
             '   • Use mobile hotspot from laptop\n'
             '   • Connect both devices to same network\n'
             '   • Try USB debugging with ADB reverse';
    }
  }

  // Quick connectivity test
  static Future<bool> testConnection() async {
    try {
      await ApiService.healthCheck();
      return true;
    } catch (e) {
      return false;
    }
  }
}
