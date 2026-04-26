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
  String? checkIn;
  String? checkOut;
  Duration totalHours;
  AttendanceStatus status;
  
  AttendanceLog({
    required this.date,
    this.checkIn,
    this.checkOut,
    this.totalHours = Duration.zero,
    this.status = AttendanceStatus.absent,
  });

  String get formattedCheckIn {
    if (checkIn == null) return "--:--";
    try {
      final utcTime = DateTime.parse("1970-01-01 ${checkIn!}").toUtc();
      final riyadhTime = utcTime.add(const Duration(hours: 3));
      return DateFormat('hh:mm a').format(riyadhTime);
    } catch (_) {
      return checkIn!;
    }
  }

  String get formattedCheckOut {
    if (checkOut == null) return "--:--";
    try {
      final utcTime = DateTime.parse("1970-01-01 ${checkOut!}").toUtc();
      final riyadhTime = utcTime.add(const Duration(hours: 3));
      return DateFormat('hh:mm a').format(riyadhTime);
    } catch (_) {
      return checkOut!;
    }
  }

  String get formattedTotalHours {
    final hours = totalHours.inHours.toString().padLeft(2, '0');
    final minutes = (totalHours.inMinutes % 60).toString().padLeft(2, '0');
    return "$hours:$minutes";
  }
}