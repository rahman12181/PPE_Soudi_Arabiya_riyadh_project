// lib/screens/support_screen.dart
// Premium Support Screen with HomemainScreen color palette

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/support_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  String? _selectedQueryType;
  final TextEditingController _descriptionController = TextEditingController();
  File? _screenshot;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  int _selectedTab = 0;
  final SupportService _supportService = SupportService();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Focus nodes for form fields
  final FocusNode _descriptionFocusNode = FocusNode();
  
  // Color palette - Matching HomemainScreen Sky Blue Theme
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color lightSky = Color(0xFFE0F2FE);
  static const Color mediumSky = Color(0xFF7EC8E0);
  static const Color deepSky = Color(0xFF00A5E0);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color slate = Color(0xFF334155);
  static const Color steel = Color(0xFF475569);
  
  final List<Map<String, dynamic>> _queryTypes = [
    {'title': 'App Crash', 'icon': Icons.bug_report, 'color': const Color(0xFFEF4444)},
    {'title': 'Login Issue', 'icon': Icons.login, 'color': const Color(0xFFF59E0B)},
    {'title': 'Scan QR Not Working', 'icon': Icons.qr_code_scanner, 'color': const Color(0xFF8B5CF6)},
    {'title': 'Assessment Not Loading', 'icon': Icons.assessment, 'color': const Color(0xFFEC4899)},
    {'title': 'Slow Performance', 'icon': Icons.speed, 'color': const Color(0xFF10B981)},
    {'title': 'Other Issue', 'icon': Icons.help_outline, 'color': const Color(0xFF6B7280)},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    HapticFeedback.lightImpact();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
        final sizeInBytes = await file.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);
        
        if (sizeInMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image size should be less than 5MB'),
                backgroundColor: Colors.red.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          return;
        }
        
        setState(() {
          _screenshot = file;
        });
        
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitSupportQuery() async {
    if (_selectedQueryType == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select an issue type'),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final result = await _supportService.submitQuery(
      queryType: _selectedQueryType!,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      screenshot: _screenshot,
    );

    setState(() => _isSubmitting = false);

    if (result['success']) {
      HapticFeedback.lightImpact();
      await _showPremiumSuccessDialog();
      setState(() {
        _selectedQueryType = null;
        _descriptionController.clear();
        _screenshot = null;
      });
      if (_selectedTab == 1) {
        setState(() {});
      }
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showPremiumSuccessDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [slate, charcoal]
                      : [skyBlue, deepSky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? slate : skyBlue).withOpacity(0.4),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your query has been submitted successfully.\nOur support team will get back to you within 24 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: skyBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Great!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? charcoal : offWhite,
        body: Column(
          children: [
            // Premium App Bar matching HomemainScreen header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [slate, charcoal]
                      : [skyBlue, deepSky],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? slate : skyBlue).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            hoverColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Support Center',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'We\'re here to help you 24/7',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Premium Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? slate : pureWhite,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildPremiumTab('New Query', 0, isDark),
                  _buildPremiumTab('My Queries', 1, isDark),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _selectedTab == 0
                      ? _buildNewQueryForm(isDark, isTablet)
                      : _buildMyQueries(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTab(String title, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            color: isSelected ? skyBlue : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: skyBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewQueryForm(bool isDark, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : 20),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, double opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: Card(
                  elevation: isDark ? 2 : 8,
                  shadowColor: skyBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: isDark ? slate : pureWhite,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [skyBlue, deepSky],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.edit_note, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Report an Issue',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : charcoal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Issue Type',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedQueryType != null 
                                  ? skyBlue 
                                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                              width: 2,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedQueryType,
                              hint: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.grey.shade400),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Select issue type',
                                      style: TextStyle(color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              isExpanded: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              dropdownColor: isDark ? slate : pureWhite,
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: skyBlue),
                              items: _queryTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type['title'] as String,
                                  child: Row(
                                    children: [
                                      Icon(type['icon'] as IconData, color: type['color'] as Color, size: 20),
                                      const SizedBox(width: 12),
                                      Text(type['title'] as String),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedQueryType = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocusNode,
                          maxLines: 5,
                          maxLength: 500,
                          style: TextStyle(color: isDark ? Colors.white : charcoal),
                          decoration: InputDecoration(
                            hintText: 'Please describe your issue in detail...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: skyBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? charcoal : offWhite,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Screenshot (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickScreenshot,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _screenshot != null 
                                    ? skyBlue 
                                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                width: _screenshot != null ? 2 : 1,
                              ),
                              color: isDark ? charcoal : offWhite,
                            ),
                            child: _screenshot != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(_screenshot!, fit: BoxFit.cover),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.5),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              setState(() => _screenshot = null);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.image, color: Colors.white, size: 16),
                                                SizedBox(width: 4),
                                                Text('Screenshot', style: TextStyle(color: Colors.white, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, size: 48, color: skyBlue),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to upload screenshot',
                                        style: TextStyle(
                                          color: skyBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'PNG, JPG up to 5MB',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, double opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitSupportQuery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skyBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Submitting...',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded),
                              SizedBox(width: 12),
                              Text('Submit Query', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyQueries(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        setState(() {});
      },
      color: skyBlue,
      child: FutureBuilder<List<dynamic>>(
        future: _supportService.getMyQueries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading(isDark);
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load queries',
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skyBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildPremiumEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final query = snapshot.data![index];
              return TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, double opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: _buildQueryCard(query, isDark),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQueryCard(Map<String, dynamic> query, bool isDark) {
    final status = query['status'] ?? 'Pending';
    final statusColor = status == 'Resolved' 
        ? Colors.green 
        : (status == 'In Progress' ? Colors.orange : skyBlue);
    final statusIcon = status == 'Resolved' 
        ? Icons.check_circle_rounded 
        : (status == 'In Progress' ? Icons.hourglass_top : Icons.pending_rounded);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 4,
      shadowColor: skyBlue.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? slate : pureWhite,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showPremiumQueryDetails(query, isDark),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query['queryType'] ?? 'Unknown Issue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        query['description'] ?? 'No description provided',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(query['createdAt']),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPremiumQueryDetails(Map<String, dynamic> query, bool isDark) {
    final status = query['status'] ?? 'Pending';
    final statusColor = status == 'Resolved' 
        ? Colors.green 
        : (status == 'In Progress' ? Colors.orange : skyBlue);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? slate : pureWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            status == 'Resolved' 
                                ? Icons.check_circle_rounded 
                                : (status == 'In Progress' ? Icons.hourglass_top : Icons.pending_rounded),
                            color: statusColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                query['queryType'] ?? 'Issue',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : charcoal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? charcoal : offWhite,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        query['description'] ?? 'No description provided',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.white : charcoal,
                        ),
                      ),
                    ),
                    if (query['adminResponse'] != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Response from Support Team',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              skyBlue.withOpacity(0.1),
                              deepSky.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: skyBlue.withOpacity(0.3)),
                        ),
                        child: Text(
                          query['adminResponse'],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.white : charcoal,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? slate : pureWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, double value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [skyBlue.withOpacity(0.1), deepSky.withOpacity(0.05)],
                ),
              ),
              child: Icon(
                Icons.support_agent_outlined,
                size: 100,
                color: skyBlue.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Support Queries Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your reported issues will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _selectedTab = 0);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Report New Issue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: skyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      DateTime parsed = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsed);
      
      if (difference.inDays == 0) {
        return 'Today, ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      }
    } catch (e) {
      return '';
    }
  }
}