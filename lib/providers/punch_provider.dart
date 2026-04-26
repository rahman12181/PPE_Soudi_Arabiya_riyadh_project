import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../model/attendance_model.dart';
import '../services/attendance_service.dart';

class PunchProvider extends ChangeNotifier {
  DateTime? _punchInTime;
  DateTime? _punchOutTime;
  bool _isLoaded = false;
  String? _employeeId;

  DateTime? get punchInTime => _punchInTime;
  DateTime? get punchOutTime => _punchOutTime;
  bool get isLoaded => _isLoaded;

  static const Duration riyadhOffset = Duration(hours: 3);

  DateTime toRiyadhTime(DateTime utcTime) =>
      utcTime.toUtc().add(riyadhOffset);

  DateTime get todayInRiyadh =>
      DateTime.now().toUtc().add(riyadhOffset);

  // Set employee ID – must be called after login
  void setEmployeeId(String id) {
    if (_employeeId == id) return;
    _employeeId = id;
    _isLoaded = false;
    loadDailyPunches();
  }

  String _todayKey() {
    final today = todayInRiyadh;
    final dateStr = DateFormat('yyyy-MM-dd').format(today);
    if (_employeeId != null && _employeeId!.isNotEmpty) {
      return "${_employeeId}_$dateStr";
    } else {
      // Fallback – should not happen after login
      return dateStr;
    }
  }

  Future<void> loadDailyPunches() async {
    if (_employeeId == null || _employeeId!.isEmpty) {
      debugPrint("⚠️ PunchProvider: employeeId not set, skipping load");
      _punchInTime = null;
      _punchOutTime = null;
      _isLoaded = true;
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    try {
      final key = _todayKey();
      final inStr = prefs.getString("IN_$key");
      final outStr = prefs.getString("OUT_$key");

      _punchInTime = (inStr != null && inStr.isNotEmpty)
          ? DateTime.parse(inStr).toUtc()
          : null;
      _punchOutTime = (outStr != null && outStr.isNotEmpty)
          ? DateTime.parse(outStr).toUtc()
          : null;

      debugPrint("📱 Local loaded for $_employeeId - IN: $_punchInTime, OUT: $_punchOutTime");
    } catch (e) {
      debugPrint("Punch load error: $e");
      _punchInTime = null;
      _punchOutTime = null;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> fetchAndSyncTodayFromERP({
    required String employeeId,
  }) async {
    // Ensure local employee ID matches
    if (_employeeId != employeeId) {
      setEmployeeId(employeeId);
    } else if (_employeeId == null) {
      setEmployeeId(employeeId);
    }

    try {
      debugPrint("🌐 Fetching today's attendance from ERP for employee: $employeeId");
      final attendanceService = AttendanceService();
      final todayData = await attendanceService.getTodayAttendance(
        employeeId: employeeId,
      );
      final DateTime? punchIn = todayData['punchIn'];
      final DateTime? punchOut = todayData['punchOut'];

      debugPrint("🌐 ERP Data - IN: $punchIn, OUT: $punchOut");

      bool needsUpdate = false;
      if (punchIn != null && _punchInTime == null) {
        needsUpdate = true;
        debugPrint("📝 ERP has punchIn but local doesn't - updating");
      }
      if (punchOut != null && _punchOutTime == null) {
        needsUpdate = true;
        debugPrint("📝 ERP has punchOut but local doesn't - updating");
      }
      if (needsUpdate || (punchIn != null && punchOut != null)) {
        await syncTodayFromApi(
          punchIn: punchIn,
          punchOut: punchOut,
        );
        debugPrint("✅ Successfully synced from ERP to local");
      } else {
        debugPrint("📱 Local data is already up to date");
      }
    } catch (e) {
      debugPrint("❌ Failed to sync from ERP: $e");
    }
  }

  Future<void> syncTodayFromApi({
    required DateTime? punchIn,
    required DateTime? punchOut,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();

    if (punchIn != null) {
      await prefs.setString(
        "IN_$key",
        punchIn.toUtc().toIso8601String(),
      );
      _punchInTime = punchIn;
    }
    if (punchOut != null) {
      await prefs.setString(
        "OUT_$key",
        punchOut.toUtc().toIso8601String(),
      );
      _punchOutTime = punchOut;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPunchIn(DateTime utcTime) async {
    if (_employeeId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final utc = utcTime.toUtc();

    await prefs.setString("IN_$key", utc.toIso8601String());
    await prefs.remove("OUT_$key");

    _punchInTime = utc;
    _punchOutTime = null;
    notifyListeners();
  }

  Future<void> setPunchOut(DateTime utcTime) async {
    if (_employeeId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final utc = utcTime.toUtc();

    await prefs.setString("OUT_$key", utc.toIso8601String());
    _punchOutTime = utc;
    notifyListeners();
  }

  DateTime? get punchInTimeRiyadh =>
      _punchInTime?.add(riyadhOffset);
  DateTime? get punchOutTimeRiyadh =>
      _punchOutTime?.add(riyadhOffset);

  String totalHours() {
    if (_punchInTime == null) return "00:00";
    final end = _punchOutTime ?? DateTime.now().toUtc();
    final diff = end.difference(_punchInTime!);
    return "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}";
  }

  double progressValue() {
    if (_punchInTime == null) return 0;
    final end = _punchOutTime ?? DateTime.now().toUtc();
    return (end.difference(_punchInTime!).inSeconds /
            (12 * 60 * 60))
        .clamp(0.0, 1.0);
  }

  bool canPunchInToday() => _punchInTime == null;
  bool canPunchOutToday() =>
      _punchInTime != null && _punchOutTime == null;
  bool isTodayCompleted() =>
      _punchInTime != null && _punchOutTime != null;

  Future<void> clearTodayPunches() async {
    if (_employeeId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    await prefs.remove("IN_$key");
    await prefs.remove("OUT_$key");
    _punchInTime = null;
    _punchOutTime = null;
    notifyListeners();
  }

  AttendanceStatus getCurrentAttendanceStatus() {
    if (_punchInTime == null) return AttendanceStatus.absent;
    if (_punchOutTime == null) return AttendanceStatus.checkedIn;
    final duration = _punchOutTime!.difference(_punchInTime!);
    final hours = duration.inMinutes / 60;
    if (hours >= 9) return AttendanceStatus.overtime;
    if (hours >= 8) return AttendanceStatus.completed;
    return AttendanceStatus.shortage;
  }

  Duration getTotalDuration() {
    if (_punchInTime == null) return Duration.zero;
    final end = _punchOutTime ?? DateTime.now().toUtc();
    return end.difference(_punchInTime!);
  }
}