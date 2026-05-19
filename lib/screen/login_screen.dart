// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:management_app/providers/employee_provider.dart';
import 'package:management_app/providers/profile_provider.dart';
import 'package:management_app/screen/setting_screen.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:management_app/utils/checkuser_util.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isloading = false;
  bool _isPasswordVisible = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Sky Blue Color Palette - Matching HomemainScreen
  static const Color skyBlue = Color(0xFF87CEEB); // Sky blue primary
  static const Color lightSky = Color(0xFFE0F2FE); // Very light sky
  static const Color mediumSky = Color(0xFF7EC8E0); // Medium sky
  static const Color deepSky = Color(0xFF00A5E0); // Deep sky for accents
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);

  // Get header gradient colors based on theme (matching homemain)
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
      duration: const Duration(milliseconds: 1200),
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
    _passwordController.dispose();
    super.dispose();
  }

  // ================= PREMIUM ERROR DIALOG =================
  void _showErrorDialog(BuildContext context, String title, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: screenWidth * 0.8,
          padding: EdgeInsets.all(screenWidth * 0.05),
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
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.08,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? pureWhite : charcoal,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                message,
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenWidth * 0.05),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "OK",
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
            ],
          ),
        ),
      ),
    );
  }

  // ================= PREMIUM SUCCESS DIALOG =================
  void _showSuccessDialog(String fullName) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(dialogContext);
            Navigator.pushReplacementNamed(context, "/homeScreen");
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: screenWidth * 0.8,
            padding: EdgeInsets.all(screenWidth * 0.05),
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
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: skyBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: skyBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                Text(
                  "Success",
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? pureWhite : charcoal,
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  "Welcome, $fullName!",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03),
                SizedBox(
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.1,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(skyBlue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    EdgeInsets screenPadding = MediaQuery.of(context).padding;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    double textScaleFactor = MediaQuery.of(context).textScaleFactor;

    double responsiveFontSize(double baseSize) {
      return (baseSize * (screenWidth / 375)) *
          (1 / textScaleFactor.clamp(0.8, 1.2));
    }

    double responsiveHeight(double percentage) {
      final safeHeight =
          screenHeight - screenPadding.top - screenPadding.bottom;
      return safeHeight * percentage;
    }

    double responsiveWidth(double percentage) {
      return screenWidth * percentage;
    }

    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final textColor = isDarkMode ? pureWhite : charcoal;
    final hintTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDarkMode ? slate : Colors.grey[300]!;
    final focusedBorderColor = skyBlue;

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
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsiveWidth(0.053),
                screenPadding.top + 15,
                responsiveWidth(0.053),
                20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              // Premium Logo Section with Sky Blue Theme
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        responsiveWidth(0.02),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradientColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.03),
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
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(
                                              responsiveWidth(0.015),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    responsiveWidth(0.02),
                                                  ),
                                            ),
                                            child: Image.asset(
                                              "assets/images/app_icon.png",
                                              width: responsiveWidth(0.08),
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(
                                            width: responsiveWidth(0.02),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "PIONEER",
                                                style: TextStyle(
                                                  fontSize: responsiveFontSize(
                                                    16,
                                                  ),
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
                                                  fontSize: responsiveFontSize(
                                                    16,
                                                  ),
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
                                  ],
                                ),
                              ),

                              SizedBox(height: responsiveHeight(0.05)),

                              // Premium Welcome Text with Sky Blue Theme
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, double value, child) {
                                  return Opacity(opacity: value, child: child);
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Welcome back!",
                                        style: TextStyle(
                                          fontSize: responsiveFontSize(32),
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: responsiveHeight(0.005)),
                                      Text(
                                        "Enter your login credentials",
                                        style: TextStyle(
                                          fontSize: responsiveFontSize(14),
                                          color: hintTextColor,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: responsiveHeight(0.07)),

                              // Premium Email Field with Sky Blue Theme
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      responsiveWidth(0.04),
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
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: responsiveFontSize(16),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: responsiveWidth(0.04),
                                        vertical: responsiveHeight(0.015),
                                      ),
                                      labelText: "Email address",
                                      labelStyle: TextStyle(
                                        fontSize: responsiveFontSize(14),
                                        color: hintTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      floatingLabelStyle: TextStyle(
                                        color: focusedBorderColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: responsiveFontSize(14),
                                      ),
                                      prefixIcon: Container(
                                        padding: EdgeInsets.all(
                                          responsiveWidth(0.02),
                                        ),
                                        child: Icon(
                                          Icons.email_rounded,
                                          size: responsiveFontSize(20),
                                          color: focusedBorderColor,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
                                        ),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
                                        ),
                                        borderSide: BorderSide(
                                          color: focusedBorderColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? slate.withOpacity(0.5)
                                          : pureWhite,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Email required";
                                      }
                                      // Simple email format check (must contain @)
                                      if (!value.contains('@')) {
                                        return "Enter a valid email address";
                                      }
                                      // No domain restriction anymore
                                      return null;
                                    },
                                  ),
                                ),
                              ),

                              SizedBox(height: responsiveHeight(0.042)),

                              // Premium Password Field with Sky Blue Theme
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      responsiveWidth(0.04),
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
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: responsiveFontSize(16),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: responsiveWidth(0.04),
                                        vertical: responsiveHeight(0.015),
                                      ),
                                      labelText: "Password",
                                      labelStyle: TextStyle(
                                        fontSize: responsiveFontSize(14),
                                        color: hintTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      floatingLabelStyle: TextStyle(
                                        color: focusedBorderColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: responsiveFontSize(14),
                                      ),
                                      prefixIcon: Container(
                                        padding: EdgeInsets.all(
                                          responsiveWidth(0.02),
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          size: responsiveFontSize(20),
                                          color: focusedBorderColor,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color: hintTextColor,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
                                        ),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
                                        ),
                                        borderSide: BorderSide(
                                          color: focusedBorderColor,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? slate.withOpacity(0.5)
                                          : pureWhite,
                                    ),
                                    validator: (value) =>
                                        (value == null || value.isEmpty)
                                        ? "Password required"
                                        : null,
                                  ),
                                ),
                              ),

                              SizedBox(height: responsiveHeight(0.02)),

                              // Premium Forgot Password with Sky Blue Theme
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                builder: (context, double value, child) {
                                  return Opacity(opacity: value, child: child);
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushNamed(
                                      context,
                                      "/forgotpasswordScreen",
                                    );
                                  },
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: responsiveHeight(0.005),
                                        horizontal: responsiveWidth(0.02),
                                      ),
                                      decoration: BoxDecoration(
                                        color: skyBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "Forgot password?",
                                        style: TextStyle(
                                          fontSize: responsiveFontSize(14),
                                          fontWeight: FontWeight.w600,
                                          color: skyBlue,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: responsiveHeight(0.04)),

                              // ========== PREMIUM LOGIN BUTTON with Sky Blue Theme ==========
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.elasticOut,
                                builder: (context, double value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isloading
                                        ? null
                                        : () async {
                                            HapticFeedback.mediumImpact();
                                            if (!_formKey.currentState!
                                                .validate()) {
                                              return;
                                            }
                                            setState(() => _isloading = true);

                                            try {
                                              final auth = AuthService();
                                              final response = await auth
                                                  .loginUser(
                                                    email: _emailController.text
                                                        .trim(),
                                                    password:
                                                        _passwordController.text
                                                            .trim(),
                                                  );

                                              print(
                                                "📱 Login Screen Response: $response",
                                              );

                                              if (response["success"] == true) {
                                                final prefs =
                                                    await SharedPreferences.getInstance();
                                                await prefs.setString(
                                                  'userEmail',
                                                  _emailController.text.trim(),
                                                );
                                                print(
                                                  "✅ User Email saved: ${_emailController.text.trim()}",
                                                );

                                                // 🔥 CLEAR OLD CACHE
                                                final profileProvider =
                                                    Provider.of<
                                                      ProfileProvider
                                                    >(context, listen: false);
                                                await profileProvider
                                                    .clearProfileCache();

                                                String? sid = response["sid"];
                                                List<String> cookies =
                                                    response["cookies"] ?? [];
                                                String email =
                                                    response["email"] ??
                                                    _emailController.text
                                                        .trim();
                                                String fullName =
                                                    response["full_name"] ??
                                                    email.split('@')[0];

                                                await CheckuserUtils.saveloginStatus(
                                                  route: "/homeScreen",
                                                  employeeId: "",
                                                  userName: fullName,
                                                  authToken: sid,
                                                  cookies: cookies,
                                                );

                                                // 🔥 Load profile
                                                try {
                                                  final profileProvider =
                                                      Provider.of<
                                                        ProfileProvider
                                                      >(context, listen: false);
                                                  await profileProvider
                                                      .loadProfile();
                                                } catch (e) {
                                                  print(
                                                    "Profile load error: $e",
                                                  );
                                                }

                                                // 🔥 Fetch employee ID
                                                try {
                                                  if (email.isNotEmpty) {
                                                    await Provider.of<
                                                          EmployeeProvider
                                                        >(
                                                          context,
                                                          listen: false,
                                                        )
                                                        .fetchAndSaveEmployeeId(
                                                          email,
                                                        );
                                                  }
                                                } catch (e) {
                                                  print(
                                                    "Employee fetch error: $e",
                                                  );
                                                }

                                                setState(
                                                  () => _isloading = false,
                                                );

                                                // 🔥 Show premium success dialog
                                                _showSuccessDialog(fullName);
                                              } else {
                                                setState(
                                                  () => _isloading = false,
                                                );

                                                String errorMsg =
                                                    response["message"] ??
                                                    "Login failed";

                                                // ✅ NETWORK ERROR CHECK - YAHI PE FIX KARNA HAI
                                                final errorMsgLower = errorMsg
                                                    .toLowerCase();
                                                final isNetworkError =
                                                    errorMsgLower.contains(
                                                      "socket",
                                                    ) ||
                                                    errorMsgLower.contains(
                                                      "connection",
                                                    ) ||
                                                    errorMsgLower.contains(
                                                      "network",
                                                    ) ||
                                                    errorMsgLower.contains(
                                                      "internet",
                                                    ) ||
                                                    errorMsgLower.contains(
                                                      "timeout",
                                                    ) ||
                                                    errorMsgLower.contains(
                                                      "failed to fetch",
                                                    ) ||
                                                    errorMsgLower.contains(
                                                      "host lookup",
                                                    ) ||
                                                    errorMsgLower.contains(
                                                      "unable to connect",
                                                    );

                                                if (isNetworkError) {
                                                  _showErrorDialog(
                                                    context,
                                                    "No Internet Connection",
                                                    "Please check your network and try again.", // ✅ CLEAN MESSAGE
                                                  );
                                                } else if (errorMsg.contains(
                                                  "User not found",
                                                )) {
                                                  _showErrorDialog(
                                                    context,
                                                    "Login Failed",
                                                    "User not found!",
                                                  );
                                                } else if (errorMsg.contains(
                                                  "Incorrect password",
                                                )) {
                                                  _showErrorDialog(
                                                    context,
                                                    "Invalid Credentials",
                                                    "Incorrect password.",
                                                  );
                                                } else {
                                                  _showErrorDialog(
                                                    context,
                                                    "Login Failed",
                                                    "Something went wrong. Please try again.",
                                                  ); // ✅ GENERIC MESSAGE
                                                }
                                              }
                                              // ✅ BAAD MEIN
                                            } catch (e) {
                                              setState(
                                                () => _isloading = false,
                                              );

                                              final rawMsg = e
                                                  .toString()
                                                  .toLowerCase();
                                              final displayMsg =
                                                  (rawMsg.contains("socket") ||
                                                      rawMsg.contains(
                                                        "connection",
                                                      ) ||
                                                      rawMsg.contains(
                                                        "network",
                                                      ) ||
                                                      rawMsg.contains(
                                                        "internet",
                                                      ) ||
                                                      rawMsg.contains(
                                                        "host lookup",
                                                      ) ||
                                                      rawMsg.contains(
                                                        "failed host",
                                                      ))
                                                  ? "No internet connection. Please check your network."
                                                  : "Something went wrong. Please try again.";

                                              _showErrorDialog(
                                                context,
                                                "Error",
                                                displayMsg, // ✅ clean message
                                              );
                                            }
                                          },
                                    borderRadius: BorderRadius.circular(
                                      responsiveWidth(0.04),
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: responsiveHeight(0.02),
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradientColors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
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
                                      child: Center(
                                        child: _isloading
                                            ? SizedBox(
                                                height: responsiveHeight(0.03),
                                                width: responsiveHeight(0.03),
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(
                                                      responsiveWidth(0.01),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.login_rounded,
                                                      size: responsiveFontSize(
                                                        20,
                                                      ),
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: responsiveWidth(
                                                      0.02,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Login",
                                                    style: TextStyle(
                                                      fontSize:
                                                          responsiveFontSize(
                                                            18,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: responsiveHeight(0.1)),

                              // Premium Footer with Sky Blue Theme
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                builder: (context, double value, child) {
                                  return Opacity(opacity: value, child: child);
                                },
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Container(
                                            height: 1,
                                            width: responsiveWidth(0.133),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  skyBlue.withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: responsiveWidth(0.032),
                                          ),
                                          child: Text(
                                            "Powered by",
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(12),
                                              letterSpacing: 0.5,
                                              color: hintTextColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Container(
                                            height: 1,
                                            width: responsiveWidth(0.133),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  skyBlue.withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: responsiveHeight(0.02)),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Pioneer.",
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(16),
                                              color: textColor,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "Tech",
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(16),
                                              color: skyBlue,
                                              fontWeight: FontWeight.w700,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
