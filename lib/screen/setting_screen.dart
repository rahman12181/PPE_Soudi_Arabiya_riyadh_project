// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:management_app/providers/profile_provider.dart';
import 'package:management_app/screen/change_password_screen.dart';
import 'package:management_app/screen/profilescreen.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:management_app/screen/goodbye_screen.dart';
import 'package:management_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool voiceEnabled = false;
  bool faceIdEnabled = false;
  String selectedLanguage = "English";
  String selectedTheme = "Light";

  // Sky Blue Color Palette - Matching all screens
  static const Color skyBlue = Color(0xFF87CEEB); // Sky blue primary
  static const Color lightSky = Color(0xFFE0F2FE); // Very light sky
  static const Color mediumSky = Color(0xFF7EC8E0); // Medium sky
  static const Color deepSky = Color(0xFF00A5E0); // Deep sky for accents
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);

  // Get header gradient colors based on theme (matching all screens)
  List<Color> _getHeaderGradientColors(bool isDarkMode) {
    return isDarkMode
        ? [charcoal, slate, const Color(0xFF1E1E2E)]
        : [skyBlue, mediumSky, deepSky];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    // Color scheme
    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final textColor = isDarkMode ? Colors.white : Colors.grey[900]!;
    final subtitleColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Status bar color matching gradient
            Container(
              height: MediaQuery.of(context).padding.top,
              width: double.infinity,
              color: gradientColors.first,
            ),
            SafeArea(
              top: true,
              bottom: true,
              child: Consumer<ProfileProvider>(
                builder: (context, provider, _) {
                  final user = provider.profileData;

                  return Column(
                    children: [
                      // Premium Header with Sky Blue Gradient
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
                              "Settings",
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
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: screenWidth * 0.06,
                                ),
                                onPressed: () => _showLogoutDialog(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.045,
                            vertical: screenHeight * 0.025,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Premium Profile Section with Sky Blue Theme
                              _buildPremiumProfileSection(
                                context,
                                user,
                                screenWidth,
                                screenHeight,
                                isDarkMode,
                                textColor,
                                subtitleColor,
                                gradientColors,
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              // Account Settings
                              _buildPremiumSectionTitle(
                                "Account Settings",
                                Icons.settings_rounded,
                                gradientColors,
                                screenWidth,
                              ),
                              SizedBox(height: screenHeight * 0.015),

                              _buildPremiumSettingTile(
                                icon: Icons.person_outline_rounded,
                                title: "User Profile",
                                subtitle: "View and edit your profile",
                                iconColor: skyBlue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const Profilescreen(),
                                    ),
                                  );
                                },
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                gradientColors: gradientColors,
                              ),

                              _buildPremiumSettingTile(
                                icon: Icons.lock_outline_rounded,
                                title: "Change Password",
                                subtitle: "Update your password",
                                iconColor: deepSky,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChangePasswordScreen(),
                                    ),
                                  );
                                },
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                gradientColors: gradientColors,
                              ),

                              _buildPremiumSettingTile(
                                icon: Icons.email_outlined,
                                title: "Notification Email",
                                subtitle: user?['email'] ?? "Not set",
                                iconColor: mediumSky,
                                onTap: () {},
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                gradientColors: gradientColors,
                              ),

                              _buildPremiumDropdownTile(
                                icon: Icons.language_rounded,
                                title: "Language",
                                value: selectedLanguage,
                                options: const ["English", "Arabic"],
                                iconColor: deepSky,
                                onChanged: (value) {
                                  setState(() => selectedLanguage = value!);
                                },
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                gradientColors: gradientColors,
                              ),

                              _buildPremiumDropdownTile(
                                icon: Icons.brightness_6_outlined,
                                title: "Theme",
                                value: selectedTheme,
                                options: const ["Light", "Dark", "System"],
                                iconColor: mediumSky,
                                onChanged: (value) async {
                                  if (value == null) return;
                                  setState(() => selectedTheme = value);

                                  // Theme apply karo immediately
                                  switch (value) {
                                    case 'Light':
                                      themeNotifier.value = ThemeMode.light;
                                      break;
                                    case 'Dark':
                                      themeNotifier.value = ThemeMode.dark;
                                      break;
                                    default:
                                      themeNotifier.value = ThemeMode.system;
                                  }

                                  // SharedPreferences mein save karo
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('selected_theme', value);
                                },
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                gradientColors: gradientColors,
                              ),

                              _buildPremiumSettingTile(
  icon: Icons.info_outline_rounded,
  title: "About Us",
  subtitle: "Learn more about Management App",
  iconColor: skyBlue,
  onTap: () => _showAboutUsDialog(context),
  screenWidth: screenWidth,
  screenHeight: screenHeight,
  isDarkMode: isDarkMode,
  textColor: textColor,
  subtitleColor: subtitleColor,
  gradientColors: gradientColors,
),

                              // App Settings (commented out)
                              // ... existing commented code ...

                              SizedBox(height: screenHeight * 0.05),

                              // App Info with Sky Blue Theme
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Version 1.0.0",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.w600,
                                        color: skyBlue,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      "© 2024 Management App",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: subtitleColor.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium Profile Section with Sky Blue Theme
  Widget _buildPremiumProfileSection(
    BuildContext context,
    Map<String, dynamic>? user,
    double screenWidth,
    double screenHeight,
    bool isDarkMode,
    Color textColor,
    Color subtitleColor,
    List<Color> gradientColors,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Profilescreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          border: Border.all(color: skyBlue.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: skyBlue.withOpacity(0.1),
              blurRadius: 25,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Premium Profile Image with Sky Blue Gradient
            Container(
              width: screenWidth * 0.18,
              height: screenWidth * 0.18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: skyBlue.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  backgroundColor: isDarkMode ? slate : Colors.white,
                  child: ClipOval(
                    child:
                        (user != null &&
                            user['user_image'] != null &&
                            user['user_image'].toString().isNotEmpty)
                        ? Image.network(
                            "https://ppecon.erpnext.com${user['user_image']}",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,

                            /// ERPNext session cookie
                            headers: {"Cookie": AuthService.cookies.join("; ")},

                            errorBuilder: (_, __, ___) => Image.asset(
                              "assets/images/app_icon.png",
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            "assets/images/app_icon.png",
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?['full_name'] ?? "Loading...",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w700,
                      color: skyBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    user?['email'] ?? "",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: subtitleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: skyBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: skyBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: skyBlue,
                          size: screenWidth * 0.035,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          "Verified Account",
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
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
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: screenWidth * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium Section Title with Sky Blue Theme
  Widget _buildPremiumSectionTitle(
    String title,
    IconData icon,
    List<Color> gradientColors,
    double screenWidth,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            boxShadow: [
              BoxShadow(
                color: skyBlue.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, size: screenWidth * 0.04, color: Colors.white),
        ),
        SizedBox(width: screenWidth * 0.02),
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w800,
            color: skyBlue,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // Premium Setting Tile with Sky Blue Theme
  Widget _buildPremiumSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required VoidCallback? onTap,
    required double screenWidth,
    required double screenHeight,
    required bool isDarkMode,
    required Color textColor,
    required Color subtitleColor,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.018,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              border: Border.all(color: skyBlue.withOpacity(0.2), width: 1.5),
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
              children: [
                // Icon with gradient background
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: screenWidth * 0.05),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: screenWidth * 0.032,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.015),
                  decoration: BoxDecoration(
                    color: skyBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: skyBlue,
                    size: screenWidth * 0.04,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium Toggle Tile with Sky Blue Theme
  Widget _buildPremiumToggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
    required double screenWidth,
    required double screenHeight,
    required bool isDarkMode,
    required Color textColor,
    required Color subtitleColor,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.018,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: skyBlue.withOpacity(0.2), width: 1.5),
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
          children: [
            // Icon with gradient background
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: iconColor, size: screenWidth * 0.05),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: screenHeight * 0.003),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: iconColor,
              activeTrackColor: iconColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  // Premium Dropdown Tile with Sky Blue Theme
  Widget _buildPremiumDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required Color iconColor,
    required ValueChanged<String?> onChanged,
    required double screenWidth,
    required double screenHeight,
    required bool isDarkMode,
    required Color textColor,
    required Color subtitleColor,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.018,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: skyBlue.withOpacity(0.2), width: 1.5),
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
          children: [
            // Icon with gradient background
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: iconColor, size: screenWidth * 0.05),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.003),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              color: isDarkMode ? slate : Colors.white,
              itemBuilder: (BuildContext context) {
                return options.map((String option) {
                  return PopupMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: textColor,
                      ),
                    ),
                  );
                }).toList();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.008,
                ),
                decoration: BoxDecoration(
                  color: skyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                        color: skyBlue,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: skyBlue,
                      size: screenWidth * 0.045,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium Logout Dialog with Sky Blue Theme
  Future<void> _showLogoutDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    final bool? confirm = await showDialog<bool>(
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
                  gradient: const LinearGradient(colors: [deepSky, skyBlue]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: deepSky.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.08,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                "Logout",
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w800,
                  color: skyBlue,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                "Are you sure you want to logout?",
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenWidth * 0.05),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, false),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.03,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.03,
                            ),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[700],
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
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenWidth * 0.03,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors),
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.03,
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
                          child: const Center(
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                fontSize: 16,
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

    if (confirm == true) {
      _performLogout(context);
    }
  }

  // Perform Logout
  Future<void> _performLogout(BuildContext context) async {
    final auth = AuthService();
    final result = await auth.logoutUser();

    if (context.mounted) {
      if (result["success"] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const GoodbyeScreen()),
          (route) => false,
        );
      } else {
        _showErrorDialog(
          context,
          result["message"] ?? "Logout failed. Please try again.",
        );
      }
    }
  }

  // Premium Error Dialog with Sky Blue Theme
  void _showErrorDialog(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    showDialog(
      context: context,
      barrierDismissible: true,
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
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFF556270)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.08,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                "Error",
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
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
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
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

  // About Us Dialog with Website Link
void _showAboutUsDialog(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final screenWidth = MediaQuery.of(context).size.width;
  final gradientColors = _getHeaderGradientColors(isDarkMode);

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: screenWidth * 0.85,
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
            // Logo / Icon
            Container(
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
              child: Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: screenWidth * 0.08,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Title
            Text(
              "About Us",
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w800,
                color: skyBlue,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            
            // Description
            Text(
              "Management App helps you track your daily attendance, manage punches, and monitor your work hours efficiently.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Website Link
            InkWell(
              onTap: () {
                // Copy to clipboard and show message
                Clipboard.setData(const ClipboardData(text: "https://ppecon.com"));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Website link copied!"),
                    duration: Duration(seconds: 1),
                    backgroundColor: skyBlue,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.02,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: skyBlue.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_rounded, color: Colors.white, size: screenWidth * 0.04),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      "www.ppecon.com",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            
            // Version
            Text(
              "Version 1.0.0",
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                //color: subtitleColor.withOpacity(0.6),
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            
            // Close Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      "Close",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: skyBlue,
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
}