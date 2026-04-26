import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class EmployeeProvider extends ChangeNotifier {
  String? employeeId;
  bool isLoading = false;

  final String baseUrl = "https://ppecon.erpnext.com";

  Future<void> fetchAndSaveEmployeeId(String email) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await AuthService.client.get(
        Uri.parse(
          '$baseUrl/api/resource/Employee'
          '?filters=[["user_id","=","$email"]]'
          '&fields=["name"]',
        ),
        headers: {
          "Cookie": AuthService.cookies.join(';'),
        },
      );

      final json = jsonDecode(response.body);

      if (json["data"] == null || json["data"].isEmpty) {
        throw Exception("Employee not linked with this user");
      }

      employeeId = json["data"][0]["name"];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("employeeId", employeeId!);

      debugPrint("Employee ID saved: $employeeId");
      notifyListeners();
    } catch (e) {
      debugPrint("Employee ID fetch error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadEmployeeIdFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    employeeId = prefs.getString("employeeId");
    notifyListeners();
  }
}