import 'dart:convert';
import 'package:intl/intl.dart';
import 'auth_service.dart';

class AttendanceService {
  static const String baseUrl =
      "https://ppecon.erpnext.com/api/resource/Employee%20Checkin";

  Future<List<dynamic>> fetchLogs({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final df = DateFormat("yyyy-MM-dd");

    final formattedStart = "${df.format(start)} 00:00:00";
    final formattedEnd = "${df.format(end)} 23:59:59";

    final url =
        "$baseUrl?fields=[\"name\",\"employee\",\"log_type\",\"time\"]"
        "&filters=[[\"employee\",\"=\",\"$employeeId\"],"
        "[\"time\",\">=\",\"$formattedStart\"],"
        "[\"time\",\"<=\",\"$formattedEnd\"]]"
        "&order_by=time%20asc"
        "&limit_page_length=1000";
    try {
      final response = await AuthService.safeRequest(() {
        return AuthService.client.get(
          Uri.parse(url),
          headers: AuthService().buildHeaders(isJson: true),
        );
      });

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to fetch attendance: ${response.statusCode}");
      }

      final jsonData = jsonDecode(response.body);

      if (jsonData["data"] == null) {
        return [];
      }

      return List<dynamic>.from(jsonData["data"]);
    } catch (e) {
      throw Exception("Attendance fetch error: $e");
    }
  }

  Future<Map<String, DateTime?>> getTodayAttendance({
    required String employeeId,
  }) async {
    try {
      final now = DateTime.now();

      final logs = await fetchLogs(
        employeeId: employeeId,
        start: now,
        end: now,
      );

      DateTime? punchIn;
      DateTime? punchOut;

      for (final log in logs) {
        final type = log["log_type"];
        final time = DateTime.parse(log["time"]);

        if (type == "IN" && punchIn == null) {
          punchIn = time;
        }

        if (type == "OUT") {
          punchOut = time;
        }
      }

      return {
        "punchIn": punchIn,
        "punchOut": punchOut,
      };
    } catch (e) {
      throw Exception("Today attendance fetch failed: $e");
    }
  }
}