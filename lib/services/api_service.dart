import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Auto-detected working backend URL (will be set after successful connection)
  static String? _workingBaseUrl;

  // Environment-based configuration (can be set via --dart-define or .env file)
  static const String _envBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  // Multiple fallback URLs to try automatically
  static const List<String> possibleUrls = [
    'https://agri-stock-backend.onrender.com', // Render Production URL
    'http://10.126.206.31:8000', // Current detected IP
    'http://10.126.122.95:8000', // Previous network IP
    'http://localhost:8000', // Local development
    'http://127.0.0.1:8000', // Localhost alternative
    'http://10.0.2.2:8000', // Android emulator default
    'http://192.168.1.100:8000', // Common local network
    'http://192.168.0.100:8000', // Alternative local network
  ];

  // Get the backend URL (prioritizes environment variable, then platform defaults)
  static String get baseUrl {
    // 1. If an environment variable is provided, use it
    if (_envBackendUrl.isNotEmpty) {
      return _envBackendUrl;
    }

    // 2. If we already auto-detected a working URL, use it
    if (_workingBaseUrl != null) {
      return _workingBaseUrl!;
    }

    // 3. Fallback to platform-specific defaults
    if (kIsWeb) {
      // Web browser always uses localhost
      return 'http://localhost:8000';
    } else {
      // Mobile apps use the Render production URL as default
      return 'https://agri-stock-backend.onrender.com';
    }
  }

  static const String apiPrefix = '/api';

  // Get stored auth token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Store auth token
  static Future<void> _setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remove auth token
  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with auth token if available
  static Future<Map<String, String>> _getHeaders({
    bool requireAuth = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Generic GET request
  static Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await _removeToken();
        throw Exception('Authentication required. Please login again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic POST request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _removeToken();
        throw Exception('Authentication required. Please login again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic PUT request
  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _removeToken();
        throw Exception('Authentication required. Please login again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic PATCH request
  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _removeToken();
        throw Exception('Authentication required. Please login again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // Generic DELETE request
  static Future<dynamic> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$apiPrefix$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _removeToken();
        throw Exception('Authentication required. Please login again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // Get current working backend URL for debugging
  static String getCurrentBackendUrl() {
    return _workingBaseUrl ??
        'Not detected yet (will auto-detect on first request)';
  }

  // Authentication methods with auto-detection
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await post('/auth/login', {
        'username': email,
        'password': password,
      }, requireAuth: false);

      if (response.containsKey('access_token')) {
        await _setToken(response['access_token']);
      }

      return response;
    } catch (e) {
      if (e.toString().contains('Network') ||
          e.toString().contains('connect')) {
        throw Exception(
          'Network Error: Cannot connect to backend server. Please ensure:\n\n1. Backend server is running (python run.py)\n2. Mobile device and laptop are on same WiFi network\n3. Firewall allows connections on port 8000\n\nCurrent backend URL: ${getCurrentBackendUrl()}',
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signup(
    String email,
    String fullName,
    String password,
  ) async {
    try {
      final response = await post('/auth/signup', {
        'email': email,
        'full_name': fullName,
        'password': password,
      }, requireAuth: false);

      return response;
    } catch (e) {
      if (e.toString().contains('Network') ||
          e.toString().contains('connect')) {
        throw Exception(
          'Network Error: Cannot connect to backend server. Please ensure:\n\n1. Backend server is running (python run.py)\n2. Mobile device and laptop are on same WiFi network\n3. Firewall allows connections on port 8000\n\nCurrent backend URL: ${getCurrentBackendUrl()}',
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    return await get('/auth/me');
  }

  static Future<void> logout() async {
    await _removeToken();
  }

  // Health check with auto-detection
  static Future<Map<String, dynamic>> healthCheck() async {
    // First try with current URL
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // If current URL fails, try auto-detection
      print('Current URL failed, trying auto-detection...');
    }

    // Auto-detect working URL
    final workingUrl = await autoDetectBackendUrl();
    _workingBaseUrl = workingUrl;

    // Try again with the detected URL
    try {
      final url = Uri.parse('$workingUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Backend not reachable - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Backend connection failed after auto-detection: ${e.toString()}',
      );
    }
  }

  // Auto-detect working backend URL
  static Future<String> autoDetectBackendUrl() async {
    // If we already found a working URL, use it
    if (_workingBaseUrl != null) {
      return _workingBaseUrl!;
    }

    print('🔍 Auto-detecting backend URL...');

    for (String url in possibleUrls) {
      try {
        print('Testing: $url');
        final testUrl = Uri.parse('$url/health');
        final response = await http
            .get(testUrl)
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          _workingBaseUrl = url;
          print('✅ Found working backend: $url');
          return url;
        }
      } catch (e) {
        print('❌ Failed: $url - ${e.toString()}');
        continue; // Try next URL
      }
    }

    // If no URL works, provide helpful error message
    throw Exception(
      'Could not connect to backend server. Please:\n\n'
      '1. Ensure backend is running: python run.py\n'
      '2. Check if mobile device and laptop are on same WiFi\n'
      '3. Try different IP addresses\n'
      '4. Check firewall settings\n\n'
      'Tested URLs: ${possibleUrls.join(", ")}',
    );
  }
}
