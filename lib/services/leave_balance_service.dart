import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LeaveBalanceService {
  static const String baseUrl = 'https://ppecon.erpnext.com';

  // Fetch leave balances for logged in user
  Future<Map<String, dynamic>> fetchLeaveBalances() async {
    debugPrint('🚀 Starting fetchLeaveBalances...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get employee ID
      String? employeeId = prefs.getString('employee_id') ?? 
                           prefs.getString('employee') ?? 
                           prefs.getString('emp_code') ??
                           prefs.getString('empId') ??
                           prefs.getString('userId') ??
                           prefs.getString('employeeId');
      
      debugPrint('🔍 Employee ID: $employeeId');

      // Get cookies - handle both String and List types
      final cookiesData = prefs.get('cookies');
      final sidData = prefs.get('sid');
      final cookiesListData = prefs.getStringList('cookies_list');
      
      String? cookies;
      String? sid;
      
      if (cookiesData is String) {
        cookies = cookiesData;
        debugPrint('🍪 Cookies found as String');
      } else if (cookiesData is List) {
        cookies = (cookiesData as List).join('; ');
        debugPrint('🍪 Cookies found as List, converted to String');
      } else if (cookiesListData != null && cookiesListData.isNotEmpty) {
        cookies = cookiesListData.join('; ');
        debugPrint('🍪 Cookies found in cookies_list');
      }
      
      if (sidData is String) {
        sid = sidData;
        debugPrint('🔑 SID found as String');
      } else if (sidData is List && sidData.isNotEmpty) {
        sid = sidData.first as String?;
        debugPrint('🔑 SID found as List');
      }

      // If employee ID is null, try user_data
      if (employeeId == null || employeeId.isEmpty) {
        final String? userData = prefs.getString('user_data');
        if (userData != null) {
          try {
            final Map<String, dynamic> userMap = jsonDecode(userData);
            employeeId = userMap['employee_id'] ?? userMap['employee'];
          } catch (e) {
            debugPrint('Error parsing user_data: $e');
          }
        }
      }

      if (employeeId == null || employeeId.isEmpty) {
        return {
          'success': false,
          'message': 'Employee ID not found. Please login again.',
        };
      }

      // Build cookies string
      String cookieString = '';
      if (cookies != null && cookies.isNotEmpty) {
        cookieString = cookies;
      } else if (sid != null && sid.isNotEmpty) {
        cookieString = 'sid=$sid';
      }

      if (cookieString.isEmpty) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'needsLogin': true,
        };
      }

      return await _fetchFromMainAPI(employeeId, cookieString);
      
    } catch (e) {
      debugPrint('❌ Error: $e');
      return {
        'success': false,
        'message': 'Error fetching leave data: ${e.toString()}',
      };
    }
  }

  // Fetch from API
  Future<Map<String, dynamic>> _fetchFromMainAPI(String employeeId, String cookies) async {
    try {
      final url = Uri.parse('$baseUrl/api/method/ppecon_erp.leave_application.leave_balance.get_my_leave_balance');
      
      debugPrint('🌐 API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Cookie': cookies,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('📊 API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse.containsKey('message')) {
          final message = jsonResponse['message'];
          
          // New API structure: { "message": { "annual_leave": 20.0, "sick_leave": 4.0 } }
          if (message is Map) {
            debugPrint('📦 API message: $message');
            return _processNewAPIResponse(message, employeeId);
          }
        }
        
        return {
          'success': true,
          'employeeId': employeeId,
          'leaveDetails': {},
          'totals': {'allocated': 0.0, 'taken': 0.0, 'remaining': 0.0}
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'needsLogin': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load leave data',
        };
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Process NEW API response structure:
  // { "annual_leave": 20.0, "sick_leave": 4.0 }
  // These values are the REMAINING balance directly.
  Map<String, dynamic> _processNewAPIResponse(Map<dynamic, dynamic> message, String employeeId) {
    final Map<String, Map<String, double>> leaveDetails = {};

    final double annualRemaining = _toDouble(message['annual_leave']);
    final double sickRemaining = _toDouble(message['sick_leave']);

    debugPrint('📊 Annual Leave remaining: $annualRemaining');
    debugPrint('📊 Sick Leave remaining: $sickRemaining');

    if (message.containsKey('annual_leave')) {
      leaveDetails['Annual Leave'] = {
        'allocated': annualRemaining, // API only gives balance; use as allocated too
        'taken': 0.0,
        'remaining': annualRemaining,
      };
    }

    if (message.containsKey('sick_leave')) {
      leaveDetails['Sick Leave'] = {
        'allocated': sickRemaining,
        'taken': 0.0,
        'remaining': sickRemaining,
      };
    }

    final double totalRemaining = annualRemaining + sickRemaining;

    return {
      'success': true,
      'employeeId': employeeId,
      'leaveDetails': leaveDetails,
      'totals': {
        'allocated': totalRemaining,
        'taken': 0.0,
        'remaining': totalRemaining,
      }
    };
  }

  // Helper to safely convert int or double to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Process OLD API response - SUM values for same leave type
  Map<String, dynamic> _processAPIResponse(List<dynamic> leaveData, String employeeId) {
    Map<String, Map<String, double>> leaveDetails = {};
    double totalAllocated = 0;
    double totalTaken = 0;
    double totalRemaining = 0;

    debugPrint('🔄 Processing ${leaveData.length} leave records...');

    // Group and sum by leave type
    for (var item in leaveData) {
      final leaveType = _extractStringValue(item, ['leave_type', 'leaveType', 'type']) ?? 'Unknown Leave';
      final allocated = _extractDoubleValue(item, ['allocated', 'allocated_leaves']) ?? 0.0;
      final taken = _extractDoubleValue(item, ['taken', 'taken_leaves']) ?? 0.0;
      final remaining = _extractDoubleValue(item, ['remaining', 'remaining_leaves', 'balance']) ?? 0.0;

      debugPrint('📊 Processing: $leaveType → Allocated: $allocated, Taken: $taken, Remaining: $remaining');

      // If this leave type already exists, SUM the values
      if (leaveDetails.containsKey(leaveType)) {
        final existing = leaveDetails[leaveType]!;
        leaveDetails[leaveType] = {
          'allocated': existing['allocated']! + allocated,
          'taken': existing['taken']! + taken,
          'remaining': existing['remaining']! + remaining,
        };
        debugPrint('   ➕ Adding to existing $leaveType');
      } else {
        // New leave type
        leaveDetails[leaveType] = {
          'allocated': allocated,
          'taken': taken,
          'remaining': remaining,
        };
        debugPrint('   ✅ New $leaveType added');
      }
    }

    // Calculate totals
    for (var entry in leaveDetails.entries) {
      totalAllocated += entry.value['allocated']!;
      totalTaken += entry.value['taken']!;
      totalRemaining += entry.value['remaining']!;
    }

    debugPrint('✅ Final grouped data (${leaveDetails.length} leave types):');
    leaveDetails.forEach((key, value) {
      debugPrint('   $key → Allocated: ${value['allocated']}, Taken: ${value['taken']}, Remaining: ${value['remaining']}');
    });

    return {
      'success': true,
      'employeeId': employeeId,
      'leaveDetails': leaveDetails,
      'totals': {
        'allocated': totalAllocated,
        'taken': totalTaken,
        'remaining': totalRemaining,
      }
    };
  }

  // Helper to extract string value
  String? _extractStringValue(Map<String, dynamic> map, List<String> possibleKeys) {
    for (var key in possibleKeys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key].toString();
      }
    }
    return null;
  }

  // Helper to extract double value
  double? _extractDoubleValue(Map<String, dynamic> map, List<String> possibleKeys) {
    for (var key in possibleKeys) {
      if (map.containsKey(key) && map[key] != null) {
        final value = map[key];
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          return double.tryParse(value) ?? 0.0;
        }
      }
    }
    return null;
  }

  // Get dashboard balance
  static Future<double> getDashboardLeaveBalance() async {
    try {
      final service = LeaveBalanceService();
      final result = await service.fetchLeaveBalances();
      return result['success'] == true ? (result['totals']['remaining'] ?? 0.0) : 0.0;
    } catch (e) {
      debugPrint('Error: $e');
      return 0.0;
    }
  }
}