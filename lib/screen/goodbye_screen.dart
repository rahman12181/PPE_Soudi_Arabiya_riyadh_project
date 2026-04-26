// lib/screens/goodbye_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:management_app/screen/login_screen.dart';

class GoodbyeScreen extends StatefulWidget {
  const GoodbyeScreen({super.key});

  @override
  State<GoodbyeScreen> createState() => _GoodbyeScreenState();
}

class _GoodbyeScreenState extends State<GoodbyeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  // Sky Blue Color Palette - Matching other screens
  static const Color skyBlue = Color(0xFF87CEEB); // Sky blue primary
  static const Color lightSky = Color(0xFFE0F2FE); // Very light sky
  static const Color mediumSky = Color(0xFF7EC8E0); // Medium sky
  static const Color deepSky = Color(0xFF00A5E0); // Deep sky for accents
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);

  // Get header gradient colors based on theme
  List<Color> _getHeaderGradientColors(bool isDarkMode) {
    return isDarkMode
        ? [charcoal, slate, const Color(0xFF1E1E2E)]
        : [skyBlue, mediumSky, deepSky];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    double responsiveWidth(double percentage) => screenWidth * percentage;
    double responsiveHeight(double percentage) => screenHeight * percentage;
    double responsiveFontSize(double baseSize) => baseSize * (screenWidth / 375);

    // Color scheme with Sky Blue theme
    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final surfaceColor = isDarkMode ? slate.withOpacity(0.5) : pureWhite;
    final textColor = isDarkMode ? pureWhite : charcoal;
    final subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: gradientColors.first,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: gradientColors.map((c) => c.withOpacity(0.05)).toList(),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Decorative Background Elements with Sky Blue Theme
                Positioned(
                  top: -screenHeight * 0.1,
                  right: -screenWidth * 0.2,
                  child: Container(
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          skyBlue.withOpacity(0.2),
                          skyBlue.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -screenHeight * 0.1,
                  left: -screenWidth * 0.2,
                  child: Container(
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          deepSky.withOpacity(0.15),
                          deepSky.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: responsiveWidth(0.06),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Logo with Wave
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer Glow with Sky Blue
                                    TweenAnimationBuilder(
                                      tween: Tween<double>(begin: 0.8, end: 1.2),
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOut,
                                      builder: (context, double value, child) {
                                        return Container(
                                          width: responsiveWidth(0.45) * value,
                                          height: responsiveWidth(0.45) * value,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                skyBlue.withOpacity(0.15),
                                                skyBlue.withOpacity(0.05),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    
                                    // Main Logo Container with Sky Blue Gradient
                                    ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: RotationTransition(
                                        turns: _rotateAnimation,
                                        child: Container(
                                          width: responsiveWidth(0.35),
                                          height: responsiveWidth(0.35),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: gradientColors,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: skyBlue.withOpacity(0.3),
                                                blurRadius: 30,
                                                spreadRadius: 5,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              "assets/images/app_icon.png",
                                              width: responsiveWidth(0.2),
                                              height: responsiveWidth(0.2),
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsiveHeight(0.03)),
                                
                                // Company Name with Sky Blue Gradient
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    "PIONEER TECH",
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(32),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: responsiveHeight(0.005)),
                                
                                // Tagline with Sky Blue Theme
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsiveWidth(0.04),
                                    vertical: responsiveHeight(0.005),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: skyBlue.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "INNOVATION • EXCELLENCE • TRUST",
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(12),
                                      letterSpacing: 2,
                                      color: skyBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: responsiveHeight(0.06)),

                        // Goodbye Message Card with Sky Blue Theme
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              padding: EdgeInsets.all(responsiveWidth(0.06)),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(responsiveWidth(0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: skyBlue.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: skyBlue.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Animated Wave Icon with Sky Blue
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 1.0, end: 1.2),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      padding: EdgeInsets.all(responsiveWidth(0.04)),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: gradientColors,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: skyBlue.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.waving_hand_rounded,
                                        size: responsiveWidth(0.12),
                                        color: Colors.white,
                                      ),
                                    ),
                                    builder: (context, double value, Widget? child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                  ),
                                  SizedBox(height: responsiveHeight(0.02)),
                                  
                                  Text(
                                    "Goodbye!",
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(28),
                                      fontWeight: FontWeight.w800,
                                      foreground: Paint()
                                        ..shader = LinearGradient(
                                          colors: gradientColors,
                                        ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                                    ),
                                  ),
                                  SizedBox(height: responsiveHeight(0.015)),
                                  
                                  Text(
                                    "You have been successfully logged out.\nThank you for spending time with us today.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(15),
                                      color: subtitleColor,
                                      height: 1.5,
                                    ),
                                  ),

                                  SizedBox(height: responsiveHeight(0.02)),

                                  // Time of logout with Sky Blue Theme
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsiveWidth(0.04),
                                      vertical: responsiveHeight(0.008),
                                    ),
                                    decoration: BoxDecoration(
                                      color: skyBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: skyBlue.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: responsiveWidth(0.04),
                                          color: skyBlue,
                                        ),
                                        SizedBox(width: responsiveWidth(0.02)),
                                        Text(
                                          "Logged out at ${_getCurrentTime()}",
                                          style: TextStyle(
                                            fontSize: responsiveFontSize(13),
                                            color: skyBlue,
                                            fontWeight: FontWeight.w600,
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

                        SizedBox(height: responsiveHeight(0.04)),

                        // Action Buttons
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Text(
                                  "See you again soon!",
                                  style: TextStyle(
                                    fontSize: responsiveFontSize(16),
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: responsiveHeight(0.02)),
                                
                                // Login Button with Sky Blue Gradient
                                Container(
                                  width: double.infinity,
                                  height: responsiveHeight(0.07),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                    ),
                                    borderRadius: BorderRadius.circular(responsiveWidth(0.03)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: skyBlue.withOpacity(0.3),
                                        blurRadius: 25,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(responsiveWidth(0.03)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(responsiveWidth(0.01)),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.login_rounded,
                                            size: responsiveWidth(0.06),
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: responsiveWidth(0.02)),
                                        Text(
                                          "Login Again",
                                          style: TextStyle(
                                            fontSize: responsiveFontSize(18),
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: responsiveHeight(0.015)),

                                // Exit Button with Sky Blue Theme
                                TextButton.icon(
                                  onPressed: () => _showExitDialog(context, screenWidth, gradientColors),
                                  icon: Icon(
                                    Icons.exit_to_app_rounded,
                                    size: responsiveWidth(0.05),
                                    color: skyBlue,
                                  ),
                                  label: Text(
                                    "Exit Application",
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(15),
                                      color: skyBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsiveWidth(0.06),
                                      vertical: responsiveHeight(0.015),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: responsiveHeight(0.03)),

                        // Footer with Sky Blue Theme
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                "© 2026 Pioneer Tech. All rights reserved.",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(11),
                                  color: subtitleColor.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(height: responsiveHeight(0.005)),
                              Text(
                                "Version 2.0.0",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(10),
                                  color: subtitleColor.withOpacity(0.6),
                                ),
                              ),
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
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showExitDialog(BuildContext context, double screenWidth, List<Color> gradientColors) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: screenWidth * 0.85,
          padding: EdgeInsets.all(screenWidth * 0.05),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.06),
            border: Border.all(
              color: skyBlue.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: skyBlue.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: skyBlue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.exit_to_app_rounded,
                  size: screenWidth * 0.1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                "Exit Application?",
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: gradientColors,
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                "Are you sure you want to close the application?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
              SizedBox(height: screenWidth * 0.06),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.035,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.withOpacity(0.1),
                                Colors.grey.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Stay",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          SystemNavigator.pop();
                        },
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.035,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            boxShadow: [
                              BoxShadow(
                                color: skyBlue.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Exit",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}