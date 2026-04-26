import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _baseUrl = "https://ppecon.erpnext.com";

  static Future<Map<String, dynamic>> getCompleteProfile(String userEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookies = prefs.getStringList("cookies");

      if (cookies == null || cookies.isEmpty) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
          'data': null,
        };
      }

      final userData = await _fetchUserData(userEmail, cookies);
      
      if (!userData['success']) {
        return userData;
      }

      Map<String, dynamic> combinedData = Map.from(userData['data']);

      final employeeData = await _fetchEmployeeData(userEmail, cookies);
      
      if (employeeData['success']) {
        combinedData.addAll(employeeData['data']);
        combinedData['has_employee_record'] = true;
      } else {
        combinedData['has_employee_record'] = false;
      }

      combinedData = _constructImageUrl(combinedData);

      return {
        'success': true,
        'message': 'Profile fetched successfully',
        'data': combinedData,
      };

    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> _fetchUserData(String userEmail, List<String> cookies) async {
    try {
      final url = Uri.parse("$_baseUrl/api/resource/User/$userEmail");
      
      final response = await http.get(
        url,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        if (decoded["data"] != null) {
          return {
            'success': true,
            'data': decoded["data"],
          };
        }
      }
      
      return {
        'success': false,
        'message': 'User not found',
        'data': null,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  static Future<Map<String, dynamic>> _fetchEmployeeData(String userEmail, List<String> cookies) async {
    try {
      var url = Uri.parse("$_baseUrl/api/resource/Employee?filters=[[\"user_id\",\"=\",\"$userEmail\"]]&fields=[\"*\"]");
      
      var response = await http.get(
        url,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        
        if (decoded["data"] != null && decoded["data"].isNotEmpty) {
          return {
            'success': true,
            'data': decoded["data"][0],
          };
        }
      }

      url = Uri.parse("$_baseUrl/api/resource/Employee?filters=[[\"company_email\",\"=\",\"$userEmail\"]]&fields=[\"*\"]");
      
      response = await http.get(
        url,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        
        if (decoded["data"] != null && decoded["data"].isNotEmpty) {
          return {
            'success': true,
            'data': decoded["data"][0],
          };
        }
      }

      url = Uri.parse("$_baseUrl/api/resource/Employee?filters=[[\"personal_email\",\"=\",\"$userEmail\"]]&fields=[\"*\"]");
      
      response = await http.get(
        url,
        headers: {
          "Cookie": cookies.join("; "),
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        
        if (decoded["data"] != null && decoded["data"].isNotEmpty) {
          return {
            'success': true,
            'data': decoded["data"][0],
          };
        }
      }

      return {
        'success': false,
        'message': 'No employee record found',
        'data': null,
      };

    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  static Map<String, dynamic> _constructImageUrl(Map<String, dynamic> data) {
    if (data['image'] != null && data['image'].toString().isNotEmpty) {
      String imagePath = data['image'].toString();
      if (!imagePath.startsWith('http')) {
        data['full_image_url'] = "$_baseUrl$imagePath";
      } else {
        data['full_image_url'] = imagePath;
      }
    }
    else if (data['user_image'] != null && data['user_image'].toString().isNotEmpty) {
      String imagePath = data['user_image'].toString();
      if (!imagePath.startsWith('http')) {
        data['full_image_url'] = "$_baseUrl$imagePath";
      } else {
        data['full_image_url'] = imagePath;
      }
    }
    else {
      data['full_image_url'] = null;
    }
    
    return data;
  }

  static String getDisplayName(Map<String, dynamic> data) {
    if (data['employee_name'] != null && data['employee_name'].toString().isNotEmpty) {
      return data['employee_name'].toString();
    }
    if (data['full_name'] != null && data['full_name'].toString().isNotEmpty) {
      return data['full_name'].toString();
    }
    String name = '';
    if (data['first_name'] != null) {
      name += data['first_name'].toString();
    }
    if (data['last_name'] != null && data['last_name'].toString().isNotEmpty) {
      name += ' ${data['last_name']}';
    }
    return name.isNotEmpty ? name : 'N/A';
  }

  static String getEmployeeId(Map<String, dynamic> data) {
    if (data['name'] != null && data['name'].toString().startsWith('EMP-')) {
      return data['name'].toString();
    }
    if (data['employee'] != null) {
      return data['employee'].toString();
    }
    if (data['employee_number'] != null) {
      return data['employee_number'].toString();
    }
    return 'N/A';
  }

  static String getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return '🟢 Active';
      case 'inactive':
        return '🔴 Inactive';
      case 'suspended':
        return '🟠 Suspended';
      case 'left':
        return '⚫ Left';
      default:
        return '⚪ Unknown';
    }
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  static int getAge(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return 0;
    try {
      final dob = DateTime.parse(dobStr);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'suspended':
        return Colors.orange;
      case 'left':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Icons.check_circle_rounded;
      case 'inactive':
        return Icons.cancel_rounded;
      case 'suspended':
        return Icons.pause_circle_rounded;
      case 'left':
        return Icons.exit_to_app_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  static String getExperience(String? joiningDate) {
    if (joiningDate == null || joiningDate.isEmpty) return 'N/A';
    try {
      final join = DateTime.parse(joiningDate);
      final today = DateTime.now();
      
      int years = today.year - join.year;
      int months = today.month - join.month;
      
      if (months < 0) {
        years--;
        months += 12;
      }
      
      if (years > 0) {
        return '$years years ${months > 0 ? '$months months' : ''}';
      } else {
        return '$months months';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  // ✅ NEW: Get Contract End Date from employee data
  static String getContractEndDate(Map<String, dynamic> data) {
    // Try common field names used in ERPNext
    if (data['contract_end_date'] != null && data['contract_end_date'].toString().isNotEmpty) {
      return formatDate(data['contract_end_date'].toString());
    }
    if (data['custom_contract_end_date'] != null && data['custom_contract_end_date'].toString().isNotEmpty) {
      return formatDate(data['custom_contract_end_date'].toString());
    }
    if (data['employment_end_date'] != null && data['employment_end_date'].toString().isNotEmpty) {
      return formatDate(data['employment_end_date'].toString());
    }
    return 'N/A';
  }
}