import 'package:flutter/material.dart';
import 'package:management_app/model/attendance_model.dart';

Color getDateColor(
    DateTime date, Map<DateTime, AttendanceLog> map) {

  if (map.containsKey(date)) {
    return Colors.green; // Present
  }
  return Colors.red; // Absent
}
