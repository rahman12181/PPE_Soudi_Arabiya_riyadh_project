// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:management_app/screen/homemain_screen.dart';
import 'package:management_app/screen/attendance_screen.dart';
import 'package:management_app/screen/dashboard_screen.dart';
import 'package:management_app/screen/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;
  late AnimationController _navBarController;
  late PageController _pageController;

  static final List<Widget> _bottomNavigationScreens = [
    const HomemainScreen(),
    const DashboardScreen(),
    const AttendanceScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _hintAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _hintController,
        curve: Curves.easeInOut,
      ),
    );
    
    _navBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _hintController.repeat(reverse: true);
    _navBarController.forward();
    
    _pageController = PageController(initialPage: _selectedIndex);
  }
  
  @override
  void dispose() {
    _hintController.dispose();
    _navBarController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _bottomNavigationScreens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildUniqueBottomNavigation(isDarkMode, bottomPadding, screenWidth, screenHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildUniqueBottomNavigation(bool isDarkMode, double bottomPadding, double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    
    final double navBarHeight = screenWidth < 360 ? 56 : 64;
    final double iconSize = screenWidth < 360 ? 22 : 24;
    final double fontSize = screenWidth < 360 ? 10 : 11;
    final double activeIndicatorHeight = screenWidth < 360 ? 3 : 4;
    
    return Container(
      height: navBarHeight + bottomPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
              ? [
                  const Color(0xFF334155),
                  const Color(0xFF334155),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screenWidth < 400 ? 20 : 30),
          topRight: Radius.circular(screenWidth < 400 ? 20 : 30),
        ),
        border: Border(
          top: BorderSide(
            color: theme.primaryColor.withOpacity(isDarkMode ? 0.3 : 0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildUniqueNavItem(
              icon: Icons.home_rounded,
              activeIcon: Icons.home_rounded,
              label: "Home",
              index: 0,
              isDarkMode: isDarkMode,
              iconSize: iconSize,
              fontSize: fontSize,
              activeIndicatorHeight: activeIndicatorHeight,
              screenWidth: screenWidth,
            ),
            _buildUniqueNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: "Dashboard",
              index: 1,
              isDarkMode: isDarkMode,
              iconSize: iconSize,
              fontSize: fontSize,
              activeIndicatorHeight: activeIndicatorHeight,
              screenWidth: screenWidth,
            ),
            _buildUniqueNavItem(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: "History",
              index: 2,
              isDarkMode: isDarkMode,
              iconSize: iconSize,
              fontSize: fontSize,
              activeIndicatorHeight: activeIndicatorHeight,
              screenWidth: screenWidth,
            ),
            _buildUniqueNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: "Setting",
              index: 3,
              isDarkMode: isDarkMode,
              iconSize: iconSize,
              fontSize: fontSize,
              activeIndicatorHeight: activeIndicatorHeight,
              screenWidth: screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniqueNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDarkMode,
    required double iconSize,
    required double fontSize,
    required double activeIndicatorHeight,
    required double screenWidth,
  }) {
    final bool active = _selectedIndex == index;
    final theme = Theme.of(context);
    
    final Color inactiveColor = isDarkMode 
        ? Colors.grey.shade500 
        : Colors.grey.shade600;
    final Color activeColor = theme.primaryColor;
    final Color textColor = isDarkMode 
        ? Colors.grey.shade300 
        : Colors.grey.shade800;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      transform: Matrix4.identity()
                        ..scale(active ? 1.1 : 1.0),
                      child: Icon(
                        active ? activeIcon : icon,
                        size: iconSize,
                        color: active ? activeColor : inactiveColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? activeColor : textColor,
                        letterSpacing: active ? 0.3 : 0,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
              if (active)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      height: activeIndicatorHeight,
                      width: screenWidth * 0.12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            activeColor.withOpacity(0.5),
                            activeColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(activeIndicatorHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(isDarkMode ? 0.5 : 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
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
    );
  }
}