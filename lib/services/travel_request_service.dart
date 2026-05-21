import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TravelRequestService {
  static const String _baseUrl = "https://ppecon.erpnext.com";

  static const String _customTravelApi =
      "$_baseUrl/api/method/ppecon_erp.travel_request.travel_request.submit_travel_request_from_mobile";

  // =====================================================
  // GET TRAVEL FUNDING TYPES FROM ERP
  // =====================================================
  static Future<List<Map<String, dynamic>>> getFundingTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");

      if (cookies == null || cookies.isEmpty) {
        return _getDefaultFundingTypes();
      }

      const url =
          "$_baseUrl/api/resource/Travel Funding Type?fields=[\"name\"]&limit=100";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Cookie": cookies.join("; "), "Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"] ?? [];

        if (data.isNotEmpty) {
          return data.map((item) {
            final name = item["name"].toString();
            return {
              'value': name,
              'label': name,
              'icon': _getIconForFunding(name),
              'color': _getColorForFunding(name),
            };
          }).toList();
        }
      }

      return _getDefaultFundingTypes();
    } catch (e) {
      return _getDefaultFundingTypes();
    }
  }

  static Future<List<Map<String, dynamic>>> getPurposeTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");

      if (cookies == null || cookies.isEmpty) {
        return _getDefaultPurposeTypes();
      }

      const url =
          "$_baseUrl/api/resource/Purpose of Travel?fields=[\"name\"]&limit=100";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Cookie": cookies.join("; "), "Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"] ?? [];

        if (data.isNotEmpty) {
          return data.map((item) {
            final name = item["name"].toString();
            return {
              'value': name,
              'label': name,
              'icon': _getIconForPurpose(name),
              'color': _getColorForPurpose(name),
            };
          }).toList();
        }
      }

      return _getDefaultPurposeTypes();
    } catch (e) {
      return _getDefaultPurposeTypes();
    }
  }

  // =====================================================
  // SUBMIT ONE-WAY TRAVEL REQUEST
  // =====================================================
  static Future<String> submitTravelRequest({
    required String travelType,
    required String travelFunding,
    required String purpose,
    required String from,
    required String to,
    required String mode,
    required String departureDate,
    required String description,
    bool isTwoWay = false, // Added for clarity but not used in one-way
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");
      final employeeId = prefs.getString("employeeId");

      if (cookies == null || cookies.isEmpty || employeeId == null) {
        throw "Session expired. Please login again.";
      }

      final response = await http.post(
        Uri.parse(_customTravelApi),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookies.join("; "),
        },
        body: jsonEncode({
          "employee": employeeId,
          "personal_id_type": "Iqama",
          "personal_id_number": "1234567890",
          "travel_type": travelType,
          "travel_funding": travelFunding,
          "purpose_of_travel": purpose,
          "description": description,
          "itinerary": [
            {
              "travel_from": from,
              "travel_to": to,
              "mode_of_travel": mode,
              "departure_date": departureDate,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        return "Travel Request Submitted Successfully";
      }

      throw "Submit Failed: ${response.body}";
    } catch (e) {
      throw e.toString();
    }
  }

  // =====================================================
  // SUBMIT TWO-WAY TRAVEL REQUEST
  // =====================================================
  static Future<String> submitTwoWayTravelRequest({
    required String travelType,
    required String travelFunding,
    required String purpose,
    required String onwardFrom,
    required String onwardTo,
    required String onwardMode,
    required String onwardDate,
    required String returnFrom,
    required String returnTo,
    required String returnMode,
    required String returnDate,
    required String description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");
      final employeeId = prefs.getString("employeeId");

      if (cookies == null || cookies.isEmpty || employeeId == null) {
        throw "Session expired. Please login again.";
      }

      // Validate that return location matches onward destination
      if (onwardTo.toLowerCase() != returnFrom.toLowerCase()) {
        throw "Return journey must start from your destination";
      }

      if (onwardFrom.toLowerCase() != returnTo.toLowerCase()) {
        throw "Return journey must end at your origin";
      }

      final response = await http.post(
        Uri.parse(_customTravelApi),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookies.join("; "),
        },
        body: jsonEncode({
          "employee": employeeId,
          "personal_id_type": "Iqama",
          "personal_id_number": "1234567890",
          "travel_type": travelType,
          "travel_funding": travelFunding,
          "purpose_of_travel": purpose,
          "description": description,
          "itinerary": [
            // Onward journey
            {
              "travel_from": onwardFrom,
              "travel_to": onwardTo,
              "mode_of_travel": onwardMode,
              "departure_date": onwardDate,
            },
            // Return journey
            {
              "travel_from": returnFrom,
              "travel_to": returnTo,
              "mode_of_travel": returnMode,
              "departure_date": returnDate,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        return "Two-Way Travel Request Submitted Successfully";
      }

      // ✅ BAAD MEIN
      throw "Failed to submit request. Please try again."; // ✅ clean
    } catch (e) {
      throw e.toString();
    }
  }

  // =====================================================
  // GET MY TRAVEL REQUESTS
  // =====================================================
  static Future<List<Map<String, dynamic>>> getMyTravelRequests(
    String employeeId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");

      if (cookies == null || cookies.isEmpty) {
        throw "Please login again";
      }

      // First get list of travel request names
      final listUrl =
          "$_baseUrl/api/resource/Travel%20Request"
          "?fields=[\"name\"]"
          "&filters=[[\"employee\",\"=\",\"$employeeId\"]]"
          "&order_by=creation desc"
          "&limit=100";

      final listResponse = await http.get(
        Uri.parse(listUrl),
        headers: {"Cookie": cookies.join("; "), "Accept": "application/json"},
      );

      if (listResponse.statusCode != 200) {
        // ✅ BAAD MEIN
        throw "Failed to load travel requests. Please try again."; // ✅ clean
      }

      final listDecoded = jsonDecode(listResponse.body);
      final List listData = listDecoded["data"] ?? [];

      List<Map<String, dynamic>> travelRequests = [];

      // Fetch each document individually to get FULL data including itinerary child table
      for (var item in listData) {
        final requestName = item["name"];

        final detailUrl =
            "$_baseUrl/api/resource/Travel%20Request/$requestName";

        final detailResponse = await http.get(
          Uri.parse(detailUrl),
          headers: {"Cookie": cookies.join("; "), "Accept": "application/json"},
        );

        if (detailResponse.statusCode == 200) {
          final detailDecoded = jsonDecode(detailResponse.body);
          final Map<String, dynamic> fullData = detailDecoded["data"] ?? {};

          final status = _getDisplayStatus(
            fullData["workflow_state"],
            fullData["docstatus"],
          );

          // Parse itinerary from the full data
          List<Map<String, dynamic>> itineraryList = [];

          if (fullData["itinerary"] != null) {
            final itinerary = fullData["itinerary"];

            if (itinerary is List) {
              for (var leg in itinerary) {
                if (leg is Map<String, dynamic>) {
                  itineraryList.add(leg);
                }
              }
            }
          }

          travelRequests.add({
            "type": "travel",
            "data": fullData,
            "itinerary": itineraryList,
            "itinerary_list": itineraryList,
            "id": fullData["name"] ?? "",
            "title": fullData["travel_type"] != null
                ? "Travel: ${fullData["travel_type"]}"
                : "",
            "subtitle": fullData["purpose_of_travel"] ?? "",
            "date": fullData["creation"] ?? "",
            "status": status,
            "color": _getStatusColor(
              fullData["workflow_state"],
              fullData["docstatus"],
            ),
            "icon": Icons.flight_takeoff,
            "purpose_of_travel": fullData["purpose_of_travel"] ?? "",
            "travel_type": fullData["travel_type"] ?? "",
            "travel_funding": fullData["travel_funding"] ?? "",
            "created_on": fullData["creation"] ?? "",
            "workflow_state": fullData["workflow_state"] ?? "",
            "docstatus": fullData["docstatus"] ?? 0,
            "employee_name": fullData["employee_name"] ?? "",
            "employee": fullData["employee"] ?? "",
            "name": fullData["name"] ?? "",
            "posting_date": fullData["posting_date"] ?? "",
            "creation": fullData["creation"] ?? "",
          });
        }
      }

      return travelRequests;
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================
  static List<Map<String, dynamic>> _getDefaultFundingTypes() {
    return [
      {
        'value': 'Fully Sponsored',
        'label': 'Fully Sponsored',
        'icon': Icons.account_balance_wallet,
        'color': Colors.purple,
      },
      {
        'value': 'Self Sponsored',
        'label': 'Self Sponsored',
        'icon': Icons.person,
        'color': Colors.orange,
      },
      {
        'value': 'Partially Sponsored',
        'label': 'Partially Sponsored',
        'icon': Icons.account_balance,
        'color': Colors.teal,
      },
    ];
  }

  static List<Map<String, dynamic>> _getDefaultPurposeTypes() {
    return [
      {
        'value': 'Business',
        'label': 'Business Meeting',
        'icon': Icons.business,
        'color': Colors.blue,
      },
      {
        'value': 'Conference',
        'label': 'Conference',
        'icon': Icons.groups,
        'color': Colors.purple,
      },
      {
        'value': 'Training',
        'label': 'Training',
        'icon': Icons.school,
        'color': Colors.green,
      },
      {
        'value': 'Project',
        'label': 'Project Work',
        'icon': Icons.work,
        'color': Colors.orange,
      },
      {
        'value': 'Personal',
        'label': 'Personal',
        'icon': Icons.person,
        'color': Colors.red,
      },
    ];
  }

  static IconData _getIconForFunding(String fundingName) {
    final name = fundingName.toLowerCase();
    if (name.contains('fully')) return Icons.account_balance_wallet;
    if (name.contains('self')) return Icons.person;
    if (name.contains('partial')) return Icons.account_balance;
    return Icons.attach_money;
  }

  static Color _getColorForFunding(String fundingName) {
    final name = fundingName.toLowerCase();
    if (name.contains('fully')) return Colors.purple;
    if (name.contains('self')) return Colors.orange;
    if (name.contains('partial')) return Colors.teal;
    return Colors.blue;
  }

  static IconData _getIconForPurpose(String purposeName) {
    final name = purposeName.toLowerCase();
    if (name.contains('business')) return Icons.business;
    if (name.contains('conference')) return Icons.groups;
    if (name.contains('training') || name.contains('school'))
      return Icons.school;
    if (name.contains('project')) return Icons.work;
    if (name.contains('personal')) return Icons.person;
    if (name.contains('meeting')) return Icons.people;
    return Icons.flight_takeoff;
  }

  static Color _getColorForPurpose(String purposeName) {
    final name = purposeName.toLowerCase();
    if (name.contains('business')) return Colors.blue;
    if (name.contains('conference')) return Colors.purple;
    if (name.contains('training')) return Colors.green;
    if (name.contains('project')) return Colors.orange;
    if (name.contains('personal')) return Colors.red;
    if (name.contains('meeting')) return Colors.teal;
    return Colors.indigo;
  }

  static String _getDisplayStatus(String? workflowState, int? docstatus) {
    if (workflowState == "Direct Manager Approval") {
      return "Pending (Manager)";
    }
    if (workflowState == "HR Approval") {
      return "Pending (HR)";
    }
    if (workflowState == "Approved") {
      return "Approved";
    }
    if (workflowState == "Rejected") {
      return "Rejected";
    }
    if (docstatus == 0) return "Draft";
    if (docstatus == 1) return "Submitted";
    if (docstatus == 2) return "Cancelled";
    return "Pending";
  }

  static Color _getStatusColor(String? workflowState, int? docstatus) {
    final status = _getDisplayStatus(workflowState, docstatus).toLowerCase();
    switch (status) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
