

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/punch_provider.dart';
import '../model/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _currentMonth = DateTime.now();
  late ScrollController _scrollController;
  bool _isLoading = false;

  
  static const Color skyBlue = Color(0xFF87CEEB);  
  static const Color lightSky = Color(0xFFE0F2FE);  
  static const Color mediumSky = Color(0xFF7EC8E0);  
  static const Color deepSky = Color(0xFF00A5E0);    
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);

  
  List<Color> _getHeaderGradientColors(bool isDarkMode) {
    return isDarkMode
        ? [charcoal, slate, const Color(0xFF1E1E2E)]
        : [skyBlue, mediumSky, deepSky];
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAttendance();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAttendance() async {
    if (_isLoading) return; 

    setState(() => _isLoading = true);

    try {
      final employeeProvider = context.read<EmployeeProvider>();
      final attendanceProvider = context.read<AttendanceProvider>();

      final employeeId = employeeProvider.employeeId;

      if (employeeId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text("Employee ID not found")),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }      
      
      attendanceProvider.clearError();
      
      await attendanceProvider.loadMonthAttendance(employeeId, _currentMonth);
      
      if (mounted) {
        setState(() {}); 
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text("Failed to load attendance: ${e.toString()}")),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.completed:
        return Colors.green;
      case AttendanceStatus.overtime:
        return deepSky;
      case AttendanceStatus.shortage:
        return Colors.orange;
      case AttendanceStatus.checkedIn:
        return mediumSky;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.completed:
        return "Completed";
      case AttendanceStatus.overtime:
        return "Overtime";
      case AttendanceStatus.shortage:
        return "Shortage";
      case AttendanceStatus.checkedIn:
        return "Checked In";
      case AttendanceStatus.absent:
        return "Absent";
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.completed:
        return Icons.check_circle;
      case AttendanceStatus.overtime:
        return Icons.timer;
      case AttendanceStatus.shortage:
        return Icons.schedule;
      case AttendanceStatus.checkedIn:
        return Icons.login;
      case AttendanceStatus.absent:
        return Icons.cancel;
    }
  }

  Widget _buildCalendarDay(int day, DateTime date, BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final punchProvider = context.read<PunchProvider>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final screenWidth = MediaQuery.of(context).size.width;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    Color? bgColor;
    Color? textColor;
    Border? border;
    AttendanceStatus? status;
    double opacity = 1.0;

    
    for (final key in attendanceProvider.attendanceMap.keys) {
      if (key.year == date.year &&
          key.month == date.month &&
          key.day == date.day) {
        status = attendanceProvider.attendanceMap[key]!.status;
        break;
      }
    }

    if (date.isAfter(today)) {
      bgColor = Colors.transparent;
      textColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
      border = Border.all(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        width: 1.0,
      );
      opacity = 0.5;
    } else if (date.isAtSameMomentAs(today)) {
      if (punchProvider.punchInTime != null) {
        status ??= AttendanceStatus.checkedIn;
        bgColor = _getStatusColor(status);
        textColor = Colors.white;
        border = Border.all(
          color: skyBlue,
          width: 2.5,
        );
      } else {
        bgColor = isDarkMode ? slate.withOpacity(0.3) : Colors.grey.shade200;
        textColor = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;
        border = Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
          width: 1.5,
        );
      }
    } else {
      status ??= AttendanceStatus.absent;
      bgColor = _getStatusColor(status);
      textColor = Colors.white;
      if (status == AttendanceStatus.absent) {
        opacity = 0.9;
      }
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        width: screenWidth * 0.11,
        height: screenWidth * 0.11,
        margin: EdgeInsets.all(screenWidth * 0.005),
        decoration: BoxDecoration(
          gradient: bgColor != Colors.transparent ? null : null,
          color: bgColor,
          border: border,
          borderRadius: BorderRadius.circular(12),
          boxShadow: date.isAtSameMomentAs(today) && punchProvider.punchInTime != null
              ? [
                  BoxShadow(
                    color: skyBlue.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "$day",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: screenWidth * 0.035,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.002),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat('EEE').format(date).substring(0, 1),
                  style: TextStyle(
                    fontSize: screenWidth * 0.022,
                    fontWeight: FontWeight.w600,
                    color: textColor?.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceLog(AttendanceLog log) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = log.date.isAtSameMomentAs(today);
    final statusColor = _getStatusColor(log.status);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      decoration: BoxDecoration(
        color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: skyBlue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: skyBlue.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.035),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              width: screenWidth * 0.14,
              height: screenWidth * 0.14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [statusColor, statusColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DateFormat('dd').format(log.date),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: screenWidth * 0.045,
                          height: 0.9,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DateFormat('MMM').format(log.date),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: screenWidth * 0.025,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: screenWidth * 0.035),

            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.015),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(log.status),
                          color: statusColor,
                          size: screenWidth * 0.04,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Expanded(
                        child: Text(
                          _getStatusText(log.status),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            fontSize: screenWidth * 0.035,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: screenHeight * 0.004,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: skyBlue.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            "TODAY",
                            style: TextStyle(
                              fontSize: screenWidth * 0.025,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.025),
                    decoration: BoxDecoration(
                      color: isDarkMode ? slate.withOpacity(0.3) : Colors.grey[50]!,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: skyBlue.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeRow(
                                context,
                                "Punch In",
                                log.formattedCheckIn,
                                Icons.login_rounded,
                                skyBlue,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: _buildTimeRow(
                                context,
                                "Punch Out",
                                log.formattedCheckOut,
                                Icons.logout_rounded,
                                deepSky,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.008),

                        
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.008,
                          ),
                          decoration: BoxDecoration(
                            color: skyBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skyBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_rounded,
                                size: screenWidth * 0.035,
                                color: skyBlue,
                              ),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                "Total: ",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                log.formattedTotalHours,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w900,
                                  color: skyBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: screenWidth * 0.035),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.028,
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenWidth * 0.002),
              Text(
                time,
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenWidth * 0.012,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? slate.withOpacity(0.3) : pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: skyBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenWidth * 0.025,
            height: screenWidth * 0.025,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.015),
          Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.028,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBorder(Color color, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenWidth * 0.012,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? slate.withOpacity(0.3) : pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: skyBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenWidth * 0.025,
            height: screenWidth * 0.025,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: skyBlue,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: skyBlue.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.015),
          Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.028,
              fontWeight: FontWeight.w600,
              color: skyBlue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final attendanceProvider = context.watch<AttendanceProvider>();
    final now = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    final canGoNext =
        _currentMonth.year < now.year ||
        (_currentMonth.year == now.year && _currentMonth.month < now.month);

    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );

    final monthlyLogs = attendanceProvider.getMonthlyLogs(_currentMonth);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: gradientColors.first,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDarkMode ? charcoal : offWhite,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.015,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: skyBlue.withOpacity(0.3),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Attendance",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isLoading
                            ? SizedBox(
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: screenWidth * 0.06,
                                color: Colors.white,
                              ),
                        onPressed: _isLoading ? null : _refreshAttendance,
                      ),
                    ),
                  ],
                ),
              ),

              
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAttendance,
                  color: skyBlue,
                  backgroundColor: isDarkMode ? slate : pureWhite,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      
                      SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.all(screenWidth * 0.035),
                          padding: EdgeInsets.all(screenWidth * 0.035),
                          decoration: BoxDecoration(
                            color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: skyBlue.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: skyBlue.withOpacity(0.1),
                                blurRadius: 25,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: skyBlue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: skyBlue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading ? null : () {
                                          setState(() {
                                            _currentMonth = DateTime(
                                              _currentMonth.year,
                                              _currentMonth.month - 1,
                                            );
                                          });
                                          _refreshAttendance();
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: EdgeInsets.all(screenWidth * 0.02),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: gradientColors,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.chevron_left_rounded,
                                            size: screenWidth * 0.05,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                        vertical: screenHeight * 0.01,
                                      ),
                                      child: Text(
                                        DateFormat('MMMM yyyy').format(_currentMonth),
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w800,
                                          color: skyBlue,
                                        ),
                                      ),
                                    ),

                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: (canGoNext && !_isLoading)
                                            ? () {
                                                setState(() {
                                                  _currentMonth = DateTime(
                                                    _currentMonth.year,
                                                    _currentMonth.month + 1,
                                                  );
                                                });
                                                _refreshAttendance();
                                              }
                                            : null,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: EdgeInsets.all(screenWidth * 0.02),
                                          decoration: BoxDecoration(
                                            gradient: canGoNext
                                                ? LinearGradient(
                                                    colors: gradientColors,
                                                  )
                                                : const LinearGradient(
                                                    colors: [Colors.grey, Colors.grey],
                                                  ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            size: screenWidth * 0.05,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              
                              if (_isLoading)
                                LinearProgressIndicator(
                                  backgroundColor: isDarkMode ? slate : Colors.grey[200],
                                  valueColor: const AlwaysStoppedAnimation<Color>(skyBlue),
                                  minHeight: 2,
                                ),

                              
                              if (attendanceProvider.errorMessage != null)
                                Container(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.error_outline_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        child: Text(
                                          attendanceProvider.errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      
                                      GestureDetector(
                                        onTap: () {
                                          attendanceProvider.clearError();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: screenHeight * 0.015),

                              
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  crossAxisSpacing: screenWidth * 0.01,
                                  mainAxisSpacing: screenWidth * 0.01,
                                  childAspectRatio: 1,
                                ),
                                itemCount: daysInMonth,
                                itemBuilder: (context, index) {
                                  final day = index + 1;
                                  final date = DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month,
                                    day,
                                  );
                                  return _buildCalendarDay(day, date, context);
                                },
                              ),

                              SizedBox(height: screenHeight * 0.025),

                              
                              Wrap(
                                spacing: screenWidth * 0.02,
                                runSpacing: screenHeight * 0.01,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildLegend(Colors.green, "Completed"),
                                  _buildLegend(deepSky, "Overtime"),
                                  _buildLegend(Colors.orange, "Shortage"),
                                  _buildLegend(mediumSky, "Checked In"),
                                  _buildLegend(Colors.red, "Absent"),
                                  _buildLegend(Colors.grey, "Future"),
                                  _buildLegendBorder(skyBlue, "Today"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.05,
                            screenHeight * 0.025,
                            screenWidth * 0.05,
                            screenHeight * 0.015,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.history_rounded,
                                  size: screenWidth * 0.04,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                "Attendance Logs",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w800,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      
                      if (monthlyLogs.isNotEmpty)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.05,
                            0,
                            screenWidth * 0.05,
                            screenHeight * 0.03,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final log = monthlyLogs[index];
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);

                              if (log.date.isAtSameMomentAs(today)) {
                                final punchProvider = context.read<PunchProvider>();
                                if (punchProvider.punchInTime == null) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return _buildAttendanceLog(log);
                            }, childCount: monthlyLogs.length),
                          ),
                        )
                      else if (!_isLoading && attendanceProvider.errorMessage == null)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: EdgeInsets.all(screenWidth * 0.05),
                            padding: EdgeInsets.all(screenWidth * 0.08),
                            decoration: BoxDecoration(
                              color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: skyBlue.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  decoration: BoxDecoration(
                                    color: skyBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: screenWidth * 0.1,
                                    color: skyBlue,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Text(
                                  "No attendance records",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.008),
                                Text(
                                  "Attendance records will appear here",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.032,
                                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}