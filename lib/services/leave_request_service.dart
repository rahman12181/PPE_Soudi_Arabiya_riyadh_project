import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LeaveRequestService {
  static const String _baseUrl = "https://ppecon.erpnext.com";
  
  static const String _customLeaveApi = "$_baseUrl/api/method/ppecon_erp.leave_application.leave_application.submit_leave_from_mobile";

  static Map<String, String> leaveTypeMapping = {
    "CL": "Annual Leave",
    "SL": "Sick Leave",
    "EL": "Umrah Leave",
    "UL": "Unpaid Leave",
    "ML": "Maternity Leave",
    "PL": "Paternity Leave",
  };

  static String mapLeaveType(String? value) {
    if (value == null || value.isEmpty) return "";
    
    if (leaveTypeMapping.containsValue(value)) {
      return value;
    }
    
    return leaveTypeMapping[value] ?? value;
  }

  static String _formatDate(String date) {
    try {
      if (date.contains("-")) {
        final parts = date.split("-");
        if (parts.length == 3) {
          if (parts[0].length == 2 && parts[2].length == 4) {
            return "${parts[2]}-${parts[1]}-${parts[0]}";
          } else if (parts[0].length == 4 && parts[2].length == 2) {
            return date;
          }
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
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> submitLeave({
    required String employeeCode,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required String compOff,
    required String inchargeReplacement,
  }) async {
    // Check internet connection
    if (!await _hasInternet()) {
      return {
        "success": false,
        "message": "No internet connection. Please check your connection and try again.",
      };
    }

    try {
      // Load authentication cookies
      await AuthService.loadCookies();
      
      if (AuthService.cookies.isEmpty) {
        return {
          "success": false,
          "message": "Your session has expired. Please login again.",
        };
      }

      // Validate required fields
      if (employeeCode.isEmpty) {
        return {
          "success": false,
          "message": "Employee code is required",
        };
      }

      if (leaveType.isEmpty) {
        return {
          "success": false, 
          "message": "Leave type is required",
        };
      }

      // Prepare request body according to your custom API format
      final body = {
        "employee": employeeCode.trim(),
        "leave_type": leaveType.trim(),
        "from_date": _formatDate(fromDate.trim()),
        "to_date": _formatDate(toDate.trim()),
        "incharge_replacement": inchargeReplacement.isNotEmpty 
            ? inchargeReplacement.trim() 
            : "Temporary Incharge",
        "ticket": compOff == "YES" ? "Yes (On Company)" : "No",
        "description": reason.isNotEmpty 
            ? reason.trim() 
            : "Leave application submitted from mobile app",
      };

      print("=== LEAVE SUBMISSION REQUEST ===");
      print("URL: $_customLeaveApi");
      print("Body: ${jsonEncode(body)}");
      print("Cookies: ${AuthService.cookies.length} cookies present");

      // Make POST request to your custom API
      final response = await http.post(
        Uri.parse(_customLeaveApi),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": AuthService.cookies.join("; "),
          "X-Frappe-CSRF-Token": await _getCsrfToken(),
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print("=== RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Check for successful response from custom API
        if (decoded.containsKey("message")) {
          final message = decoded["message"];
          
          if (message is Map) {
            final status = message["status"]?.toString() ?? "";
            final workflowState = message["workflow_state"]?.toString() ?? "";
            final docId = message["name"]?.toString() ?? "";
            final docStatus = message["docstatus"]?.toString() ?? "";
            final appMessage = message["message"]?.toString() ?? "Leave applied successfully";
            
            // Validate that it's not in Draft state
            if (workflowState == "Draft" || status == "Draft") {
              return {
                "success": false,
                "message": "Leave was saved as Draft. This might be a workflow configuration issue. Please contact administrator.",
                "document_id": docId,
                "workflow_state": workflowState,
              };
            }
            
            // Success - leave is in workflow
            String successMessage = appMessage;
            if (workflowState.isNotEmpty && workflowState != "Draft") {
              successMessage += "\nStatus: $workflowState";
            }
            
            return {
              "success": true,
              "message": successMessage,
              "document_id": docId,
              "workflow_state": workflowState,
              "status": status,
              "docstatus": docStatus,
            };
          }
        }
        
        // If response structure is different but status is 200
        return {
          "success": true,
          "message": "Leave application submitted successfully!",
        };
      }

      // Handle error responses
      if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          "success": false,
          "message": "Authentication failed. Please login again.",
        };
      }

      if (response.statusCode == 400) {
        return {
          "success": false,
          "message": "Bad request. Please check your input data.",
        };
      }

      if (response.statusCode == 500) {
        return {
          "success": false,
          "message": "Server error. Please try again later or contact administrator.",
        };
      }

      // Extract error message from response
      String errorMessage = "Failed to submit leave application";
      
      if (decoded.containsKey("exception")) {
        errorMessage = _extractErrorMessage(decoded["exception"]);
      } else if (decoded.containsKey("_server_messages")) {
        try {
          final serverMessages = decoded["_server_messages"];
          if (serverMessages is String) {
            final messages = jsonDecode(serverMessages);
            if (messages is List && messages.isNotEmpty) {
              final firstMsg = jsonDecode(messages[0]);
              errorMessage = firstMsg["message"] ?? errorMessage;
            }
          }
        } catch (e) {
          print("Error parsing server messages: $e");
        }
      } else if (decoded.containsKey("message")) {
        errorMessage = decoded["message"].toString();
      }

      return {
        "success": false,
        "message": errorMessage,
      };

    } on TimeoutException {
      return {
        "success": false,
        "message": "Request timeout. Please check your internet connection and try again.",
      };
    } on SocketException {
      return {
        "success": false,
        "message": "Network error. Please check your internet connection.",
      };
    } on FormatException {
      return {
        "success": false,
        "message": "Invalid response from server. Please try again.",
      };
    } catch (e, stackTrace) {
      print("Unexpected error: $e");
      print("Stack trace: $stackTrace");
      return {
        "success": false,
        "message": "An unexpected error occurred: ${e.toString()}",
      };
    }
  }

  // Helper to get CSRF token from cookies
  static Future<String> _getCsrfToken() async {
    for (var cookie in AuthService.cookies) {
      if (cookie.contains("csrf_token")) {
        final parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) return parts[1];
      }
    }
    return "";
  }

  static String _extractErrorMessage(String error) {
    error = error.toLowerCase();
    
    if (error.contains("mandatoryerror") || error.contains("required")) {
      return "Required information is missing. Please fill all fields.";
    }
    if (error.contains("validationerror")) {
      return "Validation error. Please check your input data.";
    }
    if (error.contains("authentication") || error.contains("session") || error.contains("login")) {
      return "Session expired. Please login again.";
    }
    if (error.contains("duplicate") || error.contains("already exists")) {
      return "Leave application already exists for these dates.";
    }
    if (error.contains("permission") || error.contains("not allowed")) {
      return "You don't have permission to apply leave.";
    }
    if (error.contains("overlap")) {
      return "Leave dates overlap with existing leave.";
    }
    if (error.contains("balance")) {
      return "Insufficient leave balance.";
    }
    
    return "Unable to process request. Please try again.";
  }

  // Optional: Add a method to check leave balance
  static Future<Map<String, dynamic>> checkLeaveBalance({
    required String employee,
    required String leaveType,
  }) async {
    try {
      await AuthService.loadCookies();
      
      if (AuthService.cookies.isEmpty) {
        return {"success": false, "message": "Not authenticated"};
      }
      
      final response = await http.get(
        Uri.parse("$_baseUrl/api/method/frappe.client.get_list?doctype=Leave Allocation&fields=[\"name\",\"total_leaves_allocated\",\"expired\",\"leaves_taken\"]&filters=[[\"employee\",\"=\",\"$employee\"],[\"leave_type\",\"=\",\"$leaveType\"],[\"docstatus\",\"=\",1]]"),
        headers: {
          "Cookie": AuthService.cookies.join("; "),
        },
      );
      
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      
      return {"success": false, "message": "Failed to fetch leave balance"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}