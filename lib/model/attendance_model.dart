import 'package:intl/intl.dart';

enum AttendanceStatus {
  absent,
  checkedIn,
  completed,
  overtime,
  shortage,
}

class AttendanceLog {
  final DateTime date;

  // Store as actual DateTime (already converted to local) for accuracy
  DateTime? checkInTime;
  DateTime? checkOutTime;
  Duration totalHours;
  AttendanceStatus status;

  // Legacy string fields — kept for backward compat but not used for display
  String? checkIn;
  String? checkOut;

  AttendanceLog({
    required this.date,
    this.checkIn,
    this.checkOut,
    this.checkInTime,
    this.checkOutTime,
    this.totalHours = Duration.zero,
    this.status = AttendanceStatus.absent,
  });

  /// Returns formatted punch-in time in device local timezone.
  /// Uses [checkInTime] (DateTime) if available, falls back to [checkIn] string.
  String get formattedCheckIn {
    if (checkInTime != null) {
      return DateFormat('hh:mm a').format(checkInTime!);
    }
    if (checkIn == null) return "--:--";
    return checkIn!;
  }

  /// Returns formatted punch-out time in device local timezone.
  /// Uses [checkOutTime] (DateTime) if available, falls back to [checkOut] string.
  String get formattedCheckOut {
    if (checkOutTime != null) {
      return DateFormat('hh:mm a').format(checkOutTime!);
    }
    if (checkOut == null) return "--:--";
    return checkOut!;
  }

  String get formattedTotalHours {
    final hours = totalHours.inHours.toString().padLeft(2, '0');
    final minutes = (totalHours.inMinutes % 60).toString().padLeft(2, '0');
    return "$hours:$minutes";
  }
}