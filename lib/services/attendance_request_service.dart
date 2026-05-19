// attendance_request_service.dart
// FIXED: Only creates DRAFT (docstatus=0), NO auto-submission

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceRequestService {
  static const String baseUrl = "https://ppecon.erpnext.com";

  Future<Map<String, dynamic>> submitRequest({
    required DateTime date,
    required String reason,
    required String explanation,
    required String shift,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getString("employeeId");
    final cookies = prefs.getStringList("cookies");

    if (employeeId == null || employeeId.isEmpty) {
      return {'success': false, 'message': "Session expired. Please login again."};
    }
    if (cookies == null || cookies.isEmpty) {
      return {'success': false, 'message': "Authentication failed. Please login again."};
    }

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Cookie": cookies.join("; "),
      "X-Frappe-CSRF-Token": _getCSRFToken(cookies),
    };

    try {
      // ONLY CREATE DOCUMENT (DRAFT - docstatus will be 0 automatically)
      final createUrl = Uri.parse("$baseUrl/api/resource/Attendance%20Request");
      final createBody = {
        "employee": employeeId,
        "from_date": DateFormat("yyyy-MM-dd").format(date),
        "to_date": DateFormat("yyyy-MM-dd").format(date),
        "reason": reason,
        "explanation": explanation,
        "shift": shift,
      };

      final createResponse = await http
          .post(createUrl, headers: headers, body: jsonEncode(createBody))
          .timeout(const Duration(seconds: 15));

      if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
        if (createResponse.statusCode == 401 || createResponse.statusCode == 403) {
          return {'success': false, 'message': "Session expired. Please login again."};
        }
        if (createResponse.statusCode == 409) {
          return {'success': false, 'message': "A request for this date already exists."};
        }
        final decoded = _safeDecode(createResponse.body);
        return {
          'success': false,
          'message': _cleanErrorMessage(
              decoded["message"]?.toString() ??
              decoded["exception"]?.toString() ??
              "Failed to create request. Please try again."),
        };
      }

      final createDecoded = jsonDecode(createResponse.body);
      final docName = createDecoded["data"]?["name"];
      
      if (docName == null || docName.toString().isEmpty) {
        return {'success': false, 'message': "Invalid response from server. Please try again."};
      }

      // ✅ SUCCESS: Document created with docstatus = 0 (Draft)
      // ✅ NO frappe.client.submit call here
      // ✅ Manager will approve from ERPNext portal
      
      return {
        'success': true,
        'message': 'Attendance request submitted successfully! It will be processed by your manager.',
        'data': {
          'name': docName,
          'docstatus': 0,  // Draft status
        },
      };

    } on SocketException {
      return {'success': false, 'message': "No internet connection. Please check your network."};
    } on TimeoutException {
      return {'success': false, 'message': "Request timed out. Please try again."};
    } on HttpException {
      return {'success': false, 'message': "Server error. Please try again later."};
    } on FormatException {
      return {'success': false, 'message': "Invalid response from server. Please try again."};
    } catch (e) {
      return {'success': false, 'message': "Something went wrong. Please try again."};
    }
  }

  // GET my requests - Updated to show correct status
  Future<List<Map<String, dynamic>>> getMyAttendanceRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");
      final employeeId = prefs.getString("employeeId");

      if (cookies == null || cookies.isEmpty) throw Exception("Please login first.");
      if (employeeId == null || employeeId.isEmpty) throw Exception("Employee ID not found.");

      final url = Uri.parse(
        "$baseUrl/api/resource/Attendance%20Request?"
        "fields=[\"name\",\"employee\",\"employee_name\",\"from_date\",\"to_date\",\"reason\",\"explanation\",\"shift\",\"docstatus\",\"workflow_state\",\"creation\",\"modified\",\"owner\"]"
        "&filters=[[\"employee\",\"=\",\"$employeeId\"]]"
        "&order_by=creation%20desc"
        "&limit=100",
      );

      final response = await http.get(
        url,
        headers: {"Cookie": cookies.join("; "), "Accept": "application/json"},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded.containsKey("data")) {
          final data = decoded["data"] as List;
          return data.map<Map<String, dynamic>>((item) => _createRequestData(item)).toList();
        }
        return [];
      }
      if (response.statusCode == 403 || response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      }
      throw Exception("Failed to load attendance requests.");
    } on SocketException {
      throw Exception("No internet connection. Please check your network.");
    } on TimeoutException {
      throw Exception("Request timed out. Please try again.");
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _createRequestData(Map<String, dynamic> item) {
    // Get proper status based on workflow_state and docstatus
    final displayStatus = _getDisplayStatus(
      item["workflow_state"]?.toString(), 
      item["docstatus"]
    );
    final statusColor = _getStatusColor(displayStatus);
    
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
      "shift": item["shift"] ?? "",
      "from_date": item["from_date"] ?? "",
      "to_date": item["to_date"] ?? "",
      "docstatus": item["docstatus"] ?? 0,
      "workflow_state": item["workflow_state"] ?? "",
      "displayStatus": displayStatus,
      "statusColor": statusColor,
      "employee": item["employee"] ?? "",
      "employee_name": item["employee_name"] ?? "",
      "owner": item["owner"] ?? "",
    };
  }

  // Helper to determine correct status
  String _getDisplayStatus(String? workflowState, dynamic docstatus) {
    int ds = 0;
    if (docstatus is int) ds = docstatus;
    else if (docstatus is String) ds = int.tryParse(docstatus) ?? 0;
    
    // Check workflow state first
    if (workflowState != null && workflowState.isNotEmpty) {
      if (workflowState.toLowerCase().contains("pending") || 
          workflowState.toLowerCase().contains("draft")) {
        return "Pending";
      }
      if (workflowState.toLowerCase().contains("approved")) {
        return "Approved";
      }
      if (workflowState.toLowerCase().contains("rejected")) {
        return "Rejected";
      }
    }
    
    // Fallback to docstatus
    switch (ds) {
      case 0: return "Pending";
      case 1: return "Approved";
      case 2: return "Rejected";
      default: return "Pending";
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":  return Colors.green;
      case "rejected":  return Colors.red;
      case "pending":   return Colors.orange;
      case "draft":     return Colors.grey;
      default:          return Colors.orange;
    }
  }

  // Rest of the methods remain same...
  
  Future<Map<String, dynamic>> getRequestDetails(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");
      if (cookies == null || cookies.isEmpty) throw Exception("Please login first.");

      final requestUrl = Uri.parse("$baseUrl/api/resource/Attendance%20Request/$requestId");
      final requestResponse = await http.get(
        requestUrl,
        headers: {"Cookie": cookies.join("; "), "Accept": "application/json"},
      ).timeout(const Duration(seconds: 15));

      if (requestResponse.statusCode == 200) {
        final requestData = jsonDecode(requestResponse.body)["data"];
        final displayStatus = _getDisplayStatus(
          requestData["workflow_state"]?.toString(), 
          requestData["docstatus"]
        );
        
        return {
          "request": requestData,
          "status": displayStatus,
          "statusColor": _getStatusColor(displayStatus),
        };
      }
      throw Exception("Failed to load request details.");
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try { return jsonDecode(body) as Map<String, dynamic>; } catch (_) { return {}; }
  }

  String _cleanErrorMessage(String raw) {
    try {
      if (raw.startsWith('[')) {
        final list = jsonDecode(raw) as List;
        if (list.isNotEmpty) {
          final inner = jsonDecode(list.first as String) as Map;
          return inner["message"]?.toString() ?? raw;
        }
      }
    } catch (_) {}
    return raw.replaceAll('"', '').trim();
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
}