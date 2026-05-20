import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../model/attendance_model.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  final Map<DateTime, AttendanceLog> _attendanceMap = {};
  bool _isLoading = false;
  String? _errorMessage;

  // ✅ ERP time format — used to parse "2026-05-20 08:29:36" strings
  static final DateFormat _erpFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  /// Parse ERP time string as-is — no UTC/local conversion.
  /// ERP stores Riyadh time; we display exactly what ERP has.
  static DateTime _parseErpTime(String timeStr) {
    return _erpFormat.parse(timeStr, false);
  }

  Map<DateTime, AttendanceLog> get attendanceMap => _attendanceMap;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMonthAttendance(String employeeId, DateTime month) async {
    if (employeeId.isEmpty) {
      _errorMessage = "Employee ID not found";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final rawData = await _service.fetchLogs(
        employeeId: employeeId,
        start: start,
        end: end,
      );

      _processAttendanceData(rawData);
      await _loadTodayAttendance(employeeId);
    } catch (e) {
      _errorMessage = "Failed to load attendance data";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processAttendanceData(List<dynamic> rawData) {
    final Map<DateTime, List<Map<String, dynamic>>> dateGroupedLogs = {};

    for (final item in rawData) {
      try {
        final timeStr = item["time"]?.toString();
        final logType = item["log_type"]?.toString();

        if (timeStr == null || logType == null) continue;

        // ✅ KEY FIX: Parse ERP time as-is — no timezone conversion.
        // ERP returns "2026-05-20 08:29:36" in Asia/Riyadh.
        // We display EXACTLY this value on all devices regardless of device timezone.
        // So India device shows 08:29, Saudi device shows 08:29 — always correct.
        final erpTime = _parseErpTime(timeStr);

        // Group by the date part from ERP time (not device local date)
        final dateKey = DateTime(erpTime.year, erpTime.month, erpTime.day);

        dateGroupedLogs.putIfAbsent(dateKey, () => []);
        dateGroupedLogs[dateKey]!.add({
          'time': erpTime,
          'type': logType,
        });
      } catch (_) {
        // Skip invalid entries
      }
    }

    dateGroupedLogs.forEach((date, logs) {
      logs.sort((a, b) =>
          (a['time'] as DateTime).compareTo(b['time'] as DateTime));

      DateTime? firstIn;
      DateTime? lastOut;

      for (final log in logs) {
        if (log['type'] == 'IN' && firstIn == null) {
          firstIn = log['time'] as DateTime;
        } else if (log['type'] == 'OUT') {
          lastOut = log['time'] as DateTime;
        }
      }

      final totalHours = (firstIn != null && lastOut != null)
          ? lastOut.difference(firstIn)
          : Duration.zero;

      final status = _determineStatus(firstIn, lastOut, totalHours);

      _attendanceMap[date] = AttendanceLog(
        date: date,
        checkInTime: firstIn,
        checkOutTime: lastOut,
        checkIn: firstIn != null
            ? DateFormat("hh:mm a").format(firstIn)
            : null,
        checkOut: lastOut != null
            ? DateFormat("hh:mm a").format(lastOut)
            : null,
        totalHours: totalHours,
        status: status,
      );
    });
  }

  Future<void> _loadTodayAttendance(String employeeId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final todayData = await _service.fetchLogs(
        employeeId: employeeId,
        start: todayStart,
        end: todayEnd,
      );

      if (todayData.isNotEmpty) {
        _processAttendanceData(todayData);
      }
    } catch (_) {}
  }

  AttendanceStatus _determineStatus(
    DateTime? checkIn,
    DateTime? checkOut,
    Duration totalHours,
  ) {
    if (checkIn == null && checkOut == null) {
      return AttendanceStatus.absent;
    } else if (checkIn != null && checkOut == null) {
      return AttendanceStatus.checkedIn;
    } else if (checkOut != null) {
      final hours = totalHours.inHours + (totalHours.inMinutes % 60) / 60;
      if (hours >= 9.0) return AttendanceStatus.overtime;
      if (hours >= 8.0) return AttendanceStatus.completed;
      return AttendanceStatus.shortage;
    }
    return AttendanceStatus.absent;
  }

  AttendanceLog? getTodayLog() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    return _attendanceMap[todayKey];
  }

  List<AttendanceLog> getMonthlyLogs(DateTime month) {
    final List<AttendanceLog> logs = [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final int maxDay = isCurrentMonth ? today.day : lastDay.day;

    for (int day = 1; day <= maxDay; day++) {
      final date = DateTime(month.year, month.month, day);

      AttendanceLog? log;
      for (final key in _attendanceMap.keys) {
        if (key.year == date.year &&
            key.month == date.month &&
            key.day == date.day) {
          log = _attendanceMap[key];
          break;
        }
      }

      logs.add(
        log ??
            AttendanceLog(
              date: date,
              status: AttendanceStatus.absent,
            ),
      );
    }

    return logs.reversed.toList();
  }

  bool hasAttendanceForDate(DateTime date) {
    for (final key in _attendanceMap.keys) {
      if (key.year == date.year &&
          key.month == date.month &&
          key.day == date.day) {
        return true;
      }
    }
    return false;
  }

  Future<void> refresh(String employeeId) async {
    await loadMonthAttendance(employeeId, DateTime.now());
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}