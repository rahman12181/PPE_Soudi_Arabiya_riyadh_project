import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = "https://ppecon.erpnext.com";

  static List<String> cookies = [];
  static Client client = Client();
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();

  // ================= COOKIE MANAGEMENT =================
  static Future<void> saveCookies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cookies', cookies);
  }

  static Future<void> loadCookies() async {
    final prefs = await SharedPreferences.getInstance();
    cookies = prefs.getStringList('cookies') ?? [];
  }

  static void updateCookies(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final cookieList = rawCookie.split(RegExp(r',(?! )'));
      cookies = cookieList.map((c) => c.split(';')[0].trim()).toList();
      saveCookies();
    }
  }

  Map<String, String> buildHeaders({bool isJson = false}) {
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    
    if (cookies.isNotEmpty) {
      headers["Cookie"] = cookies.join('; ');
    }
    return headers;
  }

  String? extractSid() {
    for (final cookie in cookies) {
      if (cookie.startsWith("sid=")) {
        return cookie.replaceFirst("sid=", "").trim();
      }
    }
    return null;
  }

  // ================= LOGIN =================
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/method/login");

    try {
      cookies.clear();

      print("📱 Logging in with: $email");
      
      final response = await client.post(
        url,
        headers: buildHeaders(isJson: true),
        body: jsonEncode({"usr": email, "pwd": password}),
      );

      print("📱 Response Status: ${response.statusCode}");
      print("📱 Response Body: ${response.body}");

      updateCookies(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["message"] == "Logged In") {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("email", email);
        
        String fullName = data["full_name"] ?? email.split('@')[0];
        await prefs.setString("full_name", fullName);
        
        await prefs.setString("home_page", "/homeScreen");

        await secureStorage.write(key: "password", value: password);

        print("✅ Login Successful for: $fullName");

        return {
          "success": true,
          "message": "Login successful",
          "full_name": fullName,
          "sid": extractSid(),
          "email": email,
          "cookies": cookies,
        };
      }

      print("❌ Login Failed: ${data["message"]}");
      return {
        "success": false,
        "message": data["message"] ?? "Login failed",
        "exc_type": data["exc_type"] ?? "UnknownError",
      };
    } catch (e) {
      print("❌ Login Error: $e");
      return {
        "success": false,
        "message": "Something went wrong: $e",
        "error": e.toString()
      };
    }
  }

  // ================= AUTO RELOGIN =================
  static Future<bool> _autoRelogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    final password = await secureStorage.read(key: "password");

    if (email == null || password == null) return false;

    final auth = AuthService();
    final result = await auth.loginUser(email: email, password: password);
    return result["success"] == true;
  }

  // ================= SAFE REQUEST =================
  static Future<http.Response> safeRequest(
      Future<http.Response> Function() requestFunction) async {
    await loadCookies();
    http.Response response = await requestFunction();

    if (response.statusCode == 401) {
      final reloginSuccess = await _autoRelogin();
      if (reloginSuccess) {
        response = await requestFunction();
      }
    }
    return response;
  }

  // UPDATED LOGOUT - Preserves Punch Data 
  Future<Map<String, dynamic>> logoutUser() async {
    final url = Uri.parse("$baseUrl/api/method/logout");

    try {
      await client.get(url, headers: buildHeaders());
      cookies.clear();
      await saveCookies();

      final prefs = await SharedPreferences.getInstance();
      
      //  IMPORTANT: Backup punch data before clearing everything
      final Map<String, String> punchDataBackup = {};
      
      // Get all keys from SharedPreferences
      final Set<String> allKeys = prefs.getKeys();
      
      // Find and backup all punch-related data (IN_ and OUT_ keys)
      for (String key in allKeys) {
        if (key.startsWith('IN_') || key.startsWith('OUT_')) {
          final String? value = prefs.getString(key);
          if (value != null) {
            punchDataBackup[key] = value;
            debugPrint(" Backing up punch data: $key = $value");
          }
        }
      }

      final String? rememberedEmail = prefs.getString('rememberedEmail');
      final String? rememberedPassword = prefs.getString('rememberedPassword');
      final bool rememberMe = prefs.getBool('rememberMe') ?? false;
      
      // Clear all SharedPreferences
      await prefs.clear();
      debugPrint("🗑️ SharedPreferences cleared");
      
      //  Restore punch data backup
      for (var entry in punchDataBackup.entries) {
        await prefs.setString(entry.key, entry.value);
        debugPrint("♻️ Restored punch data: ${entry.key}");
      }

      // Restore Remember Me data
      if (rememberMe) {
        if (rememberedEmail != null) await prefs.setString('rememberedEmail', rememberedEmail);
        if (rememberedPassword != null) await prefs.setString('rememberedPassword', rememberedPassword);
        await prefs.setBool('rememberMe', true);
        debugPrint("♻️ Restored Remember Me data");
      }
      
      // Clear secure storage (password only)
      await secureStorage.delete(key: "password");

      debugPrint("✅ Logout successful - Punch data preserved");

      return {"success": true, "message": "Logged out successfully"};
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      return {"success": false, "message": "Something went wrong"};
    }
  }

  // ================= FORGOT PASSWORD =================
  Future<String> forgotPassword(String email) async {
  final url = Uri.parse(
      "$baseUrl/api/method/frappe.core.doctype.user.user.reset_password");

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
      },
      body: {"user": email},
    );

    // Frappe returns 200 on success
    if (response.statusCode == 200) {
      return "Reset link sent successfully.";
    }

    // Show actual error for debugging
    throw Exception("Server error ${response.statusCode}: ${response.body}");
  } on SocketException {
    throw Exception("No internet connection.");
  } on TimeoutException {
    throw Exception("Request timed out.");
  }
}

  // ================= INITIAL ROUTE =================
  Future<String> getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    
    if (isLoggedIn) {
      return '/homeScreen';
    }
    return '/loginScreen';
  }
}