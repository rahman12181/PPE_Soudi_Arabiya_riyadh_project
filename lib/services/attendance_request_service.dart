import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceRequestService {
  static const String baseUrl = "https://ppecon.erpnext.com";

  Future<void> submitRequest({
    required DateTime date,
    required String reason,
    required String explanation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getString("employeeId");
    final cookies = prefs.getStringList("cookies");

    if (employeeId == null || employeeId.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    if (cookies == null || cookies.isEmpty) {
      throw Exception("Authentication failed. Please login again.");
    }

    try {
      final createUrl = Uri.parse("$baseUrl/api/resource/Attendance%20Request");

      final createBody = {
        "employee": employeeId,
        "from_date": DateFormat("yyyy-MM-dd").format(date),
        "to_date": DateFormat("yyyy-MM-dd").format(date),
        "reason": reason,
        "explanation": explanation,
      };

      final createResponse = await http.post(
        createUrl,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookies.join("; "),
          "X-Frappe-CSRF-Token": _getCSRFToken(cookies),
        },
        body: jsonEncode(createBody),
      ).timeout(const Duration(seconds: 15));

      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        final createDecoded = jsonDecode(createResponse.body);
        final docName = createDecoded["data"]["name"];

        final submitUrl = Uri.parse("$baseUrl/api/method/frappe.client.submit");

        final submitBody = {
          "doc": {
            "doctype": "Attendance Request",
            "name": docName,
          }
        };

        final submitResponse = await http.post(
          submitUrl,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Cookie": cookies.join("; "),
            "X-Frappe-CSRF-Token": _getCSRFToken(cookies),
          },
          body: jsonEncode(submitBody),
        ).timeout(const Duration(seconds: 15));

        if (submitResponse.statusCode == 200) {
          return;
        } else {
          final errorMsg = jsonDecode(submitResponse.body)["message"] ?? "Submission failed";
          throw Exception("Failed to submit: $errorMsg");
        }
      } else {
        final errorMsg = jsonDecode(createResponse.body)["message"] ?? "Creation failed";
        throw Exception("Failed to create: $errorMsg");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on HttpException {
      throw Exception("Server error");
    } on FormatException {
      throw Exception("Invalid server response");
    } catch (e) {
      throw Exception("Failed to submit attendance request");
    }
  }

  Future<List<Map<String, dynamic>>> getMyAttendanceRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");
      final employeeId = prefs.getString("employeeId");

      if (cookies == null || cookies.isEmpty) {
        throw Exception("Please login first");
      }

      if (employeeId == null || employeeId.isEmpty) {
        throw Exception("Employee ID not found");
      }

      final url = Uri.parse(
        "$baseUrl/api/resource/Attendance%20Request?"
        "fields=[\"name\",\"employee\",\"employee_name\",\"from_date\",\"to_date\",\"reason\",\"explanation\",\"docstatus\",\"creation\",\"modified\",\"owner\"]"
        "&filters=[[\"employee\",\"=\",\"$employeeId\"]]"
        "&order_by=creation%20desc"
        "&limit=100"
      );

      final response = await http.get(
        url,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        if (decoded.containsKey("data")) {
          final data = decoded["data"] as List;
          List<Map<String, dynamic>> requests = [];
          
          for (var item in data) {
            requests.add(_createRequestData(item));
          }
          
          return requests;
        }
        return [];
      }
      
      if (response.statusCode == 403 || response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      }
      
      throw Exception("Failed to load attendance requests");
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _createRequestData(Map<String, dynamic> item) {
    final displayStatus = _getDisplayStatus(item["docstatus"]);
    final statusColor = _getStatusColor(item["docstatus"]);
    
    return {
      "type": "attendance",
      "data": item,
      "id": item["name"] ?? "",
      "title": "Attendance: ${item["reason"] ?? "Request"}",
      "subtitle": item["explanation"] ?? "",
      "date": item["from_date"] ?? item["creation"] ?? "",
      "status": displayStatus,
      "color": statusColor,
      "icon": Icons.calendar_today,
      "created_date": item["creation"] ?? "",
      "modified_date": item["modified"] ?? "",
      "reason": item["reason"] ?? "",
      "explanation": item["explanation"] ?? "",
      "from_date": item["from_date"] ?? "",
      "to_date": item["to_date"] ?? "",
      "docstatus": item["docstatus"] ?? 0,
      "displayStatus": displayStatus,
      "statusColor": statusColor,
      "employee": item["employee"] ?? "",
      "employee_name": item["employee_name"] ?? "",
      "owner": item["owner"] ?? "",
    };
  }

  Future<Map<String, dynamic>> getRequestDetails(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");

      if (cookies == null || cookies.isEmpty) {
        throw Exception("Please login first");
      }

      final requestUrl = Uri.parse("$baseUrl/api/resource/Attendance%20Request/$requestId");

      final requestResponse = await http.get(
        requestUrl,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      if (requestResponse.statusCode == 200) {
        final requestData = jsonDecode(requestResponse.body)["data"];
        
        List<Map<String, dynamic>> comments = [];
        
        try {
          final commentsUrl = Uri.parse(
            "$baseUrl/api/resource/Comment?"
            "fields=[\"content\",\"comment_by\",\"creation\",\"comment_type\"]"
            "&filters=[[\"reference_doctype\",\"=\",\"Attendance%20Request\"],[\"reference_name\",\"=\",\"$requestId\"]]"
            "&order_by=creation%20desc"
          );

          final commentsResponse = await http.get(
            commentsUrl,
            headers: {
              "Cookie": cookies.join("; "),
              "Accept": "application/json",
            },
          );

          if (commentsResponse.statusCode == 200) {
            final commentsData = jsonDecode(commentsResponse.body);
            if (commentsData.containsKey("data")) {
              final rawComments = commentsData["data"] as List;
              for (var comment in rawComments) {
                comments.add({
                  "content": comment["content"] ?? "",
                  "comment_by": comment["comment_by"] ?? "System",
                  "creation": comment["creation"] ?? "",
                  "comment_type": comment["comment_type"] ?? "Comment",
                });
              }
            }
          }
        } catch (_) {}

        final displayStatus = _getDisplayStatus(requestData["docstatus"]);
        final statusColor = _getStatusColor(requestData["docstatus"]);

        return {
          "request": requestData,
          "comments": comments,
          "status": displayStatus,
          "statusColor": statusColor,
        };
      }
      
      if (requestResponse.statusCode == 404) {
        throw Exception("Request not found");
      }
      
      throw Exception("Failed to load request details");
    } catch (e) {
      rethrow;
    }
  }

  String _getDisplayStatus(dynamic docstatus) {
    int docStatusInt = 0;
    
    if (docstatus is int) {
      docStatusInt = docstatus;
    } else if (docstatus is String) {
      docStatusInt = int.tryParse(docstatus) ?? 0;
    }
    
    switch (docStatusInt) {
      case 0:
        return "Draft";
      case 1:
        return "Submitted";
      case 2:
        return "Cancelled";
      default:
        return "Pending";
    }
  }

  Color _getStatusColor(dynamic docstatus) {
    final displayStatus = _getDisplayStatus(docstatus);
    
    switch (displayStatus.toLowerCase()) {
      case "submitted":
        return Colors.blue;
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "cancelled":
        return Colors.grey;
      case "draft":
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  String _getCSRFToken(List<String> cookies) {
    for (var cookie in cookies) {
      if (cookie.contains("csrf_token")) {
        final parts = cookie.split(';').first.split('=');
        if (parts.length > 1) return parts[1];
      }
    }
    return "";
  }

  Future<bool> testConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");

      if (cookies == null || cookies.isEmpty) {
        return false;
      }

      final url = Uri.parse("$baseUrl/api/method/frappe.auth.get_logged_user");
      
      final response = await http.get(
        url,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getRequestById(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");

      if (cookies == null || cookies.isEmpty) {
        throw Exception("Please login first");
      }

      final url = Uri.parse("$baseUrl/api/resource/Attendance%20Request/$requestId");

      final response = await http.get(
        url,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["data"];
        return _createRequestData(data);
      } else {
        throw Exception("Request not found");
      }
    } catch (e) {
      rethrow;
    }
  }
}