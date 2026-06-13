// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:management_app/card_screen/leaverequest.dart';
import 'package:management_app/model/leave_approved_model.dart';
import 'package:management_app/screen/travel_request_screen.dart';
import 'package:management_app/services/leave_approved_service.dart';
import 'package:management_app/services/travel_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leave_detail_screen.dart';
import 'travel_detail_screen.dart';

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen>
    with TickerProviderStateMixin {
  bool _isFabOpen = false;
  double _fabScale = 0.0;
  double _optionsOpacity = 0.0;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";
  String _employeeId = "";
  String _employeeName = "";
  String _selectedFilter = "All";

  Timer? _refreshTimer;
  bool _isRefreshing = false;

  int _totalCount = 0;
  int _leaveCount = 0;
  int _travelCount = 0;
  int _pendingCount = 0;

  late AnimationController _mainController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  // Sky Blue Color Palette - Matching all screens
  static const Color skyBlue = Color(0xFF87CEEB); // Sky blue primary
  static const Color deepSky = Color(0xFF00A5E0); // Deep sky for accents
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);

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
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    _loadEmployeeData().then((_) {
      if (_employeeId.isNotEmpty) {
        _fetchAllRequests(showLoading: true);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Employee ID not found. Please login again.";
        });
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isRefreshing && _employeeId.isNotEmpty) {
        _fetchAllRequests(showLoading: false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainController.forward();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _mainController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final empId = prefs.getString("employeeId") ?? "";
      final empName = prefs.getString("employeeName") ?? "";

      setState(() {
        _employeeId = empId;
        _employeeName = empName;
      });
    } catch (e) {
      print("Error loading employee data: $e");
    }
  }

  Future<void> _fetchAllRequests({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    } else {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      List<Map<String, dynamic>> allRequests = [];

      try {
        final leaves = await LeaveApprovedService.fetchLeaves();
        final userLeaves = leaves.where((leave) {
          return leave.employeeName.toLowerCase().contains(
                _employeeName.toLowerCase(),
              ) ||
              _employeeName.toLowerCase().contains(
                leave.employeeName.toLowerCase(),
              );
        }).toList();

        final leaveMaps = userLeaves.map((leave) {
          return {
            "type": "leave",
            "data": leave,
            "id":
                "${leave.employeeName}_${leave.fromDate}_${DateTime.now().millisecondsSinceEpoch}",
            "title": leave.leaveType,
            "subtitle": leave.employeeName,
            "employee": leave.employeeName,
            "from_date": leave.fromDate,
            "to_date": leave.toDate,
            "date": leave.fromDate,
            "status": leave.status,
            "status_color": _getStatusColor(leave.status),
            "status_bg_color": _getStatusBgColor(leave.status),
            "icon": Icons.beach_access,
            "icon_color": skyBlue,
            "created_date": leave.fromDate,
            "is_logged": true,
            "last_updated": DateTime.now().toIso8601String(),
          };
        }).toList();

        allRequests.addAll(leaveMaps);
      } catch (e) {
        print("Error fetching leaves: $e");
      }

      try {
        final travels = await TravelRequestService.getMyTravelRequests(
          _employeeId,
        );
        final userTravels = travels.where((travel) {
          final travelEmpId = travel["employee"]?.toString() ?? "";
          final travelEmpName = travel["employee_name"]?.toString() ?? "";
          return travelEmpId == _employeeId ||
              travelEmpName.toLowerCase().contains(
                _employeeName.toLowerCase(),
              ) ||
              _employeeName.toLowerCase().contains(travelEmpName.toLowerCase());
        }).toList();

        final formattedTravels = userTravels.map((travel) {
          return {
            ...travel,
            "type": "travel",
            "is_logged": true,
            "last_updated": DateTime.now().toIso8601String(),
            "status_color": _getStatusColor(travel["status"] ?? "Pending"),
            "status_bg_color": _getStatusBgColor(travel["status"] ?? "Pending"),
            "icon": Icons.flight_takeoff,
            "icon_color": deepSky,
            "title": travel["purpose_of_travel"] ?? "Travel Request",
            "subtitle": travel["employee_name"] ?? "",
            "created_date": travel["posting_date"] ?? "",
          };
        }).toList();

        allRequests.addAll(formattedTravels);
      } catch (e) {
        print("Error fetching travels: $e");
      }

      _calculateStatistics(allRequests);

      allRequests.sort((a, b) {
        final dateA = a["created_date"] ?? "";
        final dateB = b["created_date"] ?? "";
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _allRequests = allRequests;
          _filterRequests();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isRefreshing = false;
          _errorMessage = "Failed to load requests: ${e.toString()}";
        });
      }
    }
  }

  void _calculateStatistics(List<Map<String, dynamic>> requests) {
    int total = requests.length;
    int leaves = 0;
    int travels = 0;
    int pending = 0;

    for (var request in requests) {
      final type = request["type"];
      final status = (request["status"] ?? "").toString().toLowerCase();

      if (type == "leave") leaves++;
      if (type == "travel") travels++;

      if (status.contains("pending") ||
          status.contains("draft") ||
          status.contains("submitted")) {
        pending++;
      }
    }

    setState(() {
      _totalCount = total;
      _leaveCount = leaves;
      _travelCount = travels;
      _pendingCount = pending;
    });
  }

  void _filterRequests() {
    List<Map<String, dynamic>> filtered = List.from(_allRequests);

    if (_selectedFilter != "All") {
      filtered = filtered
          .where((req) => req["type"] == _selectedFilter.toLowerCase())
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((req) {
        final title = req["title"].toString().toLowerCase();
        final subtitle = req["subtitle"].toString().toLowerCase();
        final status = req["status"].toString().toLowerCase();
        final employee = req["employee"].toString().toLowerCase();
        final purpose =
            req["purpose_of_travel"]?.toString().toLowerCase() ?? "";
        final travelType = req["travel_type"]?.toString().toLowerCase() ?? "";

        return title.contains(query) ||
            subtitle.contains(query) ||
            status.contains(query) ||
            employee.contains(query) ||
            purpose.contains(query) ||
            travelType.contains(query);
      }).toList();
    }

    setState(() {
      _filteredRequests = filtered;
    });
  }

  void _onFilterChanged(String value) {
    setState(() {
      _selectedFilter = value;
      _filterRequests();
    });
  }

  void _onSearchChanged(String query) {
    _filterRequests();
  }

  void _clearSearch() {
    _searchController.clear();
    _filterRequests();
  }

  void _toggleFabMenu() {
    if (!_isFabOpen) {
      _bounceController.forward();
    }
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabScale = 1.0;
        _optionsOpacity = 1.0;
      } else {
        _optionsOpacity = 0.0;
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _fabScale = 0.0;
            });
          }
        });
      }
    });
  }

  void _navigateToLeaveRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaveRequest()),
    ).then((value) {
      _fetchAllRequests();
      _toggleFabMenu();
    });
  }

  void _navigateToTravelRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TravelRequestScreen()),
    ).then((value) {
      _fetchAllRequests();
      _toggleFabMenu();
    });
  }

  Future<void> _refreshData() async {
    await _fetchAllRequests(showLoading: false);
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.contains("approved")) return Colors.green;
    if (statusLower.contains("rejected")) return Colors.red;
    if (statusLower.contains("cancelled")) return Colors.grey;
    if (statusLower.contains("pending") ||
        statusLower.contains("draft") ||
        statusLower.contains("submitted")) {
      return skyBlue;
    }

    return skyBlue;
  }

  Color _getStatusBgColor(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower.contains("approved")) return Colors.green.withOpacity(0.1);
    if (statusLower.contains("rejected")) return Colors.red.withOpacity(0.1);
    if (statusLower.contains("cancelled")) return Colors.grey.withOpacity(0.1);
    if (statusLower.contains("pending") ||
        statusLower.contains("draft") ||
        statusLower.contains("submitted")) {
      return skyBlue.withOpacity(0.1);
    }

    return skyBlue.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final padding = mediaQuery.padding;
    final safeAreaTop = padding.top;
    final safeAreaBottom = padding.bottom;

    double responsiveWidth(double percentage) => screenWidth * percentage;
    double responsiveHeight(double percentage) => screenHeight * percentage;
    double responsiveFontSize(double baseSize) =>
        baseSize * (screenWidth / 375);

    final primaryColor = skyBlue;
    final secondaryColor = deepSky;
    final backgroundColor = isDark ? charcoal : offWhite;
    final cardColor = isDark ? slate : pureWhite;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
    // Status bar color based on theme
    final statusBarColor = isDark ? charcoal : skyBlue;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // Status bar background
            Container(
              height: MediaQuery.of(context).padding.top,
              width: double.infinity,
              color: statusBarColor,
            ),
            SafeArea(
              top: true,
              bottom: true,
              child: Stack(
                children: [
                  Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveWidth(0.04),
                              vertical: responsiveHeight(0.02),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark 
                                    ? [charcoal, slate, const Color(0xFF1E1E2E)]
                                    : [skyBlue, deepSky],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: IconButton(
                                    icon: Container(
                                      padding: EdgeInsets.all(responsiveWidth(0.01)),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: responsiveWidth(0.05),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "My Requests",
                                      style: TextStyle(
                                        fontSize: responsiveFontSize(20),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (_employeeName.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: responsiveWidth(0.02),
                                          vertical: responsiveHeight(0.002),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _employeeName,
                                          style: TextStyle(
                                            fontSize: responsiveFontSize(12),
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Stack(
                                  children: [
                                    ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: IconButton(
                                        icon: AnimatedRotation(
                                          duration: const Duration(milliseconds: 500),
                                          turns: _isRefreshing ? 1 : 0,
                                          child: Icon(
                                            Icons.refresh_rounded,
                                            size: responsiveWidth(0.06),
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: _isRefreshing
                                            ? null
                                            : _refreshData,
                                        tooltip: "Refresh",
                                      ),
                                    ),
                                    if (_isRefreshing)
                                      Positioned(
                                        right: responsiveWidth(0.02),
                                        top: responsiveHeight(0.01),
                                        child: ScaleTransition(
                                          scale: _pulseAnimation,
                                          child: Container(
                                            width: responsiveWidth(0.015),
                                            height: responsiveWidth(0.015),
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
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
                      ),

                      // Search and Filter Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: EdgeInsets.all(responsiveWidth(0.04)),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: skyBlue.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    decoration: InputDecoration(
                                      hintText: "Search requests...",
                                      hintStyle: TextStyle(
                                        fontSize: responsiveFontSize(14),
                                        color: subtitleColor,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        size: responsiveWidth(0.05),
                                        color: skyBlue,
                                      ),
                                      filled: true,
                                      fillColor: cardColor,
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
                                          color: isDark
                                              ? Colors.grey[700]!
                                              : Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          responsiveWidth(0.04),
                                        ),
                                        borderSide: const BorderSide(
                                          color: skyBlue,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: responsiveWidth(0.04),
                                        vertical: responsiveHeight(0.02),
                                      ),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear_rounded,
                                                size: responsiveWidth(0.05),
                                                color: subtitleColor,
                                              ),
                                              onPressed: _clearSearch,
                                            )
                                          : null,
                                    ),
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(16),
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: responsiveHeight(0.02)),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Text(
                                        "Filter: ",
                                        style: TextStyle(
                                          fontSize: responsiveFontSize(14),
                                          color: subtitleColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: responsiveWidth(0.02)),
                                      Wrap(
                                        spacing: responsiveWidth(0.02),
                                        children: ["All", "Leave", "Travel"].map((
                                          filter,
                                        ) {
                                          final isSelected =
                                              _selectedFilter == filter;
                                          final filterColor = filter == "Leave"
                                              ? Colors.green
                                              : filter == "Travel"
                                              ? Colors.orange
                                              : skyBlue;
                                          return ChoiceChip(
                                            label: Text(
                                              filter,
                                              style: TextStyle(
                                                fontSize: responsiveFontSize(14),
                                                color: isSelected
                                                    ? Colors.white
                                                    : subtitleColor,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                            selected: isSelected,
                                            backgroundColor: isDark
                                                ? slate
                                                : Colors.grey[200],
                                            selectedColor: isSelected
                                                ? filterColor
                                                : null,
                                            onSelected: (_) =>
                                                _onFilterChanged(filter),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: responsiveWidth(0.04),
                                              vertical: responsiveHeight(0.01),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Statistics Cards
                      if (!_isLoading && !_hasError && _allRequests.isNotEmpty)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsiveWidth(0.04),
                                vertical: responsiveHeight(0.01),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    title: "Total",
                                    count: _totalCount.toString(),
                                    color: skyBlue,
                                    icon: Icons.list_alt_rounded,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    responsiveWidth: responsiveWidth,
                                    responsiveHeight: responsiveHeight,
                                    responsiveFontSize: responsiveFontSize,
                                  ),
                                  _buildStatItem(
                                    title: "Leaves",
                                    count: _leaveCount.toString(),
                                    color: Colors.green,
                                    icon: Icons.beach_access_rounded,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    responsiveWidth: responsiveWidth,
                                    responsiveHeight: responsiveHeight,
                                    responsiveFontSize: responsiveFontSize,
                                  ),
                                  _buildStatItem(
                                    title: "Travel",
                                    count: _travelCount.toString(),
                                    color: Colors.orange,
                                    icon: Icons.flight_takeoff_rounded,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    responsiveWidth: responsiveWidth,
                                    responsiveHeight: responsiveHeight,
                                    responsiveFontSize: responsiveFontSize,
                                  ),
                                  _buildStatItem(
                                    title: "Pending",
                                    count: _pendingCount.toString(),
                                    color: skyBlue,
                                    icon: Icons.pending_rounded,
                                    screenWidth: screenWidth,
                                    screenHeight: screenHeight,
                                    responsiveWidth: responsiveWidth,
                                    responsiveHeight: responsiveHeight,
                                    responsiveFontSize: responsiveFontSize,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (_isRefreshing)
                        LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: skyBlue.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(skyBlue),
                        ),

                      if (_employeeId.isEmpty && !_isLoading)
                        Padding(
                          padding: EdgeInsets.all(responsiveWidth(0.04)),
                          child: Container(
                            padding: EdgeInsets.all(responsiveWidth(0.04)),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                responsiveWidth(0.04),
                              ),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: responsiveWidth(0.05),
                                ),
                                SizedBox(width: responsiveWidth(0.03)),
                                Expanded(
                                  child: Text(
                                    "Employee ID not found. Showing all requests.",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: responsiveFontSize(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Expanded(
                        child: _buildRequestsList(
                          theme,
                          isDark,
                          screenWidth,
                          screenHeight,
                          responsiveWidth,
                          responsiveHeight,
                          responsiveFontSize,
                        ),
                      ),
                    ],
                  ),

                  // FAB Menu Overlay
                  if (_isFabOpen)
                    GestureDetector(
                      onTap: _toggleFabMenu,
                      child: Container(
                        color: Colors.black54,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                  // FAB Options
                  Positioned(
                    bottom: responsiveHeight(0.15),
                    right: responsiveWidth(0.05),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _optionsOpacity,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: _fabScale,
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: _bounceAnimation,
                              child: _buildFabOptionItem(
                                icon: Icons.flight_takeoff_outlined,
                                label: "Travel Request",
                                color: deepSky,
                                onTap: _navigateToTravelRequest,
                                theme: theme,
                                screenWidth: screenWidth,
                                responsiveWidth: responsiveWidth,
                                responsiveHeight: responsiveHeight,
                                responsiveFontSize: responsiveFontSize,
                              ),
                            ),
                            SizedBox(height: responsiveHeight(0.02)),
                            ScaleTransition(
                              scale: _bounceAnimation,
                              child: _buildFabOptionItem(
                                icon: Icons.beach_access_outlined,
                                label: "Create Leave",
                                color: skyBlue,
                                onTap: _navigateToLeaveRequest,
                                theme: theme,
                                screenWidth: screenWidth,
                                responsiveWidth: responsiveWidth,
                                responsiveHeight: responsiveHeight,
                                responsiveFontSize: responsiveFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main FAB
                  Positioned(
                    bottom: responsiveHeight(0.03),
                    right: responsiveWidth(0.05),
                    child: GestureDetector(
                      onTap: _toggleFabMenu,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: responsiveWidth(0.14),
                        height: responsiveWidth(0.14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [skyBlue, deepSky],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: skyBlue.withOpacity(0.4),
                              blurRadius: responsiveWidth(0.04),
                              spreadRadius: responsiveWidth(0.005),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 300),
                          turns: _isFabOpen ? 0.125 : 0,
                          child: Icon(
                            _isFabOpen ? Icons.close_rounded : Icons.add_rounded,
                            color: Colors.white,
                            size: responsiveWidth(0.06),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
    required double screenWidth,
    required double screenHeight,
    required double Function(double) responsiveWidth,
    required double Function(double) responsiveHeight,
    required double Function(double) responsiveFontSize,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsiveWidth(0.02),
          vertical: responsiveHeight(0.01),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(responsiveWidth(0.02)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: responsiveWidth(0.05)),
            ),
            SizedBox(height: responsiveHeight(0.005)),
            Text(
              count,
              style: TextStyle(
                fontSize: responsiveFontSize(18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: responsiveFontSize(10),
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    ThemeData theme,
    bool isDark,
    double screenWidth,
    double screenHeight,
    double Function(double) responsiveWidth,
    double Function(double) responsiveHeight,
    double Function(double) responsiveFontSize,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: responsiveWidth(0.15),
              height: responsiveWidth(0.15),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                color: skyBlue,
              ),
            ),
            SizedBox(height: responsiveHeight(0.02)),
            Text(
              "Loading your requests...",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : theme.hintColor,
                fontSize: responsiveFontSize(16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(responsiveWidth(0.04)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(responsiveWidth(0.05)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: responsiveWidth(0.15),
                  color: Colors.red,
                ),
              ),
              SizedBox(height: responsiveHeight(0.02)),
              Text(
                "Failed to load requests",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: responsiveFontSize(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: responsiveHeight(0.01)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsiveWidth(0.1)),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : theme.hintColor,
                    fontSize: responsiveFontSize(14),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: responsiveHeight(0.02)),
              ScaleTransition(
                scale: _pulseAnimation,
                child: ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        responsiveWidth(0.025),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: responsiveWidth(0.06),
                      vertical: responsiveHeight(0.015),
                    ),
                  ),
                  child: Text(
                    "Try Again",
                    style: TextStyle(
                      fontSize: responsiveFontSize(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == "Travel"
                  ? Icons.flight_takeoff_rounded
                  : _selectedFilter == "Leave"
                  ? Icons.beach_access_rounded
                  : Icons.inbox_outlined,
              size: responsiveWidth(0.2),
              color: isDark ? Colors.grey[600] : theme.hintColor,
            ),
            SizedBox(height: responsiveHeight(0.02)),
            Text(
              _selectedFilter == "All"
                  ? "No requests found"
                  : "No $_selectedFilter requests",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : theme.hintColor,
                fontSize: responsiveFontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: responsiveHeight(0.01)),
            if (_searchController.text.isNotEmpty || _selectedFilter != "All")
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onFilterChanged("All");
                },
                style: TextButton.styleFrom(foregroundColor: skyBlue),
                child: Text(
                  "Clear filters",
                  style: TextStyle(
                    fontSize: responsiveFontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchAllRequests(showLoading: false);
      },
      color: skyBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          bottom: responsiveHeight(0.15),
          top: responsiveHeight(0.01),
        ),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final request = _filteredRequests[index];
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 500 + (index * 50)),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              final double clampedValue = value.clamp(0.0, 1.0);
              return Opacity(
                opacity: clampedValue,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    responsiveHeight(0.02) * (1 - clampedValue),
                  ),
                  child: child,
                ),
              );
            },
            child: _buildRequestCard(
              request,
              theme,
              isDark,
              screenWidth,
              screenHeight,
              responsiveWidth,
              responsiveHeight,
              responsiveFontSize,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> request,
    ThemeData theme,
    bool isDark,
    double screenWidth,
    double screenHeight,
    double Function(double) responsiveWidth,
    double Function(double) responsiveHeight,
    double Function(double) responsiveFontSize,
  ) {
    final type = request["type"];
    final data = request["data"];
    final title = request["title"];
    final status = request["status"];
    final statusColor = request["status_color"];
    final statusBgColor = request["status_bg_color"];
    final icon = request["icon"];
    final iconColor = request["icon_color"];
    final isLogged = request["is_logged"] ?? false;
    final employeeName = request["employee_name"] ?? request["employee"] ?? "";
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsiveWidth(0.04),
        vertical: responsiveWidth(0.015),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
          boxShadow: [
            BoxShadow(
              color: skyBlue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: isDark ? slate : pureWhite,
          borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
          child: InkWell(
            onTap: () {
              if (type == "leave") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LeaveDetailScreen(leave: data as LeaveApprovedModel),
                  ),
                );
              } else if (type == "travel") {
                final Map<String, dynamic> convertedData =
                    Map<String, dynamic>.from(data);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TravelDetailScreen(travelData: convertedData),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
            child: Padding(
              padding: EdgeInsets.all(responsiveWidth(0.04)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: responsiveWidth(0.1),
                              height: responsiveWidth(0.1),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                size: responsiveWidth(0.05),
                                color: iconColor,
                              ),
                            ),
                            SizedBox(width: responsiveWidth(0.03)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type == "leave"
                                        ? "LEAVE REQUEST"
                                        : "TRAVEL REQUEST",
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: responsiveFontSize(11),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: responsiveHeight(0.005)),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: responsiveFontSize(16),
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (employeeName.isNotEmpty)
                                    Text(
                                      "Employee: $employeeName",
                                      style: TextStyle(
                                        fontSize: responsiveFontSize(13),
                                        color: subtitleColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsiveWidth(0.03),
                              vertical: responsiveWidth(0.015),
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: responsiveFontSize(11),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: responsiveHeight(0.01)),
                          Row(
                            children: [
                              Icon(
                                isLogged
                                    ? Icons.cloud_done_rounded
                                    : Icons.cloud_off_rounded,
                                size: responsiveWidth(0.03),
                                color: isLogged ? Colors.green : Colors.grey,
                              ),
                              SizedBox(width: responsiveWidth(0.01)),
                              Text(
                                isLogged ? "Logged" : "Not Logged",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(10),
                                  color: isLogged ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: responsiveHeight(0.04)),

                  Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),

                  SizedBox(height: responsiveHeight(0.04)),

                  if (type == "leave")
                    _buildLeaveDetails(
                      data as LeaveApprovedModel,
                      theme,
                      isDark,
                      screenWidth,
                      responsiveWidth,
                      responsiveHeight,
                      responsiveFontSize,
                    )
                  else
                    _buildTravelDetails(
                      request,
                      theme,
                      isDark,
                      screenWidth,
                      responsiveWidth,
                      responsiveHeight,
                      responsiveFontSize,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveDetails(
    LeaveApprovedModel leave,
    ThemeData theme,
    bool isDark,
    double screenWidth,
    double Function(double) responsiveWidth,
    double Function(double) responsiveHeight,
    double Function(double) responsiveFontSize,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EMPLOYEE",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: responsiveFontSize(10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(0.01)),
                  Text(
                    leave.employeeName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: responsiveFontSize(14),
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: responsiveWidth(0.04)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FROM DATE",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: responsiveFontSize(10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(0.01)),
                  Text(
                    leave.fromDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: responsiveFontSize(14),
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsiveWidth(0.04)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TO DATE",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: responsiveFontSize(10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(0.01)),
                  Text(
                    leave.toDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: responsiveFontSize(14),
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsiveHeight(0.03)),
        if (leave.reason.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "REASON",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: responsiveFontSize(10),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: responsiveHeight(0.01)),
              Text(
                leave.reason,
                style: TextStyle(
                  fontSize: responsiveFontSize(14),
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTravelDetails(
    Map<String, dynamic> travel,
    ThemeData theme,
    bool isDark,
    double screenWidth,
    double Function(double) responsiveWidth,
    double Function(double) responsiveHeight,
    double Function(double) responsiveFontSize,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PURPOSE",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: responsiveFontSize(10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(0.01)),
                  Text(
                    travel["purpose_of_travel"] ?? "N/A",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: responsiveFontSize(14),
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            SizedBox(width: responsiveWidth(0.04)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TYPE",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: responsiveFontSize(10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(0.01)),
                  Text(
                    travel["travel_type"] ?? "N/A",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: responsiveFontSize(14),
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsiveHeight(0.03)),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FUNDING",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: responsiveFontSize(10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(0.01)),
                  Text(
                    travel["travel_funding"] ?? "N/A",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: responsiveFontSize(14),
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsiveWidth(0.04)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REQUESTED ON",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: responsiveFontSize(10),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: responsiveHeight(0.01)),
                  Text(
                    travel["posting_date"]?.toString().split(" ")[0] ?? "N/A",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: responsiveFontSize(14),
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFabOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    required double screenWidth,
    required double Function(double) responsiveWidth,
    required double Function(double) responsiveHeight,
    required double Function(double) responsiveFontSize,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsiveWidth(0.04),
          vertical: responsiveWidth(0.03),
        ),
        decoration: BoxDecoration(
          color: isDark ? slate : pureWhite,
          borderRadius: BorderRadius.circular(responsiveWidth(0.06)),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: responsiveWidth(0.09),
              height: responsiveWidth(0.09),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: responsiveWidth(0.05)),
            ),
            SizedBox(width: responsiveWidth(0.03)),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: responsiveFontSize(15),
                color: textColor,
              ),
            ),
            SizedBox(width: responsiveWidth(0.02)),
          ],
        ),
      ),
    );
  }
}