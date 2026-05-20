import 'dart:convert';
import 'package:intl/intl.dart';
import 'auth_service.dart';

class AttendanceService {
  static const String baseUrl =
      "https://ppecon.erpnext.com/api/resource/Employee%20Checkin";

  // ✅ ERP stores and returns times in Asia/Riyadh timezone (UTC+3).
  // We NEVER convert to device local time — we always display ERP time as-is.
  // This ensures the same time shows on any device regardless of where the user is.
  static final DateFormat _erpFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  /// Parse ERP time string as a "fixed" datetime with no timezone conversion.
  /// We use UTC flag=false so Dart treats it as a plain local-style datetime.
  /// We never call .toLocal() or .toUtc() on these values.
  static DateTime _parseErpTime(String timeStr) {
    // parse with isUtc=false → stored as-is, no offset applied
    return _erpFormat.parse(timeStr, false);
  }

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
        throw Exception("Failed to fetch attendance: ${response.statusCode}");
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

        // ✅ Parse ERP time as-is — no timezone conversion
        // ERP returns "2026-05-20 08:29:36" (Riyadh time) → display exactly that
        final time = _parseErpTime(log["time"]);

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