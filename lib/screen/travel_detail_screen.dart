// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TravelDetailScreen extends StatelessWidget {
  final Map<String, dynamic> travelData;

  const TravelDetailScreen({super.key, required this.travelData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    double responsiveWidth(double percentage) => screenWidth * percentage;
    double responsiveHeight(double percentage) => screenHeight * percentage;
    double responsiveFontSize(double baseSize) => baseSize * (screenWidth / 375);

    const Color skyBlue = Color(0xFF87CEEB);
    const Color deepSky = Color(0xFF00A5E0);
    const Color offWhite = Color(0xFFF8FAFC);
    const Color pureWhite = Color(0xFFFFFFFF);
    const Color charcoal = Color(0xFF1E293B);
    const Color slate = Color(0xFF334155);

    final backgroundColor = isDark ? charcoal : offWhite;
    final cardColor = isDark ? slate : pureWhite;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    String formatDate(dynamic dateValue) {
      if (dateValue == null) return "";
      final dateStr = dateValue.toString();
      if (dateStr.isEmpty) return "";
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        return dateStr;
      }
    }

    String formatDateTime(dynamic dateTimeValue) {
      if (dateTimeValue == null) return "";
      final dateTimeStr = dateTimeValue.toString();
      if (dateTimeStr.isEmpty) return "";
      
      try {
        if (dateTimeStr.contains('T')) {
          final date = DateTime.parse(dateTimeStr);
          return DateFormat('dd MMM yyyy • hh:mm a').format(date);
        } else if (dateTimeStr.contains(' ')) {
          final parts = dateTimeStr.split(' ');
          if (parts.length >= 2) {
            final datePart = parts[0];
            final timePart = parts[1];
            
            List<String> dateComponents;
            if (datePart.contains('-')) {
              dateComponents = datePart.split('-');
            } else {
              return dateTimeStr;
            }
            
            if (dateComponents.length == 3) {
              int day, month, year;
              if (dateComponents[0].length == 4) {
                year = int.parse(dateComponents[0]);
                month = int.parse(dateComponents[1]);
                day = int.parse(dateComponents[2]);
              } else {
                day = int.parse(dateComponents[0]);
                month = int.parse(dateComponents[1]);
                year = int.parse(dateComponents[2]);
              }
              
              final timeComponents = timePart.split(':');
              final hour = int.parse(timeComponents[0]);
              final minute = int.parse(timeComponents[1]);
              
              final date = DateTime(year, month, day, hour, minute);
              return DateFormat('dd MMM yyyy • hh:mm a').format(date);
            }
          }
        }
        return dateTimeStr;
      } catch (e) {
        return dateTimeStr;
      }
    }

    Color getStatusColor(String status) {
      final statusLower = status.toLowerCase();
      if (statusLower.contains("approved")) return Colors.green;
      if (statusLower.contains("rejected")) return Colors.red;
      if (statusLower.contains("cancelled")) return Colors.grey;
      return skyBlue;
    }

    final status = travelData["status"] ?? "";
    final statusColor = getStatusColor(status);

    // Get itinerary from travelData
    List<Map<String, dynamic>> itineraryList = [];
    
    if (travelData["itinerary_list"] is List && travelData["itinerary_list"].isNotEmpty) {
      itineraryList = List<Map<String, dynamic>>.from(travelData["itinerary_list"]);
    } else if (travelData["itinerary"] is List && travelData["itinerary"].isNotEmpty) {
      itineraryList = List<Map<String, dynamic>>.from(travelData["itinerary"]);
    } else if (travelData["data"] != null && travelData["data"]["itinerary"] is List) {
      final rawItinerary = travelData["data"]["itinerary"] as List;
      for (var leg in rawItinerary) {
        if (leg is Map<String, dynamic> && leg.isNotEmpty) {
          itineraryList.add(leg);
        }
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveWidth(0.05),
                vertical: responsiveHeight(0.02),
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [skyBlue, deepSky],
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
                children: [
                  IconButton(
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
                  SizedBox(width: responsiveWidth(0.03)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Travel Request",
                          style: TextStyle(
                            fontSize: responsiveFontSize(22),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (travelData["employee_name"] != null)
                          Text(
                            travelData["employee_name"].toString(),
                            style: TextStyle(
                              fontSize: responsiveFontSize(14),
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(responsiveWidth(0.04)),
                child: Column(
                  children: [
                    // Status Card
                    if (status.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(responsiveWidth(0.04)),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
                          border: Border.all(
                            color: skyBlue.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: skyBlue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(responsiveWidth(0.03)),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_rounded,
                                color: statusColor,
                                size: responsiveWidth(0.07),
                              ),
                            ),
                            SizedBox(width: responsiveWidth(0.04)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Current Status",
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(12),
                                      color: subtitleColor,
                                    ),
                                  ),
                                  SizedBox(height: responsiveHeight(0.005)),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(18),
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (status.isNotEmpty)
                      SizedBox(height: responsiveHeight(0.025)),

                    // Request Details
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(responsiveWidth(0.04)),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
                        border: Border.all(
                          color: skyBlue.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: skyBlue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(responsiveWidth(0.02)),
                                decoration: BoxDecoration(
                                  color: skyBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.description_rounded,
                                  color: skyBlue,
                                  size: responsiveWidth(0.06),
                                ),
                              ),
                              SizedBox(width: responsiveWidth(0.03)),
                              Text(
                                "Request Details",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(16),
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsiveHeight(0.02)),
                          if (travelData["purpose_of_travel"] != null && travelData["purpose_of_travel"].toString().isNotEmpty) ...[
                            _buildDetailItem(
                              label: "Purpose of Travel",
                              value: travelData["purpose_of_travel"].toString(),
                              icon: Icons.travel_explore,
                              color: skyBlue,
                              responsiveWidth: responsiveWidth,
                              responsiveFontSize: responsiveFontSize,
                            ),
                            _buildDivider(isDark),
                          ],
                          if (travelData["travel_type"] != null && travelData["travel_type"].toString().isNotEmpty) ...[
                            _buildDetailItem(
                              label: "Travel Type",
                              value: travelData["travel_type"].toString(),
                              icon: Icons.flight_takeoff,
                              color: deepSky,
                              responsiveWidth: responsiveWidth,
                              responsiveFontSize: responsiveFontSize,
                            ),
                            _buildDivider(isDark),
                          ],
                          if (travelData["travel_funding"] != null && travelData["travel_funding"].toString().isNotEmpty)
                            _buildDetailItem(
                              label: "Travel Funding",
                              value: travelData["travel_funding"].toString(),
                              icon: Icons.account_balance_wallet,
                              color: Colors.green,
                              responsiveWidth: responsiveWidth,
                              responsiveFontSize: responsiveFontSize,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsiveHeight(0.025)),

                    // Itinerary Section
                    if (itineraryList.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(responsiveWidth(0.04)),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
                          border: Border.all(
                            color: skyBlue.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: skyBlue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(responsiveWidth(0.02)),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.route_rounded,
                                    color: Colors.orange,
                                    size: responsiveWidth(0.06),
                                  ),
                                ),
                                SizedBox(width: responsiveWidth(0.03)),
                                Text(
                                  "Travel Itinerary",
                                  style: TextStyle(
                                    fontSize: responsiveFontSize(16),
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: responsiveHeight(0.02)),
                            
                            // Table Header
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsiveWidth(0.02),
                                vertical: responsiveHeight(0.01),
                              ),
                              decoration: BoxDecoration(
                                color: skyBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(responsiveWidth(0.02)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "From",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: responsiveFontSize(12),
                                        color: skyBlue,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "To",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: responsiveFontSize(12),
                                        color: skyBlue,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Mode",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: responsiveFontSize(12),
                                        color: skyBlue,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "Departure",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: responsiveFontSize(12),
                                        color: skyBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Itinerary Rows
                            ...itineraryList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final itinerary = entry.value;
                              
                              final from = itinerary["travel_from"] ?? itinerary["from"] ?? "";
                              final to = itinerary["travel_to"] ?? itinerary["to"] ?? "";
                              final mode = itinerary["mode_of_travel"] ?? itinerary["mode"] ?? "";
                              final dateTime = itinerary["departure_datetime"] ?? 
                                               itinerary["departure_date"] ?? 
                                               itinerary["date"] ?? "";
                              
                              return Column(
                                children: [
                                  SizedBox(height: responsiveHeight(0.015)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsiveWidth(0.02),
                                      vertical: responsiveHeight(0.01),
                                    ),
                                    decoration: BoxDecoration(
                                      color: index % 2 == 0
                                          ? (isDark ? slate.withOpacity(0.3) : offWhite)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(responsiveWidth(0.02)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            from.toString(),
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(13),
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            to.toString(),
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(13),
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            mode.toString(),
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(13),
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            dateTime.toString().isNotEmpty 
                                                ? formatDateTime(dateTime) 
                                                : "",
                                            style: TextStyle(
                                              fontSize: responsiveFontSize(13),
                                              fontWeight: FontWeight.w500,
                                              color: deepSky,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),

                    if (itineraryList.isNotEmpty)
                      SizedBox(height: responsiveHeight(0.025)),

                    // Date Information
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(responsiveWidth(0.04)),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
                        border: Border.all(
                          color: skyBlue.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: skyBlue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(responsiveWidth(0.02)),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.purple,
                                  size: responsiveWidth(0.06),
                                ),
                              ),
                              SizedBox(width: responsiveWidth(0.03)),
                              Text(
                                "Date Information",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(16),
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsiveHeight(0.02)),
                          if (travelData["creation"] != null) ...[
                            _buildDetailItem(
                              label: "Created Date",
                              value: formatDate(travelData["creation"]),
                              icon: Icons.edit_calendar,
                              color: Colors.purple,
                              responsiveWidth: responsiveWidth,
                              responsiveFontSize: responsiveFontSize,
                            ),
                            _buildDivider(isDark),
                          ],
                          if (travelData["posting_date"] != null)
                            _buildDetailItem(
                              label: "Posting Date",
                              value: formatDate(travelData["posting_date"]),
                              icon: Icons.post_add,
                              color: Colors.teal,
                              responsiveWidth: responsiveWidth,
                              responsiveFontSize: responsiveFontSize,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsiveHeight(0.025)),

                    // Reference Information
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(responsiveWidth(0.04)),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(responsiveWidth(0.04)),
                        border: Border.all(
                          color: skyBlue.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: skyBlue.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(responsiveWidth(0.02)),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.confirmation_number_rounded,
                                  color: Colors.amber,
                                  size: responsiveWidth(0.06),
                                ),
                              ),
                              SizedBox(width: responsiveWidth(0.03)),
                              Text(
                                "Reference Information",
                                style: TextStyle(
                                  fontSize: responsiveFontSize(16),
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsiveHeight(0.02)),
                          if (travelData["name"] != null) ...[
                            _buildDetailItem(
                              label: "Document ID",
                              value: travelData["name"].toString(),
                              icon: Icons.numbers,
                              color: Colors.amber,
                              responsiveWidth: responsiveWidth,
                              responsiveFontSize: responsiveFontSize,
                            ),
                            _buildDivider(isDark),
                          ],
                          if (travelData["employee"] != null)
                            _buildDetailItem(
                              label: "Employee ID",
                              value: travelData["employee"].toString(),
                              icon: Icons.badge,
                              color: Colors.cyan,
                              responsiveWidth: responsiveWidth,
                              responsiveFontSize: responsiveFontSize,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsiveHeight(0.03)),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: responsiveHeight(0.065),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: skyBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(responsiveWidth(0.03)),
                          ),
                          elevation: 5,
                          shadowColor: skyBlue.withOpacity(0.5),
                        ),
                        child: Text(
                          "Close",
                          style: TextStyle(
                            fontSize: responsiveFontSize(16),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: responsiveHeight(0.02)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double Function(double) responsiveWidth,
    required double Function(double) responsiveFontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsiveWidth(0.01)),
      child: Row(
        children: [
          Container(
            width: responsiveWidth(0.12),
            height: responsiveWidth(0.12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: responsiveWidth(0.05),
            ),
          ),
          SizedBox(width: responsiveWidth(0.03)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsiveFontSize(12),
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsiveWidth(0.01)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsiveFontSize(15),
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      ),
    );
  }
}