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

  // ✅ FORCE SAUDI TIME (UTC+3)
  String get formattedCheckIn {
    if (checkIn == null) return "--:--";
    try {
      final parts = checkIn!.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        final nowUtc = DateTime.now().toUtc();
        final saudiNow = nowUtc.add(const Duration(hours: 3));
        final time = DateTime(saudiNow.year, saudiNow.month, saudiNow.day, hour, minute);
        
        return DateFormat('hh:mm a').format(time);
      }
      return checkIn!;
    } catch (_) {
      return checkIn!;
    }
  }

  // ✅ FORCE SAUDI TIME (UTC+3)
  String get formattedCheckOut {
    if (checkOut == null) return "--:--";
    try {
      final parts = checkOut!.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        final nowUtc = DateTime.now().toUtc();
        final saudiNow = nowUtc.add(const Duration(hours: 3));
        final time = DateTime(saudiNow.year, saudiNow.month, saudiNow.day, hour, minute);
        
        return DateFormat('hh:mm a').format(time);
      }
      return checkOut!;
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