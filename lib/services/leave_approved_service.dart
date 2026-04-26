import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:management_app/model/leave_approved_model.dart';

class LeaveApprovedService {
  static Future<List<LeaveApprovedModel>> fetchLeaves() async {
    final prefs = await SharedPreferences.getInstance();

    final cookies = prefs.getStringList("cookies") ?? [];
    final employeeId = prefs.getString("employeeId"); // 

    if (employeeId == null || employeeId.isEmpty) {
      throw Exception("EmployeeId not found");
    }

    final url = Uri.parse(
      "https://ppecon.erpnext.com/api/resource/Leave Application"
      "?filters=[[\"employee\",\"=\",\"$employeeId\"]]"
      "&fields=[\"employee_name\",\"leave_type\",\"from_date\",\"to_date\",\"status\",\"description\"]"
      "&order_by=creation desc",
    );

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Cookie": cookies.join("; "),
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List data = decoded['data'];

      return data
          .map((e) => LeaveApprovedModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to fetch leave logs");
    }
  }
}
