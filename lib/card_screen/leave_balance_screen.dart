// ignore_for_file: deprecated_member_use, unused_local_variable, unused_field

import 'package:flutter/material.dart';
import 'package:management_app/services/leave_balance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class LeaveBalanceScreen extends StatefulWidget {
  const LeaveBalanceScreen({super.key});

  @override
  State<LeaveBalanceScreen> createState() => _LeaveBalanceScreenState();
}

class _LeaveBalanceScreenState extends State<LeaveBalanceScreen>
    with TickerProviderStateMixin {
  final LeaveBalanceService _leaveService = LeaveBalanceService();
  
  Map<String, Map<String, double>> _leaveDetails = {};
  Map<String, double> _totals = {
    'allocated': 0,
    'taken': 0,
    'remaining': 0,
  };
  
  bool _isLoading = true;
  String? _errorMessage;
  String? _employeeName;
  String? _employeeId;
  String? _employeeImage;
  bool _needsLogin = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;

  final List<Color> _gradientColors = [
    const Color(0xFF4158D0),
    const Color(0xFFC850C0),
    const Color(0xFFFFCC70),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _loadEmployeeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _employeeName = prefs.getString('employeeName') ?? 
                      prefs.getString('employee_name') ?? 
                      prefs.getString('full_name') ??
                      'Employee';
      
      _employeeId = prefs.getString('employeeId') ?? 
                    prefs.getString('employee_id') ?? 
                    prefs.getString('emp_code');
      
      _employeeImage = prefs.getString('user_image');
      
      setState(() {});
      
      debugPrint('👤 Loaded: $_employeeName (ID: $_employeeId)');
      await _loadLeaveData();
    } catch (e) {
      debugPrint('Error: $e');
      await _loadLeaveData();
    }
  }

  Future<void> _loadLeaveData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _needsLogin = false;
    });

    try {
      final result = await _leaveService.fetchLeaveBalances();
      
      if (mounted) {
        if (result['success'] == true) {
          final leaveDetails = Map<String, Map<String, double>>.from(
            result['leaveDetails'] ?? {}
          );
          
          setState(() {
            _leaveDetails = leaveDetails;
            _totals = Map<String, double>.from(
              result['totals'] ?? {'allocated': 0, 'taken': 0, 'remaining': 0}
            );
            _isLoading = false;
          });
          
          _animationController.forward();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load leave data';
            _needsLogin = result['needsLogin'] == true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Returns Annual Leave and Sick Leave cards based on API response keys.
  List<Map<String, dynamic>> get _leaveTypes {
    if (_leaveDetails.isEmpty) return [];

    final List<Map<String, dynamic>> result = [];

    // ── 1. Annual Leave ──────────────────────────────────────────────────────
    final annualKey = _leaveDetails.keys.firstWhere(
      (k) {
        final lower = k.toLowerCase();
        return lower.contains('annual') ||
            lower.contains('earned') ||
            lower.contains('privilege');
      },
      orElse: () => '',
    );

    if (annualKey.isNotEmpty) {
      result.add({
        'key': annualKey,
        'title': 'Annual Leave',
        'icon': Icons.beach_access,
        'gradient': const [Color(0xFF4158D0), Color(0xFFC850C0)],
        'lightColor': const Color(0xFF4158D0).withOpacity(0.1),
      });
    }

    // ── 2. Sick Leave ────────────────────────────────────────────────────────
    final sickKey = _leaveDetails.keys.firstWhere(
      (k) {
        final lower = k.toLowerCase();
        return lower.contains('sick') || lower.contains('medical');
      },
      orElse: () => '',
    );

    if (sickKey.isNotEmpty) {
      result.add({
        'key': sickKey,
        'title': 'Sick Leave',
        'icon': Icons.medical_services,
        'gradient': const [Color(0xFFFFA726), Color(0xFFFF7043)],
        'lightColor': const Color(0xFFFFA726).withOpacity(0.1),
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isTablet = size.width > 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.grey[900]! : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF5F7FA),
        body: Stack(
          children: [
            
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.grey[900]!, Colors.grey[850]!]
                        : [Colors.white, const Color(0xFFF5F7FA)],
                  ),
                ),
              ),
            ),
            
            
            ..._buildBackgroundCircles(isDark, size),
            
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadLeaveData,
                color: theme.primaryColor,
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    
                    SliverAppBar(
                      expandedHeight: size.height * 0.18,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: Container(
                        margin: EdgeInsets.all(size.width * 0.02),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800]!.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      actions: [
                        Container(
                          margin: EdgeInsets.all(size.width * 0.02),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800]!.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: isDark ? Colors.white : Colors.grey[800],
                            ),
                            onPressed: _loadLeaveData,
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -50,
                                right: -50,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -30,
                                left: -30,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    
                    SliverPadding(
                      padding: EdgeInsets.all(size.width * 0.04),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          
                          _buildProfileHeader(isDark, size, isTablet),
                          
                          SizedBox(height: size.height * 0.02),

                          
                          if (!_isLoading && _errorMessage == null && !_needsLogin)
                            _buildStatsCards(isDark, size),

                          if (!_isLoading && _errorMessage == null && !_needsLogin)
                            SizedBox(height: size.height * 0.025),

                          
                          if (!_isLoading && _errorMessage == null && !_needsLogin)
                            _buildSectionTitle(isDark, size, 'Leave Breakdown'),

                          if (!_isLoading && _errorMessage == null && !_needsLogin)
                            SizedBox(height: size.height * 0.015),

                          
                          if (_isLoading)
                            _buildLoadingState(isDark, size),

                          
                          if (_errorMessage != null && !_isLoading)
                            _buildErrorState(isDark, size, theme),

                          
                          if (!_isLoading && _errorMessage == null && !_needsLogin && _leaveDetails.isNotEmpty)
                            _buildLeaveCards(isDark, size, isTablet),

                          
                          if (!_isLoading && _errorMessage == null && !_needsLogin && _leaveDetails.isEmpty)
                            _buildNoDataState(isDark, size),

                          SizedBox(height: padding.bottom + size.height * 0.02),
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

  List<Widget> _buildBackgroundCircles(bool isDark, Size size) {
    return [
      Positioned(
        top: -size.width * 0.4,
        right: -size.width * 0.2,
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -size.width * 0.3,
        left: -size.width * 0.2,
        child: Container(
          width: size.width * 0.6,
          height: size.width * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.amber.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildProfileHeader(bool isDark, Size size, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          
          Container(
            width: size.width * 0.15,
            height: size.width * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              image: _employeeImage != null
                  ? DecorationImage(
                      image: NetworkImage(_employeeImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _employeeImage == null
                ? Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: size.width * 0.08,
                  )
                : null,
          ),
          
          SizedBox(width: size.width * 0.04),
          
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  _employeeName ?? 'Employee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_employeeId != null)
                  Text(
                    'ID: $_employeeId',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
              ],
            ),
          ),
          
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.03,
              vertical: size.height * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getFormattedDate(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark, Size size) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Allocated',
            _totals['allocated']?.toStringAsFixed(1) ?? '0',
            Icons.card_giftcard,
            Colors.blue,
            isDark,
            size,
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: _buildStatCard(
            'Taken',
            _totals['taken']?.toStringAsFixed(1) ?? '0',
            Icons.event_busy,
            Colors.orange,
            isDark,
            size,
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: _buildStatCard(
            'Remaining',
            _totals['remaining']?.toStringAsFixed(1) ?? '0',
            Icons.account_balance_wallet,
            Colors.green,
            isDark,
            size,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark, Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: size.width * 0.06),
          SizedBox(height: size.height * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: size.width * 0.03,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, Size size, String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 25,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Text(
          title,
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.03,
            vertical: size.height * 0.005,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '${_leaveTypes.length} Types',
            style: TextStyle(
              fontSize: size.width * 0.03,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCards(bool isDark, Size size, bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: size.width * 0.03,
        mainAxisSpacing: size.height * 0.015,
        childAspectRatio: 0.9,
      ),
      itemCount: _leaveTypes.length,
      itemBuilder: (context, index) {
        final leaveType = _leaveTypes[index];
        final key = leaveType['key'] as String;
        final details = _leaveDetails[key]!;
        
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 500 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: _buildLeaveCard(
                leaveType: leaveType,
                details: details,
                index: index,
                isDark: isDark,
                size: size,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaveCard({
    required Map<String, dynamic> leaveType,
    required Map<String, double> details,
    required int index,
    required bool isDark,
    required Size size,
  }) {
    final remaining = details['remaining'] ?? 0;
    final allocated = details['allocated'] ?? 0;
    final percentage = allocated > 0 ? (remaining / allocated) : 0;
    final gradient = leaveType['gradient'] as List<Color>;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLeaveDetails(
            context,
            leaveType['title'],
            remaining,
            allocated,
            leaveType['icon'],
            gradient.first,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(size.width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            leaveType['icon'],
                            color: Colors.white,
                            size: size.width * 0.05,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.02,
                            vertical: size.height * 0.002,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_getUsagePercentage(remaining, allocated)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    
                    Text(
                      leaveType['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: size.height * 0.005),
                    
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          remaining.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text(
                            'days',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: size.height * 0.01),
                    
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.005),
                    
                    
                    Text(
                      'of ${allocated.toStringAsFixed(1)} days',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, Size size) {
    return SizedBox(
      height: size.height * 0.4,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size.width * 0.15,
                  height: size.width * 0.15,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ),
                ScaleTransition(
                  scale: _pulseController,
                  child: Container(
                    width: size.width * 0.1,
                    height: size.width * 0.1,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.03),
            Text(
              'Fetching your leave data...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              'Please wait',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Size size, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.08),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (_needsLogin ? Colors.orange : Colors.red).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _needsLogin ? Icons.timer_off_rounded : Icons.error_outline_rounded,
            size: size.width * 0.15,
            color: _needsLogin ? Colors.orange : Colors.red,
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            _needsLogin ? 'Session Expired' : 'Oops! Something went wrong',
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _needsLogin ? Colors.orange : Colors.red,
              fontSize: size.width * 0.035,
            ),
          ),
          SizedBox(height: size.height * 0.03),
          SizedBox(
            width: size.width * 0.5,
            child: ElevatedButton(
              onPressed: _needsLogin 
                  ? () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false)
                  : _loadLeaveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _needsLogin ? Colors.orange : Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(_needsLogin ? 'Login Again' : 'Try Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(bool isDark, Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.08),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: size.width * 0.15,
            color: Colors.grey,
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'No Leave Allocations',
            style: TextStyle(
              fontSize: size.width * 0.045,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            'No leave records found for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: size.width * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveDetails(BuildContext context, String title, double remaining, double allocated, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final taken = allocated - remaining;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.all(size.width * 0.05),
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 32),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailItem('Allocated', allocated, Colors.blue, size),
                            _buildDetailItem('Taken', taken, Colors.orange, size),
                            _buildDetailItem('Remaining', remaining, Colors.green, size),
                          ],
                        ),
                        SizedBox(height: size.height * 0.03),
                        Container(
                          padding: EdgeInsets.all(size.width * 0.04),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Utilization Rate',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${_getUsagePercentage(remaining, allocated)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height * 0.01),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (allocated > 0 ? (taken / allocated) : 0.0).toDouble().clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 6,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, double value, Color color, Size size) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        SizedBox(height: size.height * 0.005),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]}, ${now.year}';
  }

  int _getUsagePercentage(double remaining, double allocated) {
    if (allocated == 0) return 0;
    final used = allocated - remaining;
    return ((used / allocated) * 100).round().clamp(0, 100);
  }
}