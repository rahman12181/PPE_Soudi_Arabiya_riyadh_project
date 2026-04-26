

// ignore_for_file: deprecated_member_use, unused_field

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:management_app/services/leave_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class LeaveRequest extends StatefulWidget {
  const LeaveRequest({super.key});
  
  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showSuccessDialog = false;
  bool _showErrorDialog = false;
  String _errorMessage = "";
  String _successMessage = "";
  
  late AnimationController _mainController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  final TextEditingController fromDateCtrl = TextEditingController();
  final TextEditingController toDateCtrl = TextEditingController();
  final TextEditingController reasonCtrl = TextEditingController();
  final TextEditingController empCodeCtrl = TextEditingController();
  final TextEditingController empNameCtrl = TextEditingController();
  final TextEditingController inchargeCtrl = TextEditingController();

  String? selectedLeaveType;
  String compOff = "NO";

  
  static const Color skyBlue = Color(0xFF87CEEB);  
  static const Color lightSky = Color(0xFFE0F2FE);  
  static const Color mediumSky = Color(0xFF7EC8E0);  
  static const Color deepSky = Color(0xFF00A5E0);    
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);

  final List<Map<String, dynamic>> leaveTypes = [
    {"code": "CL", "name": "Annual Leave", "color": skyBlue, "icon": Icons.beach_access},
    {"code": "SL", "name": "Sick Leave", "color": deepSky, "icon": Icons.local_hospital},
    //{"code": "EL", "name": "Umrah Leave", "color": mediumSky, "icon": Icons.work},
    {"code": "UL", "name": "Unpaid Leave", "color": Colors.orange, "icon": Icons.money_off},
  ];

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
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutBack,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
    
    _loadEmployeeData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainController.forward();
    });
  }

  Future<void> _loadEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmpCode = prefs.getString("employeeId") ?? "";
    final profileData = prefs.getString("profileData");
    
    setState(() {
      empCodeCtrl.text = savedEmpCode;
    });
    
    if (profileData != null) {
      try {
        final data = jsonDecode(profileData);
        final fullName = data["full_name"] ?? "";
        setState(() {
          empNameCtrl.text = fullName;
        });
      } catch (e) {
        print("Error parsing profile data: $e");
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Future<void> selectDate(TextEditingController controller) async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.light(
              primary: isDarkMode ? skyBlue : skyBlue,
              onPrimary: Colors.white,
              surface: isDarkMode ? slate : Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDarkMode ? slate : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      controller.text =
          "${pickedDate.day.toString().padLeft(2, '0')}-"
          "${pickedDate.month.toString().padLeft(2, '0')}-"
          "${pickedDate.year}";
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  void _showSuccessPopup(String message) {
    HapticFeedback.mediumImpact();
    _bounceController.forward();
    setState(() {
      _successMessage = message;
      _showSuccessDialog = true;
      _showErrorDialog = false;
    });
  }

  void _showErrorPopup(String message) {
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMessage = message;
      _showErrorDialog = true;
      _showSuccessDialog = false;
    });
  }

  void _closeDialogs() {
    HapticFeedback.lightImpact();
    setState(() {
      _showSuccessDialog = false;
      _showErrorDialog = false;
      _successMessage = "";
      _errorMessage = "";
    });
  }

  void _navigateToDashboard() {
    HapticFeedback.lightImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    fromDateCtrl.clear();
    toDateCtrl.clear();
    reasonCtrl.clear();
    inchargeCtrl.clear();
    setState(() {
      selectedLeaveType = null;
      compOff = "NO";
    });
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    if (selectedLeaveType == null) {
      _showErrorPopup("Please select leave type");
      return;
    }

    final hasNet = await _hasInternet();
    if (!hasNet) {
      _showErrorPopup("No internet connection. Please check your connection and try again.");
      return;
    }

    try {
      final fromParts = fromDateCtrl.text.split("-");
      final toParts = toDateCtrl.text.split("-");
      
      if (fromParts.length != 3 || toParts.length != 3) {
        _showErrorPopup("Invalid date format. Please use DD-MM-YYYY format.");
        return;
      }
      
      final fromDate = DateTime(
        int.parse(fromParts[2]),
        int.parse(fromParts[1]),
        int.parse(fromParts[0]),
      );
      final toDate = DateTime(
        int.parse(toParts[2]),
        int.parse(toParts[1]),
        int.parse(toParts[0]),
      );
      
      if (toDate.isBefore(fromDate)) {
        _showErrorPopup("To date cannot be before from date.");
        return;
      }
      
      final difference = toDate.difference(fromDate).inDays;
      if (difference < 0) {
        _showErrorPopup("Invalid date range.");
        return;
      }
    } catch (e) {
      _showErrorPopup("Invalid date format. Please use DD-MM-YYYY format.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LeaveRequestService.submitLeave(
        employeeCode: empCodeCtrl.text.trim(),
        leaveType: LeaveRequestService.mapLeaveType(selectedLeaveType),
        fromDate: fromDateCtrl.text,
        toDate: toDateCtrl.text,
        reason: reasonCtrl.text.trim(),
        compOff: compOff,
        inchargeReplacement: inchargeCtrl.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result["success"] == true) {
        final successMsg = result["message"] ?? "Leave applied successfully!";
        String displayMessage = successMsg;
        _resetForm();
        await Future.delayed(const Duration(milliseconds: 300));
        _showSuccessPopup(displayMessage);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        _showErrorPopup(result["message"] ?? "Failed to apply leave. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      _showErrorPopup("An error occurred: ${e.toString()}");
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    final mediaQuery = MediaQuery.of(context);
    final isDarkMode = mediaQuery.platformBrightness == Brightness.dark;
    final width = mediaQuery.size.width;
    
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: width * 0.035,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: skyBlue,
        fontSize: width * 0.035,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.04,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(width * 0.03),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(width * 0.03),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(width * 0.03),
        borderSide: const BorderSide(
          color: skyBlue,
          width: 2.0,
        ),
      ),
      filled: true,
      fillColor: isDarkMode ? slate : offWhite,
      prefixIcon: icon != null
          ? Icon(
              icon,
              size: width * 0.05,
              color: skyBlue,
            )
          : null,
      prefixIconColor: skyBlue,
      suffixIcon: label.contains("Date")
          ? Icon(
              Icons.calendar_today_rounded,
              size: width * 0.05,
              color: skyBlue,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    fromDateCtrl.dispose();
    toDateCtrl.dispose();
    reasonCtrl.dispose();
    empCodeCtrl.dispose();
    empNameCtrl.dispose();
    inchargeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDarkMode = mediaQuery.platformBrightness == Brightness.dark;
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final primaryColor = skyBlue;
    final secondaryColor = deepSky;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? slate : pureWhite;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                color: backgroundColor,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    color: backgroundColor,
                    width: width,
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.04,
                                  vertical: height * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      skyBlue,
                                      deepSky,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(width * 0.08),
                                    bottomRight: Radius.circular(width * 0.08),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: skyBlue.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () => Navigator.pop(context),
                                          icon: Icon(
                                            Icons.arrow_back_rounded,
                                            color: Colors.white,
                                            size: width * 0.06,
                                          ),
                                        ),
                                        Text(
                                          "Leave Request",
                                          style: TextStyle(
                                            fontSize: width * 0.05,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.06),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.01),
                                    if (empNameCtrl.text.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.04,
                                          vertical: height * 0.015,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(width * 0.03),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              color: Colors.white,
                                              size: width * 0.06,
                                            ),
                                            SizedBox(width: width * 0.03),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    empNameCtrl.text,
                                                    style: TextStyle(
                                                      fontSize: width * 0.045,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: height * 0.005),
                                                  Text(
                                                    'ID: ${empCodeCtrl.text}',
                                                    style: TextStyle(
                                                      fontSize: width * 0.035,
                                                      color: Colors.white.withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.03,
                                                vertical: height * 0.005,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(width * 0.02),
                                              ),
                                              child: Text(
                                                'Employee',
                                                style: TextStyle(
                                                  fontSize: width * 0.03,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              color: backgroundColor,
                              child: Card(
                                elevation: 0,
                                margin: EdgeInsets.all(width * 0.04),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(width * 0.05),
                                ),
                                color: cardColor,
                                child: Padding(
                                  padding: EdgeInsets.all(width * 0.04),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Select Leave Type",
                                          style: TextStyle(
                                            fontSize: width * 0.045,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                        SizedBox(height: height * 0.015),
                                        Wrap(
                                          spacing: width * 0.02,
                                          runSpacing: height * 0.01,
                                          children: leaveTypes.map((leaveType) {
                                            final isSelected = selectedLeaveType == leaveType["code"];
                                            final typeColor = leaveType["color"] as Color;
                                            return ChoiceChip(
                                              label: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    leaveType["icon"] as IconData,
                                                    size: width * 0.045,
                                                    color: isSelected ? Colors.white : typeColor,
                                                  ),
                                                  SizedBox(width: width * 0.02),
                                                  Text(
                                                    leaveType["name"]!,
                                                    style: TextStyle(
                                                      fontSize: width * 0.035,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected ? Colors.white : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                HapticFeedback.selectionClick();
                                                setState(() => selectedLeaveType = leaveType["code"]);
                                              },
                                              backgroundColor: isDarkMode ? slate : Colors.grey[200],
                                              selectedColor: typeColor,
                                              side: BorderSide(
                                                color: isSelected
                                                    ? typeColor
                                                    : isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(width * 0.025),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: width * 0.04,
                                                vertical: height * 0.012,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        SizedBox(height: height * 0.025),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "From Date",
                                                    style: TextStyle(
                                                      fontSize: width * 0.04,
                                                      fontWeight: FontWeight.w600,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  SizedBox(height: height * 0.01),
                                                  TextFormField(
                                                    controller: fromDateCtrl,
                                                    readOnly: true,
                                                    onTap: () => selectDate(fromDateCtrl),
                                                    style: TextStyle(
                                                      fontSize: width * 0.04,
                                                      color: textColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    decoration: _inputDecoration("DD-MM-YYYY", icon: Icons.calendar_month),
                                                    validator: (value) =>
                                                        value!.isEmpty ? "Please select from date" : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: width * 0.03),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "To Date",
                                                    style: TextStyle(
                                                      fontSize: width * 0.04,
                                                      fontWeight: FontWeight.w600,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  SizedBox(height: height * 0.01),
                                                  TextFormField(
                                                    controller: toDateCtrl,
                                                    readOnly: true,
                                                    onTap: () => selectDate(toDateCtrl),
                                                    style: TextStyle(
                                                      fontSize: width * 0.04,
                                                      color: textColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    decoration: _inputDecoration("DD-MM-YYYY", icon: Icons.calendar_month),
                                                    validator: (value) =>
                                                        value!.isEmpty ? "Please select to date" : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: height * 0.025),
                                        Text(
                                          "Reason for Leave",
                                          style: TextStyle(
                                            fontSize: width * 0.04,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        SizedBox(height: height * 0.01),
                                        TextFormField(
                                          controller: reasonCtrl,
                                          maxLines: 4,
                                          minLines: 3,
                                          style: TextStyle(
                                            fontSize: width * 0.04,
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: _inputDecoration(
                                            "Explain your reason...",
                                            icon: Icons.description_outlined,
                                          ),
                                          validator: (value) =>
                                              value!.isEmpty ? "Please enter reason for leave" : null,
                                        ),
                                        SizedBox(height: height * 0.025),
                                        Text(
                                          "Is it a Comp Off?",
                                          style: TextStyle(
                                            fontSize: width * 0.04,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        SizedBox(height: height * 0.01),
                                        Row(
                                          children: ["NO", "YES"].map((e) {
                                            final isSelected = compOff == e;
                                            return Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.selectionClick();
                                                  setState(() => compOff = e);
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                  margin: EdgeInsets.symmetric(horizontal: width * 0.01),
                                                  padding: EdgeInsets.symmetric(vertical: height * 0.015),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? skyBlue : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(width * 0.025),
                                                    border: Border.all(
                                                      color: skyBlue,
                                                      width: 2,
                                                    ),
                                                    boxShadow: isSelected
                                                        ? [
                                                            BoxShadow(
                                                              color: skyBlue.withOpacity(0.3),
                                                              blurRadius: 10,
                                                              spreadRadius: 2,
                                                            ),
                                                          ]
                                                        : [],
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                                                        size: width * 0.05,
                                                        color: isSelected ? Colors.white : skyBlue,
                                                      ),
                                                      SizedBox(width: width * 0.02),
                                                      Text(
                                                        e,
                                                        style: TextStyle(
                                                          fontSize: width * 0.04,
                                                          fontWeight: FontWeight.w600,
                                                          color: isSelected ? Colors.white : skyBlue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        SizedBox(height: height * 0.025),
                                        Text(
                                          "Incharge Replacement",
                                          style: TextStyle(
                                            fontSize: width * 0.04,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        SizedBox(height: height * 0.01),
                                        TextFormField(
                                          controller: inchargeCtrl,
                                          style: TextStyle(
                                            fontSize: width * 0.04,
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: _inputDecoration(
                                            "Enter person name",
                                            icon: Icons.person_add,
                                          ),
                                          validator: (value) =>
                                              value!.isEmpty ? "Please enter incharge replacement" : null,
                                        ),
                                        SizedBox(height: height * 0.04),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          width: double.infinity,
                                          height: height * 0.065,
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _submitLeave,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _isLoading
                                                  ? Colors.grey.shade400
                                                  : skyBlue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(width * 0.035),
                                              ),
                                              elevation: _isLoading ? 0 : 5,
                                              shadowColor: skyBlue.withOpacity(0.5),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                AnimatedOpacity(
                                                  opacity: _isLoading ? 0 : 1,
                                                  duration: const Duration(milliseconds: 200),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.send_rounded,
                                                        size: width * 0.05,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: width * 0.02),
                                                      Text(
                                                        "Submit Leave Application",
                                                        style: TextStyle(
                                                          fontSize: width * 0.04,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (_isLoading)
                                                  SizedBox(
                                                    width: width * 0.06,
                                                    height: width * 0.06,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      color: Colors.white,
                                                      backgroundColor: Colors.white.withOpacity(0.3),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: height * 0.02),
                                        SizedBox(
                                          width: double.infinity,
                                          height: height * 0.055,
                                          child: TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    HapticFeedback.lightImpact();
                                                    Navigator.pop(context);
                                                  },
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(width * 0.035),
                                              ),
                                              foregroundColor: subtitleColor,
                                            ),
                                            child: Text(
                                              "Cancel",
                                              style: TextStyle(
                                                fontSize: width * 0.04,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          width: double.infinity,
                                          padding: EdgeInsets.all(width * 0.04),
                                          margin: EdgeInsets.only(top: height * 0.02),
                                          decoration: BoxDecoration(
                                            color: skyBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(width * 0.03),
                                            border: Border.all(
                                              color: skyBlue.withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                size: width * 0.05,
                                                color: skyBlue,
                                              ),
                                              SizedBox(width: width * 0.03),
                                              Expanded(
                                                child: Text(
                                                  "Leave application will be sent to your manager for approval",
                                                  style: TextStyle(
                                                    fontSize: width * 0.035,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
            if (_showSuccessDialog)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: ScaleTransition(
                    scale: _bounceAnimation,
                    child: Container(
                      width: width * 0.85,
                      padding: EdgeInsets.all(width * 0.05),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(width * 0.06),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            width: width * 0.2,
                            height: width * 0.2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(color: Colors.green, width: 3),
                            ),
                            child: Icon(
                              Icons.check,
                              size: width * 0.1,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: height * 0.03),
                          Text(
                            "Success!",
                            style: TextStyle(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: height * 0.015),
                          Text(
                            _successMessage,
                            style: TextStyle(
                              fontSize: width * 0.04,
                              color: textColor,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: height * 0.03),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: SizedBox(
                              width: double.infinity,
                              height: height * 0.06,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(width * 0.03),
                                  ),
                                ),
                                onPressed: _navigateToDashboard,
                                child: Text(
                                  "Go to Dashboard",
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          TextButton(
                            onPressed: _closeDialogs,
                            child: Text(
                              "Apply Another Leave",
                              style: TextStyle(
                                color: skyBlue,
                                fontSize: width * 0.038,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showErrorDialog)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: ScaleTransition(
                    scale: _bounceAnimation,
                    child: Container(
                      width: width * 0.85,
                      padding: EdgeInsets.all(width * 0.05),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(width * 0.06),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            width: width * 0.2,
                            height: width * 0.2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red, width: 3),
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: width * 0.1,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: height * 0.03),
                          Text(
                            "Error",
                            style: TextStyle(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: height * 0.015),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: width * 0.04,
                              color: textColor,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: height * 0.03),
                          SizedBox(
                            width: double.infinity,
                            height: height * 0.06,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(width * 0.03),
                                ),
                              ),
                              onPressed: _closeDialogs,
                              child: Text(
                                "Try Again",
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          TextButton(
                            onPressed: _closeDialogs,
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: width * 0.038,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}