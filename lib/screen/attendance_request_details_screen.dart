

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:management_app/services/attendance_request_service.dart';
import 'package:intl/intl.dart';

class AttendanceRequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  
  const AttendanceRequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<AttendanceRequestDetailsScreen> createState() => _AttendanceRequestDetailsScreenState();
}

class _AttendanceRequestDetailsScreenState extends State<AttendanceRequestDetailsScreen> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _loadRequestDetails();
  }

  Future<void> _loadRequestDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await AttendanceRequestService().getRequestDetails(widget.requestId);
      setState(() {
        _comments = data["comments"] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      if (dateTimeString.isEmpty) return "Not Available";
      DateTime? dateTime = DateTime.tryParse(dateTimeString);
      return dateTime != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dateTime) : dateTimeString;
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _isDarkMode ? Colors.white : Colors.grey[900],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _isDarkMode ? Colors.blue[800]! : Colors.blue[100]!,
                child: Text(
                  comment["comment_by"]?.toString().substring(0, 1).toUpperCase() ?? "U",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isDarkMode ? Colors.white : Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment["comment_by"] ?? "System",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    Text(
                      _formatDateTime(comment["creation"] ?? ""),
                      style: TextStyle(
                        fontSize: 11,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (comment["comment_type"] ?? "Comment") == "Comment"
                      ? Colors.blue.withOpacity(_isDarkMode ? 0.2 : 0.1)
                      : Colors.green.withOpacity(_isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  comment["comment_type"] ?? "Comment",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: (comment["comment_type"] ?? "Comment") == "Comment"
                        ? Colors.blue
                        : Colors.green,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              comment["content"] ?? "",
              style: TextStyle(
                fontSize: 13,
                color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final statusColor = widget.requestData["color"] as Color? ?? Colors.blue;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.requestData["status"] ?? "N/A",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.content_copy,
                  size: 18,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Request ID",
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        widget.requestId,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode ? Colors.white : Colors.grey[900],
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(widget.requestData["date"] ?? ""),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[900] : Colors.white,
                border: Border(
                  bottom: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: _isDarkMode ? Colors.white : Colors.grey[900]),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                    ),
                    Text(
                      "Request Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: _isDarkMode ? Colors.white : Colors.grey[900]),
                      onPressed: _isLoading ? null : _loadRequestDetails,
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
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: _isDarkMode ? Colors.blue[400] : Colors.blue[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Loading details...",
                            style: TextStyle(
                              fontSize: 16,
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Failed to Load",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  _errorMessage.length > 100 ? "${_errorMessage.substring(0, 100)}..." : _errorMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadRequestDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        )
                      : CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(child: _buildStatusHeader()),
                            SliverPadding(
                              padding: const EdgeInsets.all(24),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Request Information",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: _isDarkMode ? Colors.white : Colors.grey[900],
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Detailed information about this attendance request",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildDetailRow(
                                      "Employee Name",
                                      widget.requestData["employee_name"] ?? "Not Available",
                                      Icons.person,
                                    ),
                                    _buildDetailRow(
                                      "From Date",
                                      _formatDateTime(widget.requestData["from_date"] ?? ""),
                                      Icons.calendar_today,
                                    ),
                                    _buildDetailRow(
                                      "To Date",
                                      _formatDateTime(widget.requestData["to_date"] ?? ""),
                                      Icons.calendar_today,
                                    ),
                                    _buildDetailRow(
                                      "Reason",
                                      widget.requestData["reason"] ?? "Not Available",
                                      Icons.info,
                                    ),
                                    if ((widget.requestData["explanation"] ?? "").isNotEmpty)
                                      _buildDetailRow(
                                        "Explanation",
                                        widget.requestData["explanation"] ?? "",
                                        Icons.description,
                                      ),
                                    _buildDetailRow(
                                      "Created On",
                                      _formatDateTime(widget.requestData["created_date"] ?? ""),
                                      Icons.access_time,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_comments.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Comments & Notes",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: _isDarkMode ? Colors.white : Colors.grey[900],
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "${_comments.length} ${_comments.length == 1 ? 'Comment' : 'Comments'}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            if (_comments.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildCommentItem(_comments[index], index),
                                    childCount: _comments.length,
                                  ),
                                ),
                              ),
                            const SliverToBoxAdapter(child: SizedBox(height: 40)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
