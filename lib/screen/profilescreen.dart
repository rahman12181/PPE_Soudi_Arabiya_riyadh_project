// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:management_app/services/profile_service.dart';
import 'package:management_app/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profilescreen extends StatefulWidget {
  const Profilescreen({super.key});

  @override
  State<Profilescreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<Profilescreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

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
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final userEmail =
          prefs.getString('userEmail') ?? prefs.getString('email');

      if (userEmail != null && userEmail.isNotEmpty) {
        final result = await ProfileService.getCompleteProfile(userEmail);

        if (mounted) {
          if (result['success'] == true) {
            setState(() {
              _profileData = result['data'];
              _isLoading = false;
            });
            _animationController.forward();
          } else {
            // Get error message from result
            String errorMessage =
                result['message'] ??
                "Failed to load profile. Please try again.";

            // Check if it's a network-related error
            final msgLower = errorMessage.toLowerCase();
            if (msgLower.contains("network") ||
                msgLower.contains("connection") ||
                msgLower.contains("internet") ||
                msgLower.contains("timeout") ||
                msgLower.contains("socket")) {
              errorMessage =
                  "No internet connection. Please check your network.";
            }

            setState(() {
              _errorMessage = errorMessage;
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = "User email not found. Please login again.";
          _isLoading = false;
        });
      }
      // ✅ BAAD MEIN
    } catch (e) {
      if (mounted) {
        final rawMsg = e.toString().toLowerCase();

        // Added more keywords that http package might return
        final isNetworkError =
            rawMsg.contains("socket") ||
            rawMsg.contains("connection") ||
            rawMsg.contains("network") ||
            rawMsg.contains("internet") ||
            rawMsg.contains("host lookup") ||
            rawMsg.contains("failed host") ||
            rawMsg.contains("failed to fetch") ||
            rawMsg.contains("network request failed") ||
            rawMsg.contains("timeout") ||
            rawMsg.contains("unable to connect") ||
            rawMsg.contains("connection refused") ||
            rawMsg.contains("no route to host") ||
            rawMsg.contains("xmlhttprequest error");

        final displayMsg = isNetworkError
            ? "No internet connection. Please check your network."
            : "Failed to load profile. Please try again.";

        setState(() {
          _errorMessage = displayMsg;
          _isLoading = false;
        });
      }
    }
  }

  String? _getProfileImageUrl() {
    if (_profileData == null) return null;

    if (_profileData!['full_image_url'] != null &&
        _profileData!['full_image_url'].toString().isNotEmpty) {
      return _profileData!['full_image_url'].toString();
    }

    return null;
  }

  String _getFullName() {
    return ProfileService.getDisplayName(_profileData ?? {});
  }

  String _getEmployeeId() {
    return ProfileService.getEmployeeId(_profileData ?? {});
  }

  String _getStatusText() {
    return ProfileService.getStatusText(_profileData?['status']);
  }

  String _getDepartment() {
    if (_profileData?['department'] != null) {
      return _profileData!['department'].toString();
    }
    if (_profileData?['custom_department'] != null) {
      return _profileData!['custom_department'].toString();
    }
    return 'Not Assigned';
  }

  String _getDesignation() {
    if (_profileData?['designation'] != null) {
      return _profileData!['designation'].toString();
    }
    return 'Not Assigned';
  }

  String _getBranch() {
    if (_profileData?['branch'] != null) {
      return _profileData!['branch'].toString();
    }
    return 'Not Assigned';
  }

  String _getDateOfJoining() {
    if (_profileData?['date_of_joining'] != null) {
      return ProfileService.formatDate(_profileData!['date_of_joining']);
    }
    return 'N/A';
  }

  String _getExperience() {
    return ProfileService.getExperience(_profileData?['date_of_joining']);
  }

  String _getReportsTo() {
    if (_profileData?['reports_to'] != null) {
      return _profileData!['reports_to'].toString();
    }
    if (_profileData?['reports_to_name'] != null) {
      return _profileData!['reports_to_name'].toString();
    }
    return 'N/A';
  }

  String _getContractType() {
    if (_profileData?['contract_type'] != null) {
      return _profileData!['contract_type'].toString();
    }
    if (_profileData?['employment_type'] != null) {
      return _profileData!['employment_type'].toString();
    }
    return 'N/A';
  }

  // ✅ NEW: Get Contract End Date
  String _getContractEndDate() {
    return ProfileService.getContractEndDate(_profileData ?? {});
  }

  String _getEmergencyContact() {
    if (_profileData?['emergency_phone_number'] != null) {
      return _profileData!['emergency_phone_number'].toString();
    }
    return 'N/A';
  }

  String _getEmergencyContactPerson() {
    if (_profileData?['emergency_contact_person'] != null) {
      return _profileData!['emergency_contact_person'].toString();
    }
    return 'N/A';
  }

  Future<void> _refreshProfile() async {
    _animationController.reset();
    await _loadProfileData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getHeaderGradientColors(isDarkMode);

    final backgroundColor = isDarkMode ? charcoal : offWhite;
    final cardColor = isDarkMode ? slate : pureWhite;

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
            Container(
              height: MediaQuery.of(context).padding.top,
              width: double.infinity,
              color: gradientColors.first,
            ),
            SafeArea(
              top: true,
              bottom: true,
              child: RefreshIndicator(
            onRefresh: _refreshProfile,
            color: skyBlue,
            backgroundColor: cardColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: height * 0.15,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
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
                    child: Stack(
                      children: [
                        Positioned(
                          top: -height * 0.05,
                          right: -width * 0.1,
                          child: Container(
                            width: width * 0.5,
                            height: width * 0.5,
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
                          bottom: -height * 0.03,
                          left: -width * 0.1,
                          child: Container(
                            width: width * 0.4,
                            height: width * 0.4,
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
                        FlexibleSpaceBar(
                          centerTitle: true,
                          title: Padding(
                            padding: EdgeInsets.only(top: height * 0.02),
                            child: Text(
                              "My Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.06,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  leading: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: width * 0.05,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      child: IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: width * 0.05,
                          ),
                        ),
                        onPressed: _refreshProfile,
                      ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: EdgeInsets.all(width * 0.04),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_isLoading)
                        _buildShimmerLoader(width, height)
                      else if (_errorMessage != null)
                        _buildErrorWidget(width)
                      else if (_profileData != null)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildProfileContent(
                              width,
                              isDarkMode,
                              cardColor,
                              gradientColors,
                            ),
                          ),
                        ),
                    ]),
                  ),
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

  Widget _buildProfileContent(
    double width,
    bool isDarkMode,
    Color cardColor,
    List<Color> gradientColors,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.05),
          decoration: BoxDecoration(
            color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
            borderRadius: BorderRadius.circular(width * 0.06),
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
          child: Column(
            children: [
              // Profile Image with Status Badge
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: width * 0.28,
                      height: width * 0.28,
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
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: _getProfileImageUrl() != null
                              ? Image.network(
                                  _getProfileImageUrl()!,
                                  headers: {
                                    "Cookie": AuthService.cookies.join("; "),
                                  },
                                  width: width * 0.28,
                                  height: width * 0.28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        size: width * 0.1,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: width * 0.1,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(width * 0.015),
                        decoration: BoxDecoration(
                          color: ProfileService.getStatusColor(
                            _profileData!['status'] ?? 'active',
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: ProfileService.getStatusColor(
                                _profileData!['status'] ?? 'active',
                              ).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          ProfileService.getStatusIcon(
                            _profileData!['status'] ?? 'active',
                          ),
                          size: width * 0.035,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: width * 0.04),

              // Name and Designation in a row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFullName(),
                          style: TextStyle(
                            fontSize: width * 0.055,
                            fontWeight: FontWeight.bold,
                            color: skyBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_getDesignation() != 'Not Assigned')
                          Text(
                            _getDesignation(),
                            style: TextStyle(
                              fontSize: width * 0.035,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (_getEmployeeId() != 'N/A')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: width * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: deepSky.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(width * 0.06),
                        border: Border.all(
                          color: deepSky.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getEmployeeId(),
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: deepSky,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: width * 0.03),

              // Status and Email in a horizontal row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03,
                      vertical: width * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: ProfileService.getStatusColor(
                        _profileData!['status'] ?? 'active',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(width * 0.04),
                      border: Border.all(
                        color: ProfileService.getStatusColor(
                          _profileData!['status'] ?? 'active',
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ProfileService.getStatusIcon(
                            _profileData!['status'] ?? 'active',
                          ),
                          size: width * 0.03,
                          color: ProfileService.getStatusColor(
                            _profileData!['status'] ?? 'active',
                          ),
                        ),
                        SizedBox(width: width * 0.01),
                        Text(
                          _getStatusText()
                              .replaceAll('🟢', '')
                              .replaceAll('🔴', '')
                              .replaceAll('🟠', '')
                              .replaceAll('⚫', '')
                              .replaceAll('⚪', '')
                              .trim(),
                          style: TextStyle(
                            fontSize: width * 0.03,
                            color: ProfileService.getStatusColor(
                              _profileData!['status'] ?? 'active',
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: width * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: skyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(width * 0.04),
                        border: Border.all(
                          color: skyBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            size: width * 0.03,
                            color: skyBlue,
                          ),
                          SizedBox(width: width * 0.02),
                          Expanded(
                            child: Text(
                              _profileData!['email'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: width * 0.03,
                                color: skyBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: width * 0.04),

        // Work Information Section
        _buildSectionTitle(
          'Work Information',
          Icons.work_rounded,
          skyBlue,
          width,
        ),
        SizedBox(height: width * 0.03),
        _buildInfoCard(
          label: 'Department',
          value: _getDepartment(),
          icon: Icons.business_center_rounded,
          color: deepSky,
          width: width,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: width * 0.02),
        _buildInfoCard(
          label: 'Branch',
          value: _getBranch(),
          icon: Icons.location_city_rounded,
          color: skyBlue,
          width: width,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: width * 0.02),
        _buildInfoCard(
          label: 'Date of Joining',
          value: '${_getDateOfJoining()} (${_getExperience()})',
          icon: Icons.calendar_month_rounded,
          color: Colors.orange,
          width: width,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: width * 0.02),
        _buildInfoCard(
          label: 'Reports To',
          value: _getReportsTo(),
          icon: Icons.supervisor_account_rounded,
          color: Colors.purple,
          width: width,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: width * 0.02),
        _buildInfoCard(
          label: 'Contract Type',
          value: _getContractType(),
          icon: Icons.assignment_rounded,
          color: Colors.teal,
          width: width,
          isDarkMode: isDarkMode,
        ),
        // ✅ NEW: Contract End Date card
        if (_getContractEndDate() != 'N/A') SizedBox(height: width * 0.02),
        if (_getContractEndDate() != 'N/A')
          _buildInfoCard(
            label: 'Contract End Date',
            value: _getContractEndDate(),
            icon: Icons.event_rounded,
            color: Colors.blueGrey,
            width: width,
            isDarkMode: isDarkMode,
          ),

        SizedBox(height: width * 0.04),

        // Personal Information
        _buildSectionTitle(
          'Personal Information',
          Icons.person_rounded,
          deepSky,
          width,
        ),
        _buildInfoCard(
          label: 'ID / Iqama No',
          value: _profileData!['id_iqama'] ?? 'N/A',
          icon: Icons.badge_rounded,
          color: Colors.indigo,
          width: width,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: width * 0.03),
        _buildInfoCard(
          label: 'Gender',
          value: _profileData!['gender'] ?? 'N/A',
          icon: Icons.wc_rounded,
          color: skyBlue,
          width: width,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: width * 0.02),
        _buildInfoCard(
          label: 'Date of Birth',
          value:
              '${ProfileService.formatDate(_profileData!['birth_date'])} (${ProfileService.getAge(_profileData!['birth_date'])} years)',
          icon: Icons.cake_rounded,
          color: deepSky,
          width: width,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: width * 0.02),
        _buildInfoCard(
          label: 'Blood Group',
          value: _profileData!['blood_group'] ?? 'N/A',
          icon: Icons.bloodtype_rounded,
          color: Colors.red,
          width: width,
          isDarkMode: isDarkMode,
        ),

        SizedBox(height: width * 0.04),

        // Contact Information
        _buildSectionTitle(
          'Contact Information',
          Icons.contact_phone_rounded,
          mediumSky,
          width,
        ),
        SizedBox(height: width * 0.03),
        _buildInfoCard(
          label: 'Mobile Number',
          value:
              _profileData!['phone'] ?? _profileData!['cell_number'] ?? 'N/A',
          icon: Icons.phone_android_rounded,
          color: Colors.green,
          width: width,
          isDarkMode: isDarkMode,
        ),
        if (_getEmergencyContact() != 'N/A') ...[
          SizedBox(height: width * 0.02),
          _buildInfoCard(
            label: 'Emergency Contact',
            value: _getEmergencyContactPerson() != 'N/A'
                ? '$_getEmergencyContactPerson() - $_getEmergencyContact()'
                : _getEmergencyContact(),
            icon: Icons.emergency_rounded,
            color: Colors.amber,
            width: width,
            isDarkMode: isDarkMode,
          ),
        ],

        SizedBox(height: width * 0.04),
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
    required bool isDarkMode,
  }) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: isDarkMode ? slate.withOpacity(0.5) : pureWhite,
        borderRadius: BorderRadius.circular(width * 0.04),
        border: Border.all(color: skyBlue.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: skyBlue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.02),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(width * 0.02),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, size: width * 0.05, color: color),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: width * 0.03,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: width * 0.01),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.02,
        vertical: width * 0.01,
      ),
      decoration: BoxDecoration(
        color: skyBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(width * 0.04),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.015),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [skyBlue, deepSky]),
              borderRadius: BorderRadius.circular(width * 0.02),
              boxShadow: [
                BoxShadow(
                  color: skyBlue.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, size: width * 0.04, color: Colors.white),
          ),
          SizedBox(width: width * 0.02),
          Text(
            title,
            style: TextStyle(
              fontSize: width * 0.045,
              fontWeight: FontWeight.w800,
              color: skyBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(double width, double height) {
    return SizedBox(
      height: height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: width * 0.3,
              height: width * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skyBlue.withOpacity(0.1),
              ),
            ),
            SizedBox(height: width * 0.05),
            Container(
              width: width * 0.5,
              height: width * 0.05,
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(height: width * 0.02),
            Container(
              width: width * 0.4,
              height: width * 0.04,
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(double width) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFF556270)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: width * 0.1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: width * 0.05),
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: width * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: width * 0.02),
              Text(
                _errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: width * 0.05),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _refreshProfile,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.05,
                      vertical: width * 0.03,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [skyBlue, deepSky],
                      ),
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: width * 0.05,
                        ),
                        SizedBox(width: width * 0.02),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.04,
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
    );
  }
}
