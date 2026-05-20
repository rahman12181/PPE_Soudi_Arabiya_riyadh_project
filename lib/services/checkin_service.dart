import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:management_app/services/connectivity_service.dart';
import 'package:management_app/services/geofence_service.dart';
import 'package:intl/intl.dart';

class CheckinService {
  final ConnectivityService _connectivityService = ConnectivityService();
  final GeofenceService _geofenceService = GeofenceService();

  Future<Map<String, dynamic>> checkIn({
    required String employeeId,
    required String logType,
    required Position currentPosition,
  }) async {
    try {
      bool inside =
          await _geofenceService.isWithinAnyGeofence(currentPosition);

      if (!inside) {
        return {
          'success': false,
          'message': 'You are not inside any geofence office location.',
          'offlineMode': false,
          'blocked': true,
        };
      }

      bool hasInternet = await _connectivityService.hasInternetConnection();
      if (!hasInternet) {
        return {
          'success': false,
          'offlineMode': true,
          'message': 'No internet connection. Punch saved locally.',
        };
      }

      // ✅ FIX: Use device local time directly.
      // DateTime.now() on a Saudi device already returns Saudi local time (UTC+3).
      // ERPNext expects local time — so this is correct as-is.
      // Previously there was a comment about "+3 hardcoded" — that is WRONG
      // and unnecessary. The device clock is the source of truth.
      final localNow = DateTime.now();
      final formattedTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(localNow);

      Map<String, dynamic> requestBody = {
        "employee": employeeId,
        "log_type": logType,
        "time": formattedTime,
        "latitude": currentPosition.latitude,
        "longitude": currentPosition.longitude,
      };

      print("========== SENDING PUNCH REQUEST ==========");
      print("Employee: $employeeId");
      print("Log Type: $logType");
      print("Time (local): $formattedTime");
      print(
          "Location: ${currentPosition.latitude}, ${currentPosition.longitude}");
      print("===========================================");

      final apiResponse = await AuthService.client.post(
        Uri.parse(
            "https://ppecon.erpnext.com/api/resource/Employee%20Checkin"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": AuthService.cookies.join("; "),
        },
        body: jsonEncode(requestBody),
      );

      print("========== PUNCH API RESPONSE ==========");
      print("Status Code: ${apiResponse.statusCode}");
      print("Response Body: ${apiResponse.body}");
      print("========================================");

      Map<String, dynamic> responseData = {};
      String message = '';
      bool success = apiResponse.statusCode == 200 ||
          apiResponse.statusCode == 201;

      try {
        responseData = jsonDecode(apiResponse.body);
        if (responseData['_server_messages'] != null) {
          try {
            var messages = jsonDecode(responseData['_server_messages']);
            if (messages.isNotEmpty) {
              var msgObj = jsonDecode(messages[0]);
              message = msgObj['message'] ?? '';
              message =
                  message.replaceAll('✅', '').replaceAll('❌', '').trim();
            }
          } catch (_) {}
        }
        if (message.isEmpty) {
          message = responseData['exception'] ??
              responseData['message'] ??
              (success ? 'Punch successful' : 'Punch failed');
        }
      } catch (e) {
        message = success ? 'Punch successful' : 'Punch failed';
      }

      print("========== FINAL RESULT ==========");
      print("Success: $success");
      print("Message: $message");
      print("==================================");

      return {
        'success': success,
        'message': message,
        'data': responseData['data'],
        'statusCode': apiResponse.statusCode,
        'offlineMode': false,
      };
    } catch (e) {
      print("========== ERROR ==========");
      print("Error: ${e.toString()}");
      print("============================");
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'offlineMode': false,
      };
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required String employeeId,
    required Position currentPosition,
  }) async {
    return await checkIn(
      employeeId: employeeId,
      logType: "OUT",
      currentPosition: currentPosition,
    );
  }
}