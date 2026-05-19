// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:flutter/services.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
      duration: const Duration(milliseconds: 1000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: screenWidth * 0.85,
            padding: EdgeInsets.all(screenWidth * 0.06),
            decoration: BoxDecoration(
              color: isDarkMode ? slate : pureWhite,
              borderRadius: BorderRadius.circular(screenWidth * 0.06),
              border: Border.all(color: skyBlue.withOpacity(0.3), width: 2),
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
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, value, __) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: skyBlue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: screenWidth * 0.05),
                Text(
                  "Check your mail!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? pureWhite : charcoal,
                  ),
                ),
                SizedBox(height: screenWidth * 0.03),
                Text(
                  "A password reset link has been sent to your registered email address.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: screenWidth * 0.06),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _emailController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skyBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.035,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      elevation: 5,
                      shadowColor: skyBlue.withOpacity(0.4),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: screenWidth * 0.85,
            padding: EdgeInsets.all(screenWidth * 0.06),
            decoration: BoxDecoration(
              color: isDarkMode ? slate : pureWhite,
              borderRadius: BorderRadius.circular(screenWidth * 0.06),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
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
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                SizedBox(height: screenWidth * 0.05),
                Text(
                  "Something went wrong",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? pureWhite : charcoal,
                  ),
                ),
                SizedBox(height: screenWidth * 0.03),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: screenWidth * 0.06),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.035,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      elevation: 5,
                      shadowColor: Colors.red.withOpacity(0.4),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final auth = AuthService();
      await auth.forgotPassword(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSuccessDialog();
      // ✅ BAAD MEIN
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final rawMsg = e
          .toString()
          .replaceAll("Exception:", "")
          .trim()
          .toLowerCase();

      final displayMsg =
          (rawMsg.contains("socket") ||
              rawMsg.contains("connection") ||
              rawMsg.contains("network") ||
              rawMsg.contains("internet") ||
              rawMsg.contains("host lookup") ||
              rawMsg.contains("failed host"))
          ? "No internet connection. Please check your network."
          : "Something went wrong. Please try again.";

      _showErrorDialog(displayMsg); // ✅ clean message
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final surfaceColor = isDarkMode ? slate.withOpacity(0.5) : pureWhite;
    final textColor = isDarkMode ? pureWhite : charcoal;
    final subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final inputBgColor = isDarkMode ? slate.withOpacity(0.5) : pureWhite;
    final borderColor = isDarkMode ? slate : Colors.grey[300]!;

    double responsiveFontSize(double baseSize) {
      return baseSize * (screenWidth / 375);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: gradientColors.first,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: FadeTransition(
                          opacity: _fadeInAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
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
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                          size: screenWidth * 0.05,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),

                                    ScaleTransition(
                                      scale: _scaleAnimation,
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
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      screenWidth * 0.02,
                                                    ),
                                              ),
                                              child: Image.asset(
                                                "assets/images/app_icon.png",
                                                width: screenWidth * 0.08,
                                                color: Colors.white,
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
                                                    fontSize:
                                                        responsiveFontSize(16),
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
                                                    fontSize:
                                                        responsiveFontSize(16),
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
                                  ],
                                ),

                                SizedBox(height: screenHeight * 0.03),

                                TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  builder: (context, double value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Reset Password",
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(28),
                                              fontWeight: FontWeight.w800,
                                              color: textColor,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            height: screenHeight * 0.005,
                                          ),
                                          Text(
                                            "Enter your email to receive reset instructions",
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(14),
                                              color: subtitleColor,
                                              letterSpacing: 0.3,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                SizedBox(height: screenHeight * 0.04),

                                TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  builder: (context, double value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.04,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: skyBlue.withOpacity(0.1),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(16),
                                              fontWeight: FontWeight.w500,
                                              color: textColor,
                                            ),
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              labelText: "Email address",
                                              labelStyle: TextStyle(
                                                fontSize: responsiveFontSize(
                                                  14,
                                                ),
                                                color: subtitleColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              floatingLabelStyle: TextStyle(
                                                color: skyBlue,
                                                fontWeight: FontWeight.w600,
                                                fontSize: responsiveFontSize(
                                                  14,
                                                ),
                                              ),
                                              prefixIcon: Container(
                                                padding: EdgeInsets.all(
                                                  screenWidth * 0.02,
                                                ),
                                                child: Icon(
                                                  Icons.email_rounded,
                                                  size: responsiveFontSize(20),
                                                  color: skyBlue,
                                                ),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      screenWidth * 0.04,
                                                    ),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      screenWidth * 0.04,
                                                    ),
                                                borderSide: BorderSide(
                                                  color: borderColor,
                                                  width: 1.5,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      screenWidth * 0.04,
                                                    ),
                                                borderSide: BorderSide(
                                                  color: skyBlue,
                                                  width: 2,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: inputBgColor,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal:
                                                        screenWidth * 0.04,
                                                    vertical:
                                                        screenHeight * 0.015,
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return "Email required";
                                              }
                                              if (!RegExp(
                                                r'^[a-zA-Z0-9._%+-]+@ppecon\.com$',
                                              ).hasMatch(value)) {
                                                return "Only @ppecon.com emails are allowed";
                                              }
                                              return null;
                                            },
                                          ),
                                        ),

                                        SizedBox(height: screenHeight * 0.03),

                                        Container(
                                          padding: EdgeInsets.all(
                                            screenWidth * 0.04,
                                          ),
                                          decoration: BoxDecoration(
                                            color: skyBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              screenWidth * 0.04,
                                            ),
                                            border: Border.all(
                                              color: skyBlue.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: skyBlue.withOpacity(
                                                    0.2,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.info_outline_rounded,
                                                  color: skyBlue,
                                                  size: screenWidth * 0.05,
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.03,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  "We'll send a password reset link to your email. Please check your inbox.",
                                                  style: TextStyle(
                                                    fontSize:
                                                        responsiveFontSize(12),
                                                    color: skyBlue,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.4,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(height: screenHeight * 0.04),

                                        TweenAnimationBuilder(
                                          tween: Tween<double>(
                                            begin: 0,
                                            end: 1,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          curve: Curves.elasticOut,
                                          builder: (context, double value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _submit,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical:
                                                                  screenHeight *
                                                                  0.018,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                screenWidth *
                                                                    0.04,
                                                              ),
                                                        ),
                                                        elevation: 0,
                                                      ).copyWith(
                                                        backgroundColor:
                                                            WidgetStateProperty.all(
                                                              Colors
                                                                  .transparent,
                                                            ),
                                                      ),
                                                  child: Ink(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: gradientColors,
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            screenWidth * 0.04,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: skyBlue
                                                              .withOpacity(0.3),
                                                          blurRadius: 25,
                                                          spreadRadius: 5,
                                                          offset: const Offset(
                                                            0,
                                                            10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical:
                                                                screenHeight *
                                                                0.018,
                                                          ),
                                                      child: Center(
                                                        child: _isLoading
                                                            ? SizedBox(
                                                                height:
                                                                    screenHeight *
                                                                    0.025,
                                                                width:
                                                                    screenHeight *
                                                                    0.025,
                                                                child: const CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2.5,
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<
                                                                        Color
                                                                      >(
                                                                        Colors
                                                                            .white,
                                                                      ),
                                                                ),
                                                              )
                                                            : Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Container(
                                                                    padding: EdgeInsets.all(
                                                                      screenWidth *
                                                                          0.01,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.2,
                                                                          ),
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .send_rounded,
                                                                      size:
                                                                          responsiveFontSize(
                                                                            18,
                                                                          ),
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width:
                                                                        screenWidth *
                                                                        0.02,
                                                                  ),
                                                                  Text(
                                                                    "Send Reset Link",
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          responsiveFontSize(
                                                                            16,
                                                                          ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Colors
                                                                          .white,
                                                                      letterSpacing:
                                                                          0.5,
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
                                          },
                                        ),

                                        SizedBox(height: screenHeight * 0.02),

                                        TweenAnimationBuilder(
                                          tween: Tween<double>(
                                            begin: 0,
                                            end: 1,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          curve: Curves.easeOut,
                                          builder:
                                              (context, double value, child) {
                                                return Opacity(opacity: value);
                                              },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: screenHeight * 0.02),

                                TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  builder: (context, double value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Container(
                                                  height: 1,
                                                  width: screenWidth * 0.2,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        skyBlue.withOpacity(
                                                          0.3,
                                                        ),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      screenWidth * 0.03,
                                                ),
                                                child: Text(
                                                  "Powered by",
                                                  style: TextStyle(
                                                    fontSize:
                                                        responsiveFontSize(11),
                                                    color: subtitleColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: Container(
                                                  height: 1,
                                                  width: screenWidth * 0.2,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        skyBlue.withOpacity(
                                                          0.3,
                                                        ),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: screenHeight * 0.01),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "Pioneer.",
                                                  style: TextStyle(
                                                    fontSize:
                                                        responsiveFontSize(13),
                                                    color: subtitleColor,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "Tech",
                                                  style: TextStyle(
                                                    fontSize:
                                                        responsiveFontSize(13),
                                                    color: skyBlue,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
