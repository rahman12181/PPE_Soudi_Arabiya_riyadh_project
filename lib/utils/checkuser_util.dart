import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckuserUtils {
  // ================= CHECK USER =================
  static Future<void> checkUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;

    final isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    final token = prefs.getString("authToken");

    print("📱 CheckUser - isLoggedIn: $isLoggedIn, token: $token");

    // Sirf isLoggedIn check karo, employeeId optional hai
    if (isLoggedIn && token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, "/homeScreen");
      return;
    }
    Navigator.pushReplacementNamed(context, "/loginScreen");
  }

  // ================= SAVE LOGIN STATUS (FIXED) =================
  static Future<void> saveloginStatus({
    required String route,
    required String employeeId,
    String? userName,
    String? authToken,
    List<String>? cookies,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    print("📱 Saving login status...");
    print("📱 UserName: $userName");
    print("📱 AuthToken: $authToken");
    print("📱 Cookies: $cookies");

    // BASIC
    await prefs.setBool("isLoggedIn", true);
    await prefs.setString("home_page", "/homeScreen");

    // EMPLOYEE ID - Agar empty hai to bhi save mat karo
    if (employeeId.isNotEmpty) {
      await prefs.setString("employeeId", employeeId);
    }

    // USER NAME
    if (userName != null && userName.trim().isNotEmpty) {
      await prefs.setString("userName", userName.trim());
    }

    // TOKEN
    String? finalToken = authToken;
    if ((finalToken == null || finalToken.isEmpty) &&
        cookies != null &&
        cookies.isNotEmpty) {
      try {
        final sid = cookies.firstWhere((c) => c.startsWith("sid="));
        finalToken = sid.replaceAll("sid=", "").trim();
        print("📱 Extracted SID from cookies: $finalToken");
      } catch (_) {}
    }

    if (finalToken != null && finalToken.isNotEmpty) {
      await prefs.setString("authToken", finalToken.trim());
    }

    // COOKIES
    if (cookies != null && cookies.isNotEmpty) {
      await prefs.setStringList("cookies", cookies);
    }

    print("📱 Login status saved successfully");
  }

  // ================= LOGOUT =================
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, "/loginScreen");
  } 
}