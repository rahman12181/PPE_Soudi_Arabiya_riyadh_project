import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeAdvanceService {
  static const String _baseUrl = "https://ppecon.erpnext.com/api";
  static const Duration _timeout = Duration(seconds: 30);

  // ================= SESSION =================
  Future<String?> _getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString("authToken");

    if (sid != null && sid.isNotEmpty) {
      return sid.trim();
    }

    return null;
  }

  // ================= EMPLOYEE ID =================
  Future<String> _getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final emp = prefs.getString("employeeId");

    if (emp != null && emp.isNotEmpty) {
      return emp.trim();
    }

    throw Exception("Employee ID not found. Please login again.");
  }

  // ================= HEADERS =================
  Future<Map<String, String>> _getHeaders() async {
    final sid = await _getSessionId();

    if (sid == null) {
      throw Exception("Session expired. Please login again.");
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cookie': 'sid=$sid',

      // 🔥 VERY IMPORTANT (Fix 417)
      'Expect': '',
    };
  }

  // ================= SUBMIT ADVANCE =================
  Future<Map<String, dynamic>> submitAdvance({
    required double advanceAmount,
    required String purpose,
    required String advanceAccount,
    required String modeOfPayment,
    bool repayFromSalary = true,
  }) async {
    try {
      final headers = await _getHeaders();
      final employeeId = await _getEmployeeId();

      const endpoint =
          '/method/ppecon_erp.employee_advance.employee_advance.submit_employee_advance_from_mobile';

      final url = Uri.parse('$_baseUrl$endpoint');

      final body = {
        "employee": employeeId, // ✅ REQUIRED
        "advance_amount": advanceAmount,
        "purpose": purpose,
        "advance_account": advanceAccount,
        "mode_of_payment": modeOfPayment,
        "repay_unclaimed_amount_from_salary": repayFromSalary ? 1 : 0,
      };

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Advance submitted successfully',
          'data': data,
        };
      }

      return {
        'success': false,
        'message': 'Failed (${response.statusCode})',
        'error': response.body,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ================= FETCH ADVANCE HISTORY =================
  Future<Map<String, dynamic>> getAppliedAdvances() async {
    try {
      final headers = await _getHeaders();
      final employeeId = await _getEmployeeId();

      final filters = jsonEncode([
        ["employee", "=", employeeId],
      ]);

      final fields = jsonEncode([
        "name",
        "employee",
        "employee_name",
        "posting_date",
        "advance_amount",
        "status",
        "workflow_state", 
        "purpose",
      ]);

      final url = Uri.parse(
        "$_baseUrl/resource/Employee Advance"
        "?fields=${Uri.encodeComponent(fields)}"
        "&filters=${Uri.encodeComponent(filters)}"
        "&order_by=posting_date desc",
      );

      final response = await http.get(url, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["data"] is List) {
          final list = List<Map<String, dynamic>>.from(data["data"]);

          final mappedList = list.map((item) {
            return {
              ...item,
              "status": item["workflow_state"] ?? item["status"] ?? "Draft",
            };
          }).toList();

          return {
            "success": true,
            "message": "History loaded",
            "data": mappedList,
            "total": mappedList.length,
          };
        }

        return {
          "success": true,
          "message": "No records found",
          "data": [],
          "total": 0,
        };
      }

      return {
        "success": false,
        "message": "Failed (${response.statusCode})",
        "error": response.body,
        "data": [],
      };
    } catch (e) {

      return {"success": false, "message": e.toString(), "data": []};
    }
  }

  // ================= STATIC DATA =================
  Future<Map<String, dynamic>> getAdvanceAccounts() async {
    return {
      'success': true,
      'data': [
        "1610 - Employee Advances - PPE",
        "Cash - Petty Cash",
        "1620 - Travel Advances - PPE",
      ],
    };
  }

  Future<Map<String, dynamic>> getPaymentModes() async {
    return {
      'success': true,
      'data': ["Cash", "Bank Transfer", "Cheque", "Online Payment"],
    };
  }
}
