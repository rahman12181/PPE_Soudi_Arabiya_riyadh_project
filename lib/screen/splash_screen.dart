// ignore_for_file: deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:management_app/utils/checkuser_util.dart';
import 'package:management_app/utils/systembars_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  String fullText = "Pioneer Tech";
  String displayedText = "";

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _bgOpacityAnimation;
  late Animation<Color?> _bgColorAnimation;
  late Animation<Color?> _textColorAnimation;
  late Animation<double> _pulseAnimation;

  late bool _isDarkMode;
  late Color _darkBgColor;
  late Color _lightBgColor;
  late Color _darkTextColor;
  late Color _lightTextColor;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystembarUtil.setSystemBar(context);
    });

    _isDarkMode = false;
    _darkBgColor = Colors.grey[900]!;
    _lightBgColor = Colors.white;
    _darkTextColor = Colors.white;
    _lightTextColor = Colors.black;

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _logoScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _bgOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _bgColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: _lightBgColor,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _textColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: _lightTextColor,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _startAnimations();
    AuthService.loadCookies();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _darkBgColor = Colors.grey[900]!;
    _lightBgColor = Colors.white;
    _darkTextColor = Colors.white;
    _lightTextColor = Colors.black;

    _bgColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: _isDarkMode ? _darkBgColor : _lightBgColor,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _textColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: _isDarkMode ? _darkTextColor : _lightTextColor,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  Future<void> _startAnimations() async {
    _logoController.forward().then((_) {
      _textController.forward();
      _startTypingAnimation();
    });

    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    CheckuserUtils.checkUser(context);
  }

  Future<void> _startTypingAnimation() async {
    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        displayedText = fullText.substring(0, i + 1);
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      displayedText = fullText;
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 350;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoController, _textController, _pulseController]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isDarkMode
                    ? [
                        Colors.grey[900]!,
                        Colors.grey[850]!,
                        Colors.grey[900]!,
                      ]
                    : [
                        Colors.white,
                        Colors.grey[50]!,
                        Colors.white,
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Background Pattern (Only Concentric Circles - No Bubbles)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundPatternPainter(
                        animationValue: _logoController.value,
                        isDarkMode: _isDarkMode,
                      ),
                    ),
                  ),

                  // Main Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.12),

                        // Logo with Multiple Shadows and Glow - SIRF LOGO KA GRADIENT CHANGED
                        ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: isSmallScreen
                                      ? screenWidth * 0.28
                                      : screenWidth * 0.32,
                                  height: isSmallScreen
                                      ? screenWidth * 0.28
                                      : screenWidth * 0.32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      // Outer Glow
                                      BoxShadow(
                                        color: (_isDarkMode
                                                ? Colors.blue[400]!
                                                : Colors.blue[500]!)
                                            .withOpacity(0.5),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                      // Inner Shadow
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 10),
                                      ),
                                      // Secondary Glow
                                      BoxShadow(
                                        color: (_isDarkMode
                                                ? Colors.blue[400]!
                                                : Colors.blue[300]!)
                                            .withOpacity(0.3),
                                        blurRadius: 40,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                    gradient: RadialGradient(
                                      colors: _isDarkMode
                                          ? [
                                              Colors.blue[300]!,      // Light blue
                                              Colors.blue[400]!,      // Medium blue
                                              Colors.blue[500]!,      // Dark blue
                                            ]
                                          : [
                                              Colors.blue[200]!,      // Very light blue
                                              Colors.blue[300]!,      // Light blue
                                              Colors.blue[400]!,      // Medium blue
                                            ],
                                      stops: const [0.2, 0.6, 1.0],
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 14 : 18,
                                      ),
                                      child: Image.asset(
                                        "assets/images/app_icon.png",
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.06),

                        // Text Section with Enhanced Styling (BACK TO ORIGINAL)
                        IntrinsicHeight(
                          child: AnimatedOpacity(
                            opacity: _textOpacityAnimation.value,
                            duration: Duration.zero,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Main Title with Gradient (BACK TO ORIGINAL)
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: _isDarkMode
                                          ? [
                                              Colors.blue[300]!,
                                              Colors.purple[300]!,
                                              Colors.blue[100]!,
                                            ]
                                          : [
                                              Colors.blue[700]!,
                                              Colors.purple[600]!,
                                              Colors.blue[800]!,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    displayedText,
                                    style: TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: isSmallScreen
                                          ? screenHeight * 0.03
                                          : screenHeight * 0.038,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.8,
                                      height: 1.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                SizedBox(height: screenHeight * 0.015),

                                // Tagline with Animation (BACK TO ORIGINAL)
                                AnimatedOpacity(
                                  opacity: displayedText == fullText
                                      ? 1.0
                                      : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.04,
                                      vertical: screenHeight * 0.008,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: _isDarkMode
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.blue.withOpacity(0.05),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.verified_rounded,
                                          size: screenHeight * 0.018,
                                          color: _isDarkMode
                                              ? Colors.blue[300]
                                              : Colors.blue[700],
                                        ),
                                        SizedBox(width: screenWidth * 0.01),
                                        Text(
                                          "Enterprise Solutions",
                                          style: TextStyle(
                                            fontFamily: "Poppins",
                                            fontSize: isSmallScreen
                                                ? screenHeight * 0.016
                                                : screenHeight * 0.02,
                                            fontWeight: FontWeight.w500,
                                            color: _isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Version Number (BACK TO ORIGINAL)
                                SizedBox(height: screenHeight * 0.02),
                                AnimatedOpacity(
                                  opacity: displayedText == fullText
                                      ? 0.7
                                      : 0.0,
                                  duration: const Duration(milliseconds: 800),
                                  child: Text(
                                    "Version 2.0.0",
                                    style: TextStyle(
                                      fontSize: isSmallScreen
                                          ? screenHeight * 0.012
                                          : screenHeight * 0.014,
                                      color: _isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Bottom Section with Loading and Company Name (BACK TO ORIGINAL)
                        Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.05),
                          child: Column(
                            children: [
                              // Animated Loading Bar (BACK TO ORIGINAL)
                              AnimatedOpacity(
                                opacity: _logoController.value > 0.6 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 400),
                                child: Container(
                                  width: screenWidth * 0.35,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: _isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        width: screenWidth * 0.35 * 
                                            (_logoController.value > 0.8 ? 1.0 : 0.3),
                                        height: 4,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: LinearGradient(
                                            colors: _isDarkMode
                                                ? [Colors.blue[400]!, Colors.purple[400]!]
                                                : [Colors.blue[600]!, Colors.purple[600]!],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // Company Name (BACK TO ORIGINAL)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Pioneer.",
                                    style: TextStyle(
                                      fontSize: screenHeight * 0.016,
                                      color: _isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    "Tech",
                                    style: TextStyle(
                                      fontSize: screenHeight * 0.016,
                                      color: _isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue[700],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.005),

                              // Copyright (BACK TO ORIGINAL)
                              Text(
                                "© 2024 All Rights Reserved",
                                style: TextStyle(
                                  fontSize: screenHeight * 0.012,
                                  color: _isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[500],
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
        },
      ),
    );
  }
}

// Background Pattern Painter (BACK TO ORIGINAL - with pink/purple for background)
class _BackgroundPatternPainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  _BackgroundPatternPainter({
    required this.animationValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw concentric circles only (no bubbles/particles) - BACK TO ORIGINAL
    for (int i = 0; i < 8; i++) {
      final radius = (i + 1) * 50.0 * animationValue;
      final opacity = (0.02 * (8 - i) * animationValue).clamp(0.0, 0.1);
      
      paint.color = (isDarkMode ? Colors.blue[400]! : Colors.blue[500]!).withOpacity(opacity);
      
      canvas.drawCircle(center, radius, paint);
    }

    // Draw diagonal lines for subtle texture - BACK TO ORIGINAL
    paint.color = (isDarkMode ? Colors.purple[400]! : Colors.purple[500]!).withOpacity(0.03 * animationValue);
    paint.strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      final offset = i * 40.0 * animationValue;
      
      canvas.drawLine(
        Offset(offset, 0),
        Offset(size.width - offset, size.height),
        paint,
      );
      
      canvas.drawLine(
        Offset(size.width - offset, 0),
        Offset(offset, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        isDarkMode != oldDelegate.isDarkMode;
  }
}