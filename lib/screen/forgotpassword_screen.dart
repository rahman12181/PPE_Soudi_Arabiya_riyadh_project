// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:management_app/screen/login_screen.dart';
import 'package:management_app/services/auth_service.dart';

class ForgotpasswordScreen extends StatefulWidget {
  const ForgotpasswordScreen({super.key});

  @override
  State<ForgotpasswordScreen> createState() => _ForgotpasswordScreenState();
}

class _ForgotpasswordScreenState extends State<ForgotpasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isloading = false;
  final TextEditingController _emailController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sky Blue Color Palette - Matching HomemainScreen and LoginScreen
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    
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
              child: Icon(
                color == Colors.green
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent multiple submissions
    if (_isloading) return;

    setState(() => _isloading = true);

    try {
      final auth = AuthService();
      final message = await auth.forgotPassword(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isloading = false);
      _showSnackbar(message, Colors.green);

      // Clear email after success
      _emailController.clear();

      // Optional: Navigate to login after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isloading = false);
      _showSnackbar(e.toString(), Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    // Production-level safe padding calculations
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.02;
    final topOffset = 60.0; // Fixed 60px from top

    // Color scheme with Sky Blue theme
    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final surfaceColor = isDarkMode ? slate.withOpacity(0.5) : pureWhite;
    final textColor = isDarkMode ? pureWhite : charcoal;
    final subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final inputBgColor = isDarkMode ? slate.withOpacity(0.5) : pureWhite;
    final borderColor = isDarkMode ? slate : Colors.grey[300]!;

    return Scaffold(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.zero, // Remove default padding
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: topOffset, // 60px from top
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: verticalPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Animated Header
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  // Back Button and Logo Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Back Button with proper touch target
                                      Semantics(
                                        button: true,
                                        label: 'Go back',
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: gradientColors,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: skyBlue.withOpacity(0.3),
                                                blurRadius: 15,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => Navigator.pop(context),
                                              borderRadius: BorderRadius.circular(
                                                screenWidth * 0.1,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                  screenWidth * 0.02,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_back_ios_new_rounded,
                                                  color: Colors.white,
                                                  size: screenWidth * 0.05,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Premium Logo with Sky Blue Theme
                                      Semantics(
                                        label: 'Pioneer Tech Logo',
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            screenWidth * 0.02,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: gradientColors,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.03,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: skyBlue.withOpacity(0.3),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(
                                                  screenWidth * 0.015,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(
                                                    screenWidth * 0.02,
                                                  ),
                                                ),
                                                child: Image.asset(
                                                  "assets/images/app_icon.png",
                                                  width: screenWidth * 0.08,
                                                  color: Colors.white,
                                                  errorBuilder: (
                                                    context, error, stackTrace,
                                                  ) {
                                                    return Icon(
                                                      Icons.apps_rounded,
                                                      color: Colors.white,
                                                      size: screenWidth * 0.08,
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: screenWidth * 0.02),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "PIONEER",
                                                    style: TextStyle(
                                                      fontSize: screenWidth * 0.04,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 2,
                                                      height: 1.0,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          blurRadius: 10,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    "TECH",
                                                    style: TextStyle(
                                                      fontSize: screenWidth * 0.04,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.white,
                                                      letterSpacing: 2,
                                                      height: 1.0,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          blurRadius: 10,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // Empty SizedBox for balance
                                      SizedBox(width: screenWidth * 0.1),
                                    ],
                                  ),

                                  SizedBox(height: screenHeight * 0.04),

                                  // Title and Subtitle
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.07,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                            letterSpacing: -0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: screenHeight * 0.015),
                                        Text(
                                          "Don't worry! It happens. Please enter your\nregistered email address to reset your password",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: subtitleColor,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.05),

                          // Animated Form
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.06),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.05,
                                  ),
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
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Email Field with Sky Blue Theme
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Email Address",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.038,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.012),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: inputBgColor,
                                              borderRadius: BorderRadius.circular(
                                                screenWidth * 0.04,
                                              ),
                                              border: Border.all(
                                                color: borderColor,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: skyBlue.withOpacity(0.1),
                                                  blurRadius: 15,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: TextFormField(
                                              controller: _emailController,
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.04,
                                                color: textColor,
                                              ),
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction: TextInputAction.done,
                                              onFieldSubmitted: (_) =>
                                                  _handleForgotPassword(),
                                              enabled: !_isloading,
                                              decoration: InputDecoration(
                                                hintText: "Enter your email",
                                                hintStyle: TextStyle(
                                                  fontSize: screenWidth * 0.035,
                                                  color:
                                                      subtitleColor.withOpacity(0.7),
                                                ),
                                                prefixIcon: Container(
                                                  padding: EdgeInsets.all(
                                                    screenWidth * 0.025,
                                                  ),
                                                  child: Icon(
                                                    Icons.email_outlined,
                                                    color: skyBlue,
                                                    size: screenWidth * 0.05,
                                                  ),
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: screenHeight * 0.015,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return "Email is required";
                                                }
                                                if (!RegExp(
                                                  r'^[a-zA-Z0-9._%+-]+@ppecon\.com$',
                                                ).hasMatch(value)) {
                                                  return "Please use your @ppecon.com email";
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: screenHeight * 0.035),

                                      // Continue Button with Sky Blue Theme
                                      Semantics(
                                        button: true,
                                        label: _isloading
                                            ? 'Sending reset link'
                                            : 'Send reset link',
                                        child: Container(
                                          width: double.infinity,
                                          height: screenHeight * 0.06,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: gradientColors,
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.04,
                                            ),
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
                                            onPressed:
                                                _isloading ? null : _handleForgotPassword,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                  screenWidth * 0.04,
                                                ),
                                              ),
                                            ),
                                            child: _isloading
                                                ? SizedBox(
                                                    height: screenHeight * 0.03,
                                                    width: screenHeight * 0.03,
                                                    child:
                                                        const CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                          screenWidth * 0.01,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.send_rounded,
                                                          size: screenWidth * 0.05,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: screenWidth * 0.02,
                                                      ),
                                                      Text(
                                                        "SEND RESET LINK",
                                                        style: TextStyle(
                                                          fontSize:
                                                              screenWidth * 0.04,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
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

                          SizedBox(height: screenHeight * 0.04),

                          // Login Link with Sky Blue Theme
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenHeight * 0.02,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.04,
                                ),
                                border: Border.all(
                                  color: skyBlue.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: skyBlue.withOpacity(0.05),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Remember your password? ",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Sign In",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.038,
                                        fontWeight: FontWeight.w700,
                                        color: skyBlue,
                                        decoration: TextDecoration.underline,
                                        decorationColor: skyBlue.withOpacity(0.3),
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginScreen(),
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          // Info Text with Sky Blue Theme
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: skyBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.security_rounded,
                                    size: screenWidth * 0.03,
                                    color: skyBlue,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  "We'll send a reset link to your email",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
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
              );
            },
          ),
        ),
      ),
    );
  }
}