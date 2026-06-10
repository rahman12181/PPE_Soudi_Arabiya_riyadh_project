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

  static final DateFormat _storageFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  DateTime _riyadhNow() {
    final utcNow = DateTime.now().toUtc();
    final riyadhNow = utcNow.add(const Duration(hours: 3));
    return _storageFormat.parse(_storageFormat.format(riyadhNow), false);
  }

  void setEmployeeId(String id) {
    if (_employeeId == id) return;
    _employeeId = id;
    _isLoaded = false;
    loadDailyPunches();
  }

  String _todayKey() {
    final todayRiyadh = DateTime.now().toUtc().add(const Duration(hours: 3));
    final dateStr = DateFormat('yyyy-MM-dd').format(todayRiyadh);
    if (_employeeId != null && _employeeId!.isNotEmpty) {
      return "${_employeeId}_$dateStr";
    }
    return dateStr;
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

      // ✅ Parse as plain datetime — no timezone flag
      _punchInTime = (inStr != null && inStr.isNotEmpty)
          ? _storageFormat.parse(inStr, false)
          : null;
      _punchOutTime = (outStr != null && outStr.isNotEmpty)
          ? _storageFormat.parse(outStr, false)
          : null;

      debugPrint("📱 Loaded for $_employeeId - IN: $_punchInTime, OUT: $_punchOutTime");
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
    if (_employeeId != employeeId) {
      setEmployeeId(employeeId);
    } else if (_employeeId == null) {
      setEmployeeId(employeeId);
    }

    try {
      debugPrint("🌐 Fetching today from ERP for: $employeeId");
      final attendanceService = AttendanceService();
      final todayData = await attendanceService.getTodayAttendance(
        employeeId: employeeId,
      );

      final DateTime? punchIn = todayData['punchIn'];
      final DateTime? punchOut = todayData['punchOut'];

      debugPrint("🌐 ERP times - IN: $punchIn, OUT: $punchOut");

      bool needsUpdate = false;
      if (punchIn != null && _punchInTime == null) needsUpdate = true;
      if (punchOut != null && _punchOutTime == null) needsUpdate = true;

      if (needsUpdate || (punchIn != null && punchOut != null)) {
        await syncTodayFromApi(punchIn: punchIn, punchOut: punchOut);
        debugPrint("✅ Synced from ERP");
      } else {
        debugPrint("📱 Local data already up to date");
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
      final str = _storageFormat.format(punchIn);
      await prefs.setString("IN_$key", str);
      _punchInTime = punchIn;
    }
    if (punchOut != null) {
      final str = _storageFormat.format(punchOut);
      await prefs.setString("OUT_$key", str);
      _punchOutTime = punchOut;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPunchIn(DateTime deviceTime) async {
    if (_employeeId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();

    // ✅ Convert device time → Riyadh time → store as plain datetime
    final riyadhTime = deviceTime.toUtc().add(const Duration(hours: 3));
    final plainRiyadh = _storageFormat.parse(_storageFormat.format(riyadhTime), false);
    final str = _storageFormat.format(plainRiyadh);

    await prefs.setString("IN_$key", str);
    await prefs.remove("OUT_$key");

    _punchInTime = plainRiyadh;
    _punchOutTime = null;
    notifyListeners();
  }

  Future<void> setPunchOut(DateTime deviceTime) async {
    if (_employeeId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();

    // ✅ Convert device time → Riyadh time → store as plain datetime
    final riyadhTime = deviceTime.toUtc().add(const Duration(hours: 3));
    final plainRiyadh = _storageFormat.parse(_storageFormat.format(riyadhTime), false);
    final str = _storageFormat.format(plainRiyadh);

    await prefs.setString("OUT_$key", str);
    _punchOutTime = plainRiyadh;
    notifyListeners();
  }

  String totalHours() {
    if (_punchInTime == null) return "00:00";
    
    final end = _punchOutTime ?? _riyadhNow();
    final diff = end.difference(_punchInTime!);
    return "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}";
  }

  double progressValue() {
    if (_punchInTime == null) return 0;
    final end = _punchOutTime ?? _riyadhNow(); 
    return (end.difference(_punchInTime!).inSeconds / (8 * 60 * 60))
        .clamp(0.0, 1.0);
  }

  bool canPunchInToday() => _punchInTime == null;
  bool canPunchOutToday() => _punchInTime != null && _punchOutTime == null;
  bool isTodayCompleted() => _punchInTime != null && _punchOutTime != null;

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
    final end = _punchOutTime ?? _riyadhNow(); // ✅
    return end.difference(_punchInTime!);
  }
}