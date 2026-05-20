// ignore_for_file: unused_field, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:management_app/screen/attendance_requests_list_screen.dart';
import 'package:management_app/services/connectivity_service.dart';
import '../services/attendance_request_service.dart';

class AttendanceRequestScreen extends StatefulWidget {
  const AttendanceRequestScreen({super.key});

  @override
  State<AttendanceRequestScreen> createState() =>
      _AttendanceRequestScreenState();
}

class _AttendanceRequestScreenState extends State<AttendanceRequestScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  DateTime selectedDate = DateTime.now();
  final TextEditingController explanationCtrl = TextEditingController();

  String reason = "On Duty";
  String selectedShift = "Office";
  bool isSubmitting = false;

  late AnimationController _mainController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  late double screenWidth;
  late double screenHeight;
  late bool isDarkMode;

  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color lightSky = Color(0xFFE0F2FE);
  static const Color mediumSky = Color(0xFF7EC8E0);
  static const Color deepSky = Color(0xFF00A5E0);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);

  double responsiveWidth(double v) => screenWidth * v;
  double responsiveFontSize(double v) => screenWidth * (v / 375);

  final List<String> reasons = [
    "On Duty",
    "Missed Punch",
    "System Issue",
    "Medical Emergency",
    "Personal Reason",
    "Transport Issue",
  ];

  final List<String> shifts = [
    "Office",
    "operation",
  ];

  final Map<String, IconData> reasonIcons = {
    "On Duty": Icons.work_outline,
    "Missed Punch": Icons.timer_outlined,
    "System Issue": Icons.error_outline,
    "Medical Emergency": Icons.local_hospital_outlined,
    "Personal Reason": Icons.person_outline,
    "Transport Issue": Icons.directions_bus_outlined,
  };

  final Map<String, Color> reasonColors = {
    "On Duty": skyBlue,
    "Missed Punch": Colors.amber,
    "System Issue": Colors.red,
    "Medical Emergency": Colors.green,
    "Personal Reason": Colors.purple,
    "Transport Issue": Colors.orange,
  };

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // Listen to explanation changes to rebuild counter
    explanationCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemNavigationBar();
  }

  void _updateSystemNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: isDark ? charcoal : pureWhite,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    explanationCtrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
    );
    super.dispose();
  }

  // ── Internet check dialog ────────────────────────────────────────────────────

  Future<bool> _checkInternet() async {
    final hasInternet =
        await ConnectivityService().hasInternetConnection();
    if (!hasInternet && mounted) {
      await _showNoInternetDialog();
      return false;
    }
    return true;
  }

  Future<void> _showNoInternetDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? slate : pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.03),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: screenWidth * 0.12,
                color: Colors.red,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "No Internet Connection",
              style: TextStyle(
                fontSize: responsiveFontSize(17),
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white : charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.012),
            Text(
              "Please check your Wi-Fi or mobile data and try again.",
              style: TextStyle(
                fontSize: responsiveFontSize(13),
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.028),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                  elevation: 0,
                ),
                child: Text(
                  "OK, Got it",
                  style: TextStyle(
                    fontSize: responsiveFontSize(14),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  // ── Submit ───────────────────────────────────────────────────────────────────

Future<void> submitAttendanceRequest() async {
  if (!_formKey.currentState!.validate() || isSubmitting) return;

  // 1. Internet check first
  final hasInternet = await _checkInternet();
  if (!hasInternet) return;

  HapticFeedback.mediumImpact();
  _bounceController.forward(from: 0);

  setState(() => isSubmitting = true);

  try {
    // ✅ Get response from service
    final response = await AttendanceRequestService().submitRequest(
      date: selectedDate,
      reason: reason,
      explanation: explanationCtrl.text.trim(),
      shift: selectedShift,
    );

    if (!mounted) return;

    // ✅ Check response status
    if (response['success'] == true) {
      // Success case
      await _showSuccessAnimation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Attendance request submitted successfully!",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(screenWidth * 0.04),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context);
      }
    } else {
      // ❌ API returned success = false
      final errorMsg = response['message'] ?? "Request failed. Please try again.";
      _showErrorSnackBar(errorMsg);
    }
  } catch (e) {
    if (!mounted) return;
    
    final errorMsg = e.toString().toLowerCase();
    final isNetworkError = errorMsg.contains("socket") ||
        errorMsg.contains("connection") ||
        errorMsg.contains("network") ||
        errorMsg.contains("internet") ||
        errorMsg.contains("timeout");
    
    if (isNetworkError) {
      _showErrorSnackBar("No internet connection. Please check your network.");
    } else {
      _showErrorSnackBar("Request failed. Please try again.");
    }
  } finally {
    if (mounted) setState(() => isSubmitting = false);
  }
}

// ✅ Add this helper method for error snackbar
void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.all(screenWidth * 0.04),
      duration: const Duration(seconds: 3),
    ),
  );
}

  // ── Success overlay ──────────────────────────────────────────────────────────

  Future<void> _showSuccessAnimation() async {
    OverlayEntry? overlayEntry;
    bool dismissed = false;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                padding: EdgeInsets.all(screenWidth * 0.08),
                decoration: BoxDecoration(
                  color: isDarkMode ? slate : pureWhite,
                  borderRadius: BorderRadius.circular(screenWidth * 0.06),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(
                      color: skyBlue.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(color: Colors.green, width: 3),
                      ),
                      child: Icon(Icons.check,
                          size: screenWidth * 0.08, color: Colors.green),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Text(
                      "Request Sent!",
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.w800,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "Your attendance request has been submitted successfully.",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!dismissed) {
                            dismissed = true;
                            overlayEntry?.remove();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(screenWidth * 0.03),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: screenHeight * 0.015,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "OK",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    await Future.delayed(const Duration(seconds: 3));
    if (!dismissed) {
      dismissed = true;
      overlayEntry.remove();
    }
  }

  // ── UI helpers ───────────────────────────────────────────────────────────────

  InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: responsiveFontSize(14),
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: skyBlue,
        fontSize: responsiveFontSize(14),
        fontWeight: FontWeight.w600,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsiveWidth(0.035)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsiveWidth(0.035)),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsiveWidth(0.035)),
        borderSide: const BorderSide(color: skyBlue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsiveWidth(0.035)),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsiveWidth(0.035)),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      filled: true,
      fillColor: isDarkMode ? slate.withOpacity(0.5) : offWhite,
      prefixIcon: icon != null
          ? Icon(icon, size: screenWidth * 0.05, color: skyBlue)
          : null,
    );
  }

  Widget _buildReasonChips() {
    return Wrap(
      spacing: screenWidth * 0.02,
      runSpacing: screenHeight * 0.01,
      children: reasons.map((reasonOption) {
        final bool isSelected = reason == reasonOption;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                reasonIcons[reasonOption],
                size: screenWidth * 0.04,
                color: isSelected ? Colors.white : reasonColors[reasonOption],
              ),
              SizedBox(width: screenWidth * 0.015),
              Flexible(
                child: Text(
                  reasonOption,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: responsiveFontSize(12),
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              HapticFeedback.selectionClick();
              setState(() => reason = reasonOption);
            }
          },
          backgroundColor:
              isDarkMode ? slate.withOpacity(0.5) : Colors.grey[200],
          selectedColor: reasonColors[reasonOption]?.withOpacity(0.8),
          side: BorderSide(
            color: isSelected
                ? reasonColors[reasonOption]!
                : isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveWidth(0.025)),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenHeight * 0.01,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShiftDropdown(Color textColor, Color? subtitleColor) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 2),
      decoration: BoxDecoration(
        color: isDarkMode ? slate.withOpacity(0.5) : offWhite,
        borderRadius: BorderRadius.circular(responsiveWidth(0.035)),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedShift,
          isExpanded: true,
          dropdownColor: isDarkMode ? slate : pureWhite,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: skyBlue, size: screenWidth * 0.06),
          items: shifts.map((shift) {
            return DropdownMenuItem<String>(
              value: shift,
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: screenWidth * 0.045, color: skyBlue),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    shift,
                    style: TextStyle(
                      fontSize: responsiveFontSize(14),
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    HapticFeedback.selectionClick();
                    setState(() => selectedShift = value);
                  }
                },
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isDarkMode = Theme.of(context).brightness == Brightness.dark;

    _updateSystemNavigationBar();

    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final cardColor = isDarkMode ? slate.withOpacity(0.5) : pureWhite;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor =
        isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.5)
        : skyBlue.withOpacity(0.1);

    // Clamp character count to avoid overflow in counter
    final charCount = explanationCtrl.text.length;
    final charCountColor = charCount > 500 ? Colors.red : subtitleColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              "Excuse & Request",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: responsiveFontSize(18),
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          leading: ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(screenWidth * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [skyBlue, deepSky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: Colors.white, size: screenWidth * 0.06),
              color: isDarkMode ? slate : pureWhite,
              surfaceTintColor: isDarkMode ? slate : pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    BorderSide(color: skyBlue.withOpacity(0.3), width: 1),
              ),
              elevation: 4,
              onSelected: (value) {
                if (value == 'my_requests') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AttendanceRequestsListScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'my_requests',
                  height: 48,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: skyBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history,
                            size: 18, color: skyBlue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "My Requests",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "View attendance history",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Body ──────────────────────────────────────────────────────────────
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.05,
              screenHeight * 0.02,
              screenWidth * 0.05,
              screenHeight * 0.05,
            ),
            child: Column(
              children: [
                // ── Info card ────────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        margin:
                            EdgeInsets.only(bottom: screenHeight * 0.03),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(responsiveWidth(0.05)),
                          border: Border.all(
                              color: skyBlue.withOpacity(0.2), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 25,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      EdgeInsets.all(screenWidth * 0.03),
                                  decoration: BoxDecoration(
                                    color: skyBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    size: screenWidth * 0.07,
                                    color: skyBlue,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Submit Your Request",
                                        style: TextStyle(
                                          fontSize: responsiveFontSize(16),
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Text(
                                        "Fill in the details below to request attendance adjustment",
                                        style: TextStyle(
                                          fontSize: responsiveFontSize(12),
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Divider(
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                              height: 1,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              "Note: Requests are subject to approval by your manager.",
                              style: TextStyle(
                                fontSize: responsiveFontSize(11),
                                fontStyle: FontStyle.italic,
                                color: isDarkMode ? skyBlue : deepSky,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Form card ─────────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(responsiveWidth(0.05)),
                        side: BorderSide(
                            color: skyBlue.withOpacity(0.2), width: 1.5),
                      ),
                      color: cardColor,
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.045),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Date picker ─────────────────────────────────
                              Text(
                                "Select Date",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () async {
                                        HapticFeedback.selectionClick();
                                        final picked = await showDatePicker(
                                          context: context,
                                          firstDate: DateTime.now().subtract(
                                              const Duration(days: 30)),
                                          lastDate: DateTime.now(),
                                          initialDate: selectedDate,
                                          builder: (context, child) {
                                            return Theme(
                                              data:
                                                  Theme.of(context).copyWith(
                                                colorScheme:
                                                    ColorScheme.light(
                                                  primary: skyBlue,
                                                  onPrimary: Colors.white,
                                                  surface: isDarkMode
                                                      ? slate
                                                      : pureWhite,
                                                  onSurface: textColor,
                                                ),
                                                dialogTheme: DialogThemeData(
                                                  backgroundColor: isDarkMode
                                                      ? slate
                                                      : pureWhite,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          setState(
                                              () => selectedDate = picked);
                                        }
                                      },
                                borderRadius: BorderRadius.circular(
                                    responsiveWidth(0.035)),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.02,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? slate.withOpacity(0.3)
                                        : offWhite,
                                    borderRadius: BorderRadius.circular(
                                        responsiveWidth(0.035)),
                                    border: Border.all(
                                      color: skyBlue.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: screenWidth * 0.05,
                                        color: skyBlue,
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Selected Date",
                                              style: TextStyle(
                                                fontSize:
                                                    responsiveFontSize(12),
                                                color: subtitleColor,
                                              ),
                                            ),
                                            SizedBox(
                                                height: screenHeight * 0.005),
                                            Text(
                                              DateFormat('EEEE, dd MMMM yyyy')
                                                  .format(selectedDate),
                                              style: TextStyle(
                                                fontSize:
                                                    responsiveFontSize(14),
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: screenWidth * 0.06,
                                        color: subtitleColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.025),

                              // ── Reason chips ─────────────────────────────────
                              Text(
                                "Select Reason",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              _buildReasonChips(),

                              SizedBox(height: screenHeight * 0.025),

                              // ── Shift dropdown ───────────────────────────────
                              Text(
                                "Select Shift",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              _buildShiftDropdown(textColor, subtitleColor),

                              SizedBox(height: screenHeight * 0.025),

                              // ── Explanation ──────────────────────────────────
                              Text(
                                "Additional Explanation",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              TextFormField(
                                controller: explanationCtrl,
                                style: TextStyle(
                                  fontSize: responsiveFontSize(14),
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 4,
                                minLines: 3,
                                maxLength: 500,
                                buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        maxLength}) =>
                                    null, // hide default counter; we show custom below
                                enabled: !isSubmitting,
                                decoration: inputDecoration(
                                  "Explain your situation in detail...",
                                  icon: Icons.description_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Please provide an explanation";
                                  }
                                  if (v.trim().length < 10) {
                                    return "Minimum 10 characters required";
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                              ),

                              SizedBox(height: screenHeight * 0.008),

                              // ── Char counter ──────────────────────────────────
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "$charCount / 500",
                                  style: TextStyle(
                                    fontSize: responsiveFontSize(12),
                                    color: charCountColor,
                                    fontWeight: charCount > 500
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.035),

                              // ── Submit button ─────────────────────────────────
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                width: double.infinity,
                                height: screenHeight * 0.065,
                                child: ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : submitAttendanceRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSubmitting
                                        ? Colors.grey.shade400
                                        : skyBlue,
                                    disabledBackgroundColor:
                                        Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.035)),
                                    ),
                                    elevation: isSubmitting ? 0 : 5,
                                    shadowColor: skyBlue.withOpacity(0.5),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedOpacity(
                                        opacity: isSubmitting ? 0 : 1,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.send_rounded,
                                                size: screenWidth * 0.045,
                                                color: Colors.white),
                                            SizedBox(width: screenWidth * 0.02),
                                            Text(
                                              "Submit Request",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSubmitting)
                                        SizedBox(
                                          width: screenWidth * 0.06,
                                          height: screenWidth * 0.06,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                            backgroundColor: Colors.white
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // ── Cancel button ─────────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: screenHeight * 0.055,
                                child: TextButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          Navigator.pop(context);
                                        },
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.035)),
                                    ),
                                    foregroundColor: subtitleColor,
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.038,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Footer note ───────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.03),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: screenWidth * 0.04, color: skyBlue),
                        SizedBox(width: screenWidth * 0.015),
                        Flexible(
                          child: Text(
                            "You'll receive a notification once your request is processed",
                            style: TextStyle(
                              fontSize: responsiveFontSize(11),
                              color: subtitleColor,
                            ),
                            textAlign: TextAlign.center,
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
      ),
    );
  }
}