import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystembarUtil {
  static void setSystemBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // STATUS BAR
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDark ? Brightness.dark : Brightness.light,

        // NAVIGATION BAR (🔥 MAIN FIX)
        systemNavigationBarColor:
            isDark ? const Color(0xFF121212) : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor:
            isDark ? const Color(0xFF121212) : Colors.transparent,
      ),
    );
  }
}
