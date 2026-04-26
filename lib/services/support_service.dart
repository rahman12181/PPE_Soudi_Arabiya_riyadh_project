import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SupportService {
  // Apni IP daalo (real phone ke liye)
  static const String baseUrl = 'http://16.16.187.245:8080';
  
  Future<Map<String, dynamic>> submitQuery({
    required String queryType,
    String? description,
    File? screenshot,
  }) async {
    try {
      // Get or create user ID
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      if (userId == null) {
        userId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('userId', userId);
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/support/submit'),
      );
      
      request.fields['userId'] = userId;
      request.fields['queryType'] = queryType;
      request.fields['description'] = description ?? '';
      
      if (screenshot != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'screenshot',
          screenshot.path,
        );
        request.files.add(multipartFile);
      }
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonResponse['message'],
          'queryId': jsonResponse['queryId']
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Submission failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}'
      };
    }
  }
  
  Future<List<dynamic>> getMyQueries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/support/my-queries?userId=$userId'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}