// ignore_for_file: deprecated_member_use, unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:management_app/providers/employee_provider.dart';
import 'package:management_app/providers/profile_provider.dart';
import 'package:management_app/providers/punch_provider.dart';
import 'package:management_app/providers/attendance_provider.dart';
import 'package:management_app/screen/support_screen.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:management_app/services/checkin_service.dart';
import 'package:management_app/services/location_service.dart';
import 'package:management_app/services/connectivity_service.dart';
import 'package:management_app/services/biometric_service.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomemainScreen extends StatefulWidget {
  const HomemainScreen({super.key});

  @override
  State<HomemainScreen> createState() => _HomemainScreenState();
}

class _HomemainScreenState extends State<HomemainScreen>
    with TickerProviderStateMixin {
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;
  String _greeting = 'Welcome,';
  Timer? _greetingTimer;

  final CheckinService _checkinService = CheckinService();
  final LocationService _locationService = LocationService();
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isPunching = false;
  bool _isAuthenticating = false;
  bool _showSuccess = false;
  String _successText = "";
  bool _hasError = false;
  String _errorMessage = "";
  String _errorActionText = "";
  VoidCallback? _errorAction;

  Timer? _debounceTimer;
  static const int _debounceDuration = 800;

  Position? _currentPosition;
  String _locationAddress = "Tap to fetch location";
  bool _isLocationLoading = false;
  String _locationError = "";
  String _locationType = "";
  Timer? _locationTimer;
  bool _isFirstLocationFetch = true;

  bool _hasInternet = true;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  StreamSubscription? _connectivitySubscription;

  String _biometricType = "Fingerprint";
  bool _biometricAvailable = false;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowAnimationController;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    _greetingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _greeting = _getTimeBasedGreeting();
        });
      }
    });

    _connectivityService.initialize();
    _checkInternetConnection();

    _connectivitySubscription = _connectivityService.connectionStatus.listen(
      (result) {
        if (!mounted) return;
        setState(() {
          _connectionType = result;
          _hasInternet = result != ConnectivityResult.none;
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchLocation();
      _checkBiometricAvailability();
      await _initializeData();
    });

    _locationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        _fetchLocation();
      }
    });
  }

  Future<void> _checkBiometricAvailability() async {
    final status = await BiometricService.checkBiometricStatus();
    final type = await BiometricService.getBiometricTypeName();
    setState(() {
      _biometricType = type;
      _biometricAvailable = status == BiometricStatus.available;
    });
  }

  Future<void> _checkInternetConnection() async {
    bool hasInternet = await _connectivityService.hasInternetConnection();
    ConnectivityResult type = await _connectivityService.getConnectionType();
    setState(() {
      _hasInternet = hasInternet;
      _connectionType = type;
    });
  }

  Future<void> _initializeData() async {
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      await employeeProvider.loadEmployeeIdFromLocal();
      await Provider.of<ProfileProvider>(context, listen: false).loadProfile();
      final employeeId = employeeProvider.employeeId;
      if (employeeId != null) {
        final punchProvider = Provider.of<PunchProvider>(
          context,
          listen: false,
        );
        punchProvider.setEmployeeId(employeeId);
        await punchProvider.loadDailyPunches();
        await punchProvider.fetchAndSyncTodayFromERP(employeeId: employeeId);
        await Provider.of<AttendanceProvider>(
          context,
          listen: false,
        ).loadMonthAttendance(employeeId, DateTime.now());
        debugPrint("✅ _initializeData completed successfully");
      } else {
        debugPrint("⚠️ Employee ID is null in _initializeData");
      }
    } catch (e) {
      debugPrint("❌ Error in _initializeData: $e");
    }
  }

  Future<void> _fetchLocation() async {
    if (_isLocationLoading) return;
    setState(() {
      _isLocationLoading = true;
      _locationError = "";
      _locationType = "";
    });
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _isLocationLoading = false;
      _isFirstLocationFetch = false;
      if (result['success']) {
        _currentPosition = result['position'];
        _locationError = "";
        _locationType = "success";
        _locationAddress =
            "📍 ${result['position'].latitude.toStringAsFixed(6)}, ${result['position'].longitude.toStringAsFixed(6)}";
        _getAddressFromCoordinates(
          result['position'].latitude,
          result['position'].longitude,
        );
      } else {
        _locationError = result['error'];
        _locationType = result['type'];
        if (result['type'] == 'permission_denied' ||
            result['type'] == 'permanent') {
          _locationAddress = "Permission required";
        } else if (result['type'] == 'gps_disabled') {
          _locationAddress = "GPS is off";
        } else {
          _locationAddress = "Location unavailable";
        }
      }
    });
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    String address = await _locationService.getAddressFromLatLng(lat, lng);
    if (mounted) {
      setState(() {
        _locationAddress = address;
      });
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }

  void _updateTime() {
    if (!mounted) return;
    final localTime = DateTime.now();
    setState(() {
      _currentTime = DateFormat('hh:mm a').format(localTime);
      _currentDate = DateFormat('MMM dd, yyyy • EEEE').format(localTime);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _greetingTimer?.cancel();
    _locationTimer?.cancel();
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _animationController.dispose();
    _glowAnimationController.dispose();
    BiometricService.stopAuthentication();
    super.dispose();
  }

  Color _fingerprintColor(PunchProvider punchProvider) {
    if (_isPunching || _isAuthenticating) return skyBlue;
    if (punchProvider.punchInTime == null) return skyBlue;
    if (punchProvider.punchOutTime == null) return deepSky;
    return mediumSky;
  }

  String _punchText(PunchProvider punchProvider) {
    if (punchProvider.punchInTime == null) return "PUNCH IN";
    if (punchProvider.punchOutTime == null) return "PUNCH OUT";
    return "COMPLETED";
  }

  Color _punchButtonColor(PunchProvider punchProvider) {
    if (punchProvider.punchInTime == null) return skyBlue;
    if (punchProvider.punchOutTime == null) return deepSky;
    return mediumSky;
  }

  List<BoxShadow> _getButtonShadows(PunchProvider punchProvider) {
    final color = _punchButtonColor(punchProvider);
    if (punchProvider.punchInTime != null &&
        punchProvider.punchOutTime == null) {
      return [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 15,
          spreadRadius: 2,
          offset: const Offset(0, 6),
        ),
      ];
    } else if (punchProvider.punchInTime == null) {
      return [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: color.withOpacity(0.2),
        blurRadius: 8,
        spreadRadius: 1,
        offset: const Offset(0, 3),
      ),
    ];
  }

  // ==================== UPDATED SMALLER DIALOGS (30% smaller) ====================
  
  void _showSuccessDialog({required String message, required bool isPunchIn}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color successColor = const Color(0xFF22C55E);
    
    final String formattedTime = DateFormat('hh:mm a').format(DateTime.now());
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: screenWidth * 0.75,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [charcoal, slate]
                      : [pureWhite, offWhite],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: successColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: successColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [successColor, successColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: successColor.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPunchIn ? Icons.login_rounded : Icons.logout_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  
                  Text(
                    isPunchIn ? "PUNCH IN ✓" : "PUNCH OUT ✓",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w800,
                      color: successColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: successColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: successColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w700,
                            color: successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.028,
                      color: isDarkMode ? pureWhite : charcoal,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  
                  SizedBox(
                    width: screenWidth * 0.08,
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: successColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(successColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showErrorDialog(
    String message, {
    VoidCallback? onAction,
    String actionText = 'OK',
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color errorColor = const Color(0xFFEF4444);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: screenWidth * 0.75,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [charcoal, slate]
                      : [pureWhite, offWhite],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: errorColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: errorColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [errorColor, errorColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: errorColor.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  
                  Text(
                    "FAILED",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w800,
                      color: errorColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        color: errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  
                  if (onAction != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onAction();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: errorColor.withOpacity(0.1),
                        foregroundColor: errorColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.008,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        actionText,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: screenWidth * 0.08,
                      height: 2,
                      child: LinearProgressIndicator(
                        backgroundColor: errorColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(errorColor),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    if (onAction == null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _showInfoDialog(String message, {Color color = Colors.blue}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: screenWidth * 0.75,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [charcoal, slate]
                      : [pureWhite, offWhite],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            color == const Color(0xFFF97316) 
                                ? Icons.warning_rounded
                                : Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  
                  Text(
                    "INFO",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  
                  SizedBox(
                    width: screenWidth * 0.08,
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showBiometricDialog(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getHeaderGradientColors(isDarkMode);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: screenWidth * 0.75,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [charcoal, slate]
                    : [pureWhite, offWhite],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: gradientColors.first.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                SizedBox(height: screenHeight * 0.012),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? pureWhite : charcoal,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== REST OF YOUR ORIGINAL CODE (NO CHANGES) ====================

  Future<void> _onPunchTap() async {
    final punchProvider = Provider.of<PunchProvider>(context, listen: false);
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(
      const Duration(milliseconds: _debounceDuration),
      () {},
    );
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = "";
        _errorAction = null;
        _errorActionText = "";
      });
    }
    if (punchProvider.punchInTime != null &&
        punchProvider.punchOutTime != null) {
      _showInfoDialog('You have already completed your shift today');
      return;
    }
    if (_isPunching || _isAuthenticating) return;
    HapticFeedback.lightImpact();
    bool isSupported = await BiometricService.isDeviceSupported();
    if (!isSupported) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Your device does not support biometric authentication';
      });
      _showErrorDialog('Your device does not support fingerprint');
      return;
    }
    BiometricStatus status = await BiometricService.checkBiometricStatus();
    if (status == BiometricStatus.notEnrolled) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No fingerprint enrolled';
        _errorActionText = 'Open Settings';
        _errorAction = () => BiometricService.openSecuritySettings();
      });
      _showErrorDialog(
        'Please enroll fingerprint in device settings',
        onAction: BiometricService.openSecuritySettings,
        actionText: 'Open Settings',
      );
      return;
    }
    if (status != BiometricStatus.available) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Biometric authentication not available';
      });
      _showErrorDialog('Biometric authentication not available');
      return;
    }
    bool isPunchIn;
    if (punchProvider.punchInTime == null) {
      isPunchIn = true;
    } else if (punchProvider.punchOutTime == null) {
      isPunchIn = false;
    } else {
      return;
    }
    _showBiometricDialog(
      'Please scan your ${_biometricType.toLowerCase()} to ${isPunchIn ? "punch in" : "punch out"}',
    );
    await _authenticateAndPunch(isPunchIn);
  }

  Future<void> _authenticateAndPunch(bool isPunchIn) async {
    setState(() {
      _isAuthenticating = true;
    });
    String reason = isPunchIn
        ? 'Authenticate to punch in'
        : 'Authenticate to punch out';
    BiometricResult result = await BiometricService.authenticate(
      reason: reason,
    );
    if (mounted) Navigator.pop(context);
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
    });
    if (result.success) {
      HapticFeedback.mediumImpact();
      await _performPunch(isPunchIn);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _errorMessage = result.message;
        if (result.errorType == BiometricErrorType.notEnrolled) {
          _errorActionText = 'Open Settings';
          _errorAction = () => BiometricService.openSecuritySettings();
        } else if (result.errorType == BiometricErrorType.lockedOut) {
          _errorActionText = 'OK';
          _errorAction = null;
        } else {
          _errorActionText = '';
          _errorAction = null;
        }
      });
      if (result.errorType == BiometricErrorType.canceled) {
        _showInfoDialog(result.message, color: Colors.orange);
      } else if (result.errorType == BiometricErrorType.notEnrolled) {
        _showErrorDialog(
          result.message,
          onAction: BiometricService.openSecuritySettings,
          actionText: 'Open Settings',
        );
      } else {
        _showErrorDialog(result.message);
      }
    }
  }

  Future<void> _performPunch(bool isPunchIn) async {
    final employeeId = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    ).employeeId;
    final punchProvider = Provider.of<PunchProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    if (employeeId == null || _isPunching) return;
    if (isPunchIn && punchProvider.punchInTime != null) {
      _showInfoDialog('Already checked in today');
      return;
    }
    if (!isPunchIn && punchProvider.punchOutTime != null) {
      _showInfoDialog('Already checked out today');
      return;
    }
    final logType = isPunchIn ? "IN" : "OUT";
    try {
      setState(() {
        _isPunching = true;
        _showSuccess = false;
        _hasError = false;
      });
      HapticFeedback.mediumImpact();
      final localNow = DateTime.now();

      Position? freshPosition;
      bool locationSuccess = false;
      try {
        setState(() {
          _isLocationLoading = true;
          _locationError = "";
        });
        final locationResult = await _locationService.getCurrentLocation();
        if (locationResult['success']) {
          freshPosition = locationResult['position'];
          if (freshPosition!.latitude != 0 || freshPosition.longitude != 0) {
            locationSuccess = true;
            setState(() {
              _currentPosition = freshPosition;
              _locationError = "";
              _locationType = "success";
              _locationAddress =
                  "📍 ${freshPosition!.latitude.toStringAsFixed(6)}, ${freshPosition.longitude.toStringAsFixed(6)}";
            });
            _getAddressFromCoordinates(
              freshPosition.latitude,
              freshPosition.longitude,
            );
          } else {
            setState(() {
              _locationError = "Invalid location";
              _locationType = "error";
              _locationAddress = "Location unavailable";
            });
            locationSuccess = false;
          }
        } else {
          setState(() {
            _locationError = locationResult['error'];
            _locationType = locationResult['type'];
            _locationAddress = "Location unavailable";
          });
          locationSuccess = false;
        }
      } catch (e) {
        debugPrint("Error getting location: $e");
        setState(() {
          _locationError = "Failed to get location";
          _locationAddress = "Location unavailable";
        });
        locationSuccess = false;
      } finally {
        setState(() {
          _isLocationLoading = false;
        });
      }
      if (!locationSuccess || freshPosition == null) {
        setState(() {
          _isPunching = false;
          _hasError = true;
          _errorMessage = _locationError.isNotEmpty
              ? _locationError
              : "Cannot punch without valid location";
        });
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _hasError = false;
              _errorMessage = "";
            });
          }
        });
        return;
      }
      final result = await _checkinService.checkIn(
        employeeId: employeeId,
        logType: logType,
        currentPosition: freshPosition,
      );
      if (result['blocked'] == true) {
        setState(() {
          _isPunching = false;
          _hasError = true;
          _errorMessage = result['message'] ?? "Location not allowed";
        });
        _showErrorDialog(
          result['message'] ?? 'You are outside any office area',
        );
        Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _hasError = false);
        });
        return;
      }
      setState(() {
        _isPunching = false;
      });
      if (result['offlineMode'] == true) {
        _successText = isPunchIn
            ? "✓ Checked in (Offline Mode)"
            : "✓ Checked out (Offline Mode)";
        setState(() {
          _showSuccess = true;
        });
        if (isPunchIn) {
          await punchProvider.setPunchIn(localNow);
        } else {
          await punchProvider.setPunchOut(localNow);
        }
        _showInfoDialog(
          result['message'] ?? 'Punch saved offline',
          color: Colors.orange,
        );
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSuccess = false);
        });
      } else if (result['success']) {
        if (isPunchIn) {
          await punchProvider.setPunchIn(localNow);
        } else {
          await punchProvider.setPunchOut(localNow);
        }
        _successText = isPunchIn
            ? "Checked in at ${DateFormat('hh:mm a').format(localNow)}"
            : "Checked out at ${DateFormat('hh:mm a').format(localNow)}";
        setState(() {
          _showSuccess = true;
        });
        await punchProvider.loadDailyPunches();
        _showSuccessDialog(
          message: result['message'] ?? _successText,
          isPunchIn: isPunchIn,
        );
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSuccess = false);
        });
        _fetchLocation();
        final currentMonth = DateTime(localNow.year, localNow.month);
        await attendanceProvider.loadMonthAttendance(employeeId, currentMonth);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? "Punch failed";
        });
        _showErrorDialog(result['message'] ?? 'Punch failed');
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _hasError = false;
              _errorMessage = "";
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isPunching = false;
        _hasError = true;
        _errorMessage = "An error occurred";
      });
      _showErrorDialog('Error: $e');
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _hasError = false;
            _errorMessage = "";
          });
        }
      });
    }
  }

  Widget _buildTimeWidget(
    String time,
    String label,
    Color color,
    IconData icon,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: screenWidth * 0.05),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          Text(
            time,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.002),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.028,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (_isLocationLoading) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: skyBlue.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(skyBlue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Fetching location...",
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: skyBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_locationError.isNotEmpty) {
      Color errorColor = Colors.red;
      IconData errorIcon = Icons.error_outline_rounded;
      String buttonText = "Settings";
      VoidCallback? onTap;
      switch (_locationType) {
        case 'gps_disabled':
          errorColor = Colors.orange;
          errorIcon = Icons.gps_off_rounded;
          buttonText = "Enable GPS";
          onTap = () => _locationService.openLocationSettings();
          break;
        case 'denied':
          errorColor = Colors.orange;
          errorIcon = Icons.location_off_rounded;
          buttonText = "Allow Permission";
          onTap = () => _locationService.requestLocationPermission().then(
            (_) => _fetchLocation(),
          );
          break;
        case 'permanent':
          errorColor = Colors.red;
          errorIcon = Icons.security_rounded;
          buttonText = "Open Settings";
          onTap = () => _locationService.openAppSettings();
          break;
        case 'timeout':
          errorColor = Colors.orange;
          errorIcon = Icons.timer_off_rounded;
          buttonText = "Retry";
          onTap = () => _fetchLocation();
          break;
        default:
          errorColor = Colors.red;
          errorIcon = Icons.error_outline_rounded;
          buttonText = "Retry";
          onTap = () => _fetchLocation();
      }
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: errorColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(errorIcon, size: 16, color: errorColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _locationError,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      color: errorColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: skyBlue.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: skyBlue.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: skyBlue,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _locationAddress,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: skyBlue,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternetStatusWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (!_hasInternet) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                "No Internet Connection",
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProgressWidget(PunchProvider punchProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (punchProvider.punchInTime == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Ready to start your day?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w700,
              color: skyBlue,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          Text(
            "Use ${_biometricType} to begin",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.032,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    if (punchProvider.punchOutTime == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Time to wrap up!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w700,
              color: deepSky,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          Text(
            "Use ${_biometricType} to end your shift",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.032,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.01,
          ),
          decoration: BoxDecoration(
            color: mediumSky.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: mediumSky.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: mediumSky,
                size: screenWidth * 0.045,
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                "Shift completed",
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  color: mediumSky,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.008),
        Text(
          "Great work today!",
          style: TextStyle(
            fontSize: screenWidth * 0.032,
            color: mediumSky,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterContent(
    PunchProvider punchProvider,
    ThemeData theme,
    double buttonSize,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = buttonSize * 0.3;
    final isDarkMode = theme.brightness == Brightness.dark;
    if (_showSuccess) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: skyBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: skyBlue.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: iconSize * 0.6,
            ),
          ),
          SizedBox(height: buttonSize * 0.03),
          Text(
            _successText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.032,
              color: skyBlue,
            ),
          ),
        ],
      );
    }
    if (_isPunching || _isAuthenticating) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize * 0.6,
            height: iconSize * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: screenWidth * 0.008,
              valueColor: const AlwaysStoppedAnimation<Color>(skyBlue),
            ),
          ),
          SizedBox(height: buttonSize * 0.04),
          Text(
            _isAuthenticating ? "Authenticating..." : "Processing...",
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w800,
              color: skyBlue,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (punchProvider.punchInTime != null &&
            punchProvider.punchOutTime == null)
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: deepSky,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: deepSky.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                size: iconSize * 0.7,
                color: Colors.white,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: punchProvider.punchInTime == null ? skyBlue : mediumSky,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (punchProvider.punchInTime == null ? skyBlue : mediumSky)
                          .withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              size: iconSize * 0.7,
              color: Colors.white,
            ),
          ),
        SizedBox(height: buttonSize * 0.05),
        if (punchProvider.punchInTime != null &&
            punchProvider.punchOutTime == null)
          Text(
            _punchText(punchProvider),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: screenWidth * 0.04,
              color: deepSky,
              letterSpacing: 0.8,
            ),
          )
        else
          Text(
            _punchText(punchProvider),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: screenWidth * 0.04,
              color: punchProvider.punchInTime == null ? skyBlue : mediumSky,
              letterSpacing: 0.8,
            ),
          ),
        SizedBox(height: buttonSize * 0.03),
        if (punchProvider.punchInTime == null)
          Text(
            "Tap for ${_biometricType}",
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: skyBlue,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (punchProvider.punchOutTime == null)
          Text(
            "Tap for ${_biometricType}",
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: deepSky,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Text(
            "Work completed",
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: mediumSky,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isPortrait = screenHeight > screenWidth;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getHeaderGradientColors(isDarkMode);
    final buttonSize = isPortrait ? screenWidth * 0.45 : screenHeight * 0.45;
    final progressSize = buttonSize * 1.15;
    final glowSize = buttonSize * 1.25;
    final punchProvider = Provider.of<PunchProvider>(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: gradientColors.first,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDarkMode ? charcoal : offWhite,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.first.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -screenHeight * 0.1,
                              right: -screenWidth * 0.1,
                              child: Container(
                                width: screenWidth * 0.5,
                                height: screenWidth * 0.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -screenHeight * 0.05,
                              left: -screenWidth * 0.1,
                              child: Container(
                                width: screenWidth * 0.4,
                                height: screenWidth * 0.4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.02),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                top: screenHeight * 0.02,
                                left: screenWidth * 0.05,
                                right: screenWidth * 0.05,
                                bottom: screenHeight * 0.03,
                              ),
                              child: Column(
                                children: [
                                  Consumer<ProfileProvider>(
                                    builder: (_, provider, __) {
                                      final user = provider.profileData;
                                      final imagePath = user?['user_image'];
                                      return Stack(
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/profilescreen',
                                                    ),
                                                child: Container(
                                                  width: screenWidth * 0.12,
                                                  height: screenWidth * 0.12,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.white
                                                            .withOpacity(0.3),
                                                        blurRadius: 20,
                                                        spreadRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                  child: CircleAvatar(
                                                    backgroundColor: lightSky,
                                                    child: ClipOval(
                                                      child:
                                                          (imagePath != null &&
                                                              imagePath
                                                                  .isNotEmpty)
                                                          ? Image.network(
                                                              "https://ppecon.erpnext.com$imagePath",
                                                              fit: BoxFit.cover,
                                                              width: double
                                                                  .infinity,
                                                              height: double
                                                                  .infinity,
                                                              headers: {
                                                                "Cookie":
                                                                    AuthService
                                                                        .cookies
                                                                        .join(
                                                                          "; ",
                                                                        ),
                                                              },
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) {
                                                                    return Image.asset(
                                                                      "assets/images/app_icon.png",
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    );
                                                                  },
                                                            )
                                                          : Image.asset(
                                                              "assets/images/app_icon.png",
                                                              fit: BoxFit.cover,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.03,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _greeting,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.035,
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          screenHeight * 0.003,
                                                    ),
                                                    Text(
                                                      user?['full_name'] ??
                                                          "Employee",
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.05,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 10,
                                                          ),
                                                        ],
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const SupportScreen(),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.support_agent,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: screenHeight * 0.025),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _currentTime,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.13,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 15,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.04,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.2),
                                              Colors.white.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _currentDate,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.025,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: glowSize,
                                  height: glowSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _punchButtonColor(
                                          punchProvider,
                                        ).withOpacity(0.15),
                                        Colors.transparent,
                                      ],
                                      radius: 0.8,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: progressSize,
                                  height: progressSize,
                                  child: CircularProgressIndicator(
                                    value: punchProvider.progressValue().clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    strokeWidth: screenWidth * 0.015,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _punchButtonColor(punchProvider),
                                    ),
                                    backgroundColor: isDarkMode
                                        ? slate
                                        : Colors.grey.shade200,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                if (punchProvider.punchInTime != null &&
                                    punchProvider.punchOutTime == null)
                                  ScaleTransition(
                                    scale: _pulseAnimation,
                                    child: Container(
                                      width: progressSize * 0.95,
                                      height: progressSize * 0.95,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: deepSky.withOpacity(0.3),
                                          width: screenWidth * 0.008,
                                        ),
                                      ),
                                    ),
                                  ),
                                Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    borderRadius: BorderRadius.circular(
                                      buttonSize,
                                    ),
                                    onTap: _biometricAvailable
                                        ? _onPunchTap
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: buttonSize,
                                      height: buttonSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDarkMode ? slate : pureWhite,
                                        boxShadow: _getButtonShadows(
                                          punchProvider,
                                        ),
                                        border: Border.all(
                                          color: _punchButtonColor(
                                            punchProvider,
                                          ).withOpacity(0.3),
                                          width: screenWidth * 0.005,
                                        ),
                                      ),
                                      child: Center(
                                        child: _buildCenterContent(
                                          punchProvider,
                                          Theme.of(context),
                                          buttonSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? slate.withOpacity(0.5)
                                    : pureWhite,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: skyBlue.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: skyBlue.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildTimeWidget(
                                    punchProvider.punchInTime == null
                                        ? "--:--"
                                        : DateFormat(
                                            'hh:mm a',
                                          ).format(punchProvider.punchInTime!),
                                    "PUNCH IN",
                                    skyBlue,
                                    Icons.login_rounded,
                                  ),
                                  _buildTimeWidget(
                                    punchProvider.punchOutTime == null
                                        ? "--:--"
                                        : DateFormat(
                                            'hh:mm a',
                                          ).format(punchProvider.punchOutTime!),
                                    "PUNCH OUT",
                                    deepSky,
                                    Icons.logout_rounded,
                                  ),
                                  _buildTimeWidget(
                                    punchProvider.totalHours(),
                                    "TOTAL",
                                    mediumSky,
                                    Icons.timer_rounded,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInternetStatusWidget(),
                            const SizedBox(height: 8),
                            _buildLocationWidget(),
                            const SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? slate.withOpacity(0.5)
                                    : pureWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: skyBlue.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: _buildProgressWidget(punchProvider),
                            ),
                            if (_hasError)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: screenHeight * 0.02,
                                ),
                                child: AnimatedSlide(
                                  duration: const Duration(milliseconds: 300),
                                  offset: _hasError
                                      ? Offset.zero
                                      : const Offset(0, -1),
                                  child: Container(
                                    padding: EdgeInsets.all(screenWidth * 0.04),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.03),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                "Attention",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.002,
                                              ),
                                              Text(
                                                _errorMessage,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (_errorAction != null) ...[
                                                SizedBox(
                                                  height: screenHeight * 0.005,
                                                ),
                                                TextButton(
                                                  onPressed: _errorAction,
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor: Colors
                                                        .white
                                                        .withOpacity(0.2),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                  ),
                                                  child: Text(_errorActionText),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
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