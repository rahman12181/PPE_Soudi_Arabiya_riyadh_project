// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:management_app/services/attendance_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'attendance_request_details_screen.dart';
import 'package:flutter/services.dart';

class AttendanceRequestsListScreen extends StatefulWidget {
  const AttendanceRequestsListScreen({super.key});

  @override
  State<AttendanceRequestsListScreen> createState() => _AttendanceRequestsListScreenState();
}

class _AttendanceRequestsListScreenState extends State<AttendanceRequestsListScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _employeeName = '';
  bool _isRefreshing = false;
  late bool _isDarkMode;

  
  static const Color skyBlue = Color(0xFF87CEEB);  
  static const Color lightSky = Color(0xFFE0F2FE);  
  static const Color mediumSky = Color(0xFF7EC8E0);  
  static const Color deepSky = Color(0xFF00A5E0);    
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAttendanceRequests();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString("employeeName") ?? 'User';
      setState(() => _employeeName = name);
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _loadAttendanceRequests() async {
    if (mounted && !_isRefreshing) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final requests = await AttendanceRequestService().getMyAttendanceRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (mounted) setState(() => _isRefreshing = true);
    await _loadAttendanceRequests();
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty || dateString == "N/A") return "N/A";
      DateTime? date = DateTime.tryParse(dateString.contains("T") ? dateString : "$dateString 00:00:00");
      return date != null ? DateFormat('dd MMM yyyy').format(date) : dateString;
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;  
      case 'pending':
        return skyBlue;  
      default:
        return Colors.grey;
    }
  }

  Widget _buildRequestItem(Map<String, dynamic> request, int index) {
    final statusColor = _getStatusColor(request["status"] ?? "pending");
    
    return Container(
      margin: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 8, 16, index == _requests.length - 1 ? 16 : 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? slate.withOpacity(0.5) : pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skyBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: skyBlue.withOpacity(_isDarkMode ? 0.1 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceRequestDetailsScreen(
                  requestId: request["id"],
                  requestData: request,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: skyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: skyBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  request["title"] ?? "Attendance Request",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isDarkMode ? Colors.white : Colors.grey[900],
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor, width: 1),
                                ),
                                child: Text(
                                  request["status"] ?? "Pending",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(request["date"]),
                            style: TextStyle(
                              fontSize: 13,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if ((request["reason"] ?? "").isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reason",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request["reason"] ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Request ID: ${request["id"]}",
                        style: TextStyle(
                          fontSize: 11,
                          color: _isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          fontFamily: 'RobotoMono',
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: skyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "View Details",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: skyBlue,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: skyBlue,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 48,
                color: skyBlue,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "No Attendance Requests",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "You haven't submitted any attendance requests yet. Create your first request to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Create New Request", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: skyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Unable to Load Requests",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? slate.withOpacity(0.3) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
              ),
              child: Text(
                _errorMessage.length > 150 ? "${_errorMessage.substring(0, 150)}..." : _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text("Go Back"),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _isDarkMode ? Colors.grey[600]! : Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? slate.withOpacity(0.5) : pureWhite,
        border: Border(
          bottom: BorderSide(color: _isDarkMode ? Colors.grey[800]! : skyBlue.withOpacity(0.2)!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [skyBlue, deepSky],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: skyBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.list_alt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Attendance Requests",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Track and manage all your attendance requests",
                      style: TextStyle(
                        fontSize: 13,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: skyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: skyBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _employeeName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: skyBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: skyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered,
                      size: 14,
                      color: skyBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${_requests.length} Request${_requests.length != 1 ? 's' : ''}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: skyBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Status bar color based on theme
    final statusBarColor = _isDarkMode ? charcoal : skyBlue;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: _isDarkMode ? charcoal : pureWhite,
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _isDarkMode ? charcoal : offWhite,
        body: Stack(
          children: [
            // Status bar background - changes with theme
            Container(
              height: MediaQuery.of(context).padding.top,
              width: double.infinity,
              color: statusBarColor,
            ),
            SafeArea(
              top: true,
              bottom: true,
              child: Column(
                children: [
                  // Header with gradient
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isDarkMode 
                            ? [charcoal, slate, const Color(0xFF1E1E2E)]
                            : [skyBlue, deepSky],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: skyBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            splashRadius: 24,
                          ),
                          const Text(
                            "Attendance History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isRefreshing ? Icons.refresh : Icons.refresh,
                              color: Colors.white,
                            ),
                            onPressed: _isRefreshing ? null : _refreshData,
                            splashRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: skyBlue,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Loading your requests...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _errorMessage.isNotEmpty
                            ? _buildErrorState()
                            : _requests.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _refreshData,
                                    color: skyBlue,
                                    backgroundColor: _isDarkMode ? slate : pureWhite,
                                    displacement: 40,
                                    child: CustomScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      slivers: [
                                        SliverToBoxAdapter(child: _buildHeader()),
                                        SliverList(
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) => _buildRequestItem(_requests[index], index),
                                            childCount: _requests.length,
                                          ),
                                        ),
                                        const SliverToBoxAdapter(child: SizedBox(height: 30)),
                                      ],
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
}