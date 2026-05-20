import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LeaveRequestService {
  static const String _baseUrl = "https://ppecon.erpnext.com";
  static const String _leaveApi =
      "$_baseUrl/api/method/ppecon_erp.leave_application.leave_application.submit_leave_from_mobile";

  static const Map<String, String> leaveTypeMapping = {
    "CL": "Annual Leave",
    "SL": "Sick Leave",
    "UL": "Unpaid Leave",
    "ML": "Maternity Leave",
    "PL": "Paternity Leave",
  };

  static const List<String> ticketOptions = [
    "Not Required",
    "Provide By Company",
    "Self (Employee)",
  ];

  static const List<String> exitReentryOptions = [
    "Not Required",
    "Provide By Company",
    "Self (Employee)",
  ];

  static String mapLeaveType(String? value) {
    if (value == null || value.isEmpty) return "";
    if (leaveTypeMapping.containsValue(value)) return value;
    return leaveTypeMapping[value] ?? value;
  }

  static String _formatDate(String date) {
    try {
      if (date.contains("-")) {
        final parts = date.split("-");
        if (parts.length == 3) {
          if (parts[0].length == 2 && parts[2].length == 4) {
            return "${parts[2]}-${parts[1]}-${parts[0]}";
          }
          if (parts[0].length == 4) return date;
        }
      }
      return date;
    } catch (_) {
      return date;
    }
  }

  static Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup("google.com");
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  static Future<String> _getCsrfToken() async {
    for (var cookie in AuthService.cookies) {
      if (cookie.contains("csrf_token")) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) return Uri.decodeComponent(parts[1]);
      }
    }
    return "";
  }

  static Future<Map<String, dynamic>> submitLeave({
    required String employeeCode,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required String inchargeReplacement,
    required String ticket,
    required String exitReentry,
  }) async {
    if (!await _hasInternet()) {
      return {
        "success": false,
        "message": "No internet connection. Please check your connection.",
      };
    }

    await AuthService.loadCookies();
    if (AuthService.cookies.isEmpty) {
      return {
        "success": false,
        "message": "Session expired. Please login again.",
      };
    }

    // Local validations
    if (employeeCode.trim().isEmpty)
      return {"success": false, "message": "Employee code is required."};
    if (leaveType.trim().isEmpty)
      return {"success": false, "message": "Leave type is required."};
    if (fromDate.trim().isEmpty)
      return {"success": false, "message": "From date is required."};
    if (toDate.trim().isEmpty)
      return {"success": false, "message": "To date is required."};
    if (reason.trim().isEmpty)
      return {"success": false, "message": "Reason for leave is required."};
    if (inchargeReplacement.trim().isEmpty)
      return {"success": false, "message": "Incharge replacement is required."};

    final body = {
      "employee": employeeCode.trim(),
      "leave_type": leaveType.trim(),
      "from_date": _formatDate(fromDate.trim()),
      "to_date": _formatDate(toDate.trim()),
      "description": reason.trim(),
      "incharge_replacement": inchargeReplacement.trim(),
      "ticket": ticket,
      "exit_reentry": exitReentry,
    };

    final csrfToken = await _getCsrfToken();

    print("=== LEAVE SUBMISSION ===");
    print("URL  : $_leaveApi");
    print("Body : ${jsonEncode(body)}");
    print("CSRF : $csrfToken");

    try {
      final response = await http
          .post(
            Uri.parse(_leaveApi),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Cookie": AuthService.cookies.join("; "),
              "X-Frappe-CSRF-Token": csrfToken,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print("=== RESPONSE ===");
      print("Status : ${response.statusCode}");
      print("Body   : ${response.body}");

      Map<String, dynamic> decoded = {};
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {"success": false, "message": "Invalid response from server."};
      }

      if (response.statusCode == 200) {
        final message = decoded["message"];
        if (message is Map) {
          final workflowState = message["workflow_state"]?.toString() ?? "";
          final docId = message["name"]?.toString() ?? "";
          final appMessage =
              message["message"]?.toString() ?? "Leave applied successfully!";
          if (workflowState == "Draft") {
            return {
              "success": false,
              "message": "Leave saved as Draft. Please contact administrator.",
              "document_id": docId,
            };
          }
          return {
            "success": true,
            "message": workflowState.isNotEmpty
                ? "$appMessage\nStatus: $workflowState"
                : appMessage,
            "document_id": docId,
            "workflow_state": workflowState,
          };
        }
        return {
          "success": true,
          "message":
              message?.toString() ??
              "Leave application submitted successfully!",
        };
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          "success": false,
          "message": "Authentication failed. Please login again.",
        };
      }

      return {
        "success": false,
        "message": _extractBestMessage(decoded, response.statusCode),
      };
    } on TimeoutException {
      return {
        "success": false,
        "message": "Request timed out. Please try again.",
      };
    } on SocketException {
      return {
        "success": false,
        "message": "Network error. Please check your internet.",
      };
    } catch (e, st) {
      print("Error: $e\n$st");
      return {
        "success": false,
        "message": "An unexpected error occurred. Please try again.",
      };
    }
  }

  static String _extractBestMessage(
    Map<String, dynamic> decoded,
    int statusCode,
  ) {
    try {
      final raw = decoded["_server_messages"];
      if (raw != null) {
        final list = jsonDecode(raw.toString()) as List;
        if (list.isNotEmpty) {
          final inner = jsonDecode(list.first.toString());
          final msg = (inner["message"] ?? inner["title"] ?? "").toString();
          if (msg.isNotEmpty) return _friendlyMessage(msg);
        }
      }
    } catch (_) {}
    final exception = decoded["exception"]?.toString() ?? "";
    if (exception.isNotEmpty) return _friendlyMessage(exception);
    final message = decoded["message"];
    if (message is String && message.isNotEmpty)
      return _friendlyMessage(message);
    if (statusCode == 400) return "Bad request. Please check your input.";
    if (statusCode == 500) return "Server error. Please try again later.";
    return "Failed to submit leave. Please try again.";
  }

  static String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains("overlap") || lower.contains("already applied"))
      return "Leave dates overlap with an existing application.";
    if (lower.contains("balance") || lower.contains("insufficient"))
      return "Insufficient leave balance.";
    if (lower.contains("permission") || lower.contains("not allowed"))
      return "You don't have permission to apply this leave.";
    if (lower.contains("duplicate") || lower.contains("already exists"))
      return "A leave application already exists for these dates.";
    if (lower.contains("session") || lower.contains("login"))
      return "Session expired. Please login again.";
    if (lower.contains("mandatory") || lower.contains("required"))
      return "Required information is missing. Please fill all fields.";
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
