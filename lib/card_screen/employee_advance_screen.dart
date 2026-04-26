// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:management_app/screen/advance_history_screen.dart';
import '../../services/employee_advance_service.dart';

class EmployeeAdvanceScreen extends StatefulWidget {
  const EmployeeAdvanceScreen({super.key});

  @override
  State<EmployeeAdvanceScreen> createState() => _EmployeeAdvanceScreenState();
}

class _EmployeeAdvanceScreenState extends State<EmployeeAdvanceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final EmployeeAdvanceService _advanceService = EmployeeAdvanceService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  String? _selectedAccount;
  String? _selectedPaymentMode;
  bool _repayFromSalary = true;

  bool _isSubmitting = false;
  bool _isLoading = false;
  List<String> _accounts = [];
  List<String> _paymentModes = [];
  String _loadingMessage = 'Loading...';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  
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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
      _animationController.forward();
    });
  }

  Future<void> _loadDropdownData() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Loading accounts...';
    });
  }

  try {
    final accountsResult = await _advanceService.getAdvanceAccounts();

    if (accountsResult['success'] == true) {
      final accountsData = accountsResult['data'] as List<dynamic>;
      
      
      var accountsList = accountsData
          .map((item) => item.toString())
          .where((account) => account != "Cash - Petty Cash") 
          .toList();

      final requiredAccounts = [
        "1610 - Employee Advances - PPE",
        "1310 - Debtors - PPE",
        "1611 - Employees Petty cash - PPE",
        "1311 - Retention with Clients - PPE",
      ];

      
      for (var account in requiredAccounts) {
        if (!accountsList.contains(account)) {
          accountsList.add(account);
        }
      }
      
      accountsList.sort();

      setState(() => _loadingMessage = 'Loading payment modes...');
      final paymentModesResult = await _advanceService.getPaymentModes();

      if (paymentModesResult['success'] == true) {
        final paymentModesData = paymentModesResult['data'] as List<dynamic>;
        final paymentModesList = paymentModesData
            .map((item) => item.toString())
            .toList();

        if (!paymentModesList.contains('Credit Card')) {
          paymentModesList.add('Credit Card');
        }

        if (mounted) {
          setState(() {
            _accounts = accountsList;
            _paymentModes = paymentModesList;
            _selectedAccount = accountsList.isNotEmpty
                ? accountsList[0]
                : null;
            _selectedPaymentMode = paymentModesList.isNotEmpty
                ? paymentModesList[0]
                : null;
            _isLoading = false;
          });
        }
      } else {
        _showErrorSnackbar('Failed to load payment modes');
        _setDefaultData();
      }
    } else {
      _showErrorSnackbar('Failed to load accounts');
      _setDefaultData();
    }
  } catch (e) {
    _showErrorSnackbar('Failed to load data: $e');
    _setDefaultData();
  }
}

  void _setDefaultData() {
    if (mounted) {
      setState(() {
        _accounts = [
          "1610 - Employee Advances - PPE",
          "1310 - Debtors - PPE",
          "1611 - Employees Petty cash - PPE",
          "1311 - Retention with Clients - PPE",
        ];
        _paymentModes = ["Cash", "Bank Transfer", "Credit Card"];
        _selectedAccount = _accounts.isNotEmpty ? _accounts[0] : null;
        _selectedPaymentMode = _paymentModes.isNotEmpty
            ? _paymentModes[0]
            : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAdvance() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar('Please fill all required fields correctly');
      return;
    }

    if (_selectedAccount == null || _selectedAccount!.isEmpty) {
      _showErrorSnackbar('Please select an advance account');
      return;
    }

    if (_selectedPaymentMode == null || _selectedPaymentMode!.isEmpty) {
      _showErrorSnackbar('Please select a payment mode');
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showErrorSnackbar('Please enter advance amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showErrorSnackbar('Please enter a valid amount greater than 0');
      return;
    }

    final purpose = _purposeController.text.trim();
    if (purpose.isEmpty) {
      _showErrorSnackbar('Please enter purpose of advance');
      return;
    }

    if (purpose.length < 10) {
      _showErrorSnackbar('Purpose should be at least 10 characters long');
      return;
    }

    final shouldProceed = await _showConfirmationDialog(amount, purpose);
    if (!shouldProceed) {
      return;
    }

    if (mounted) {
      setState(() => _isSubmitting = true);
    }

    try {
      final result = await _advanceService.submitAdvance(
        advanceAmount: amount,
        purpose: purpose,
        advanceAccount: _selectedAccount!,
        modeOfPayment: _selectedPaymentMode!,
        repayFromSalary: _repayFromSalary,
      );

      if (result['success'] == true) {
        await _showSuccessDialog(
          message:
              result['message'] ?? 'Advance request submitted successfully!',
          advanceId: result['advanceId']?.toString() ?? '',
        );
        _resetForm();
      } else {
        await _showErrorDialog(
          message: result['message'] ?? 'Failed to submit advance request',
          error: result['error']?.toString() ?? '',
        );
      }
    } catch (e) {
      await _showErrorDialog(
        message: 'Failed to submit advance request',
        error: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog(double amount, String purpose) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (context) => Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
            ),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.06),
              decoration: BoxDecoration(
                color: isDarkMode ? slate : pureWhite,
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: skyBlue.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.025),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: skyBlue.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: skyBlue,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Text(
                          'Confirm Your Request',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Text(
                    'Please review the details below before submitting:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? slate.withOpacity(0.3)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(color: skyBlue.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildConfirmationRow(
                          context,
                          'Amount:',
                          '﷼ ${amount.toStringAsFixed(2)}', // Changed to Riyal symbol
                          Icons.monetization_on_rounded, // Changed icon
                          skyBlue,
                        ),
                        _buildDivider(screenWidth, isDarkMode),
                        _buildConfirmationRow(
                          context,
                          'Purpose:',
                          purpose,
                          Icons.description_rounded,
                          deepSky,
                        ),
                        _buildDivider(screenWidth, isDarkMode),
                        _buildConfirmationRow(
                          context,
                          'Account:',
                          _selectedAccount ?? '',
                          Icons.account_balance_rounded,
                          mediumSky,
                        ),
                        _buildDivider(screenWidth, isDarkMode),
                        _buildConfirmationRow(
                          context,
                          'Payment Mode:',
                          _selectedPaymentMode ?? '',
                          Icons.payment_rounded,
                          Colors.green,
                        ),
                        _buildDivider(screenWidth, isDarkMode),
                        _buildConfirmationRow(
                          context,
                          'Repayment:',
                          _repayFromSalary
                              ? 'Salary Deduction'
                              : 'Separate Repayment',
                          Icons.account_balance_wallet_rounded,
                          Colors.amber.shade700,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: skyBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(color: skyBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: skyBlue,
                          size: screenWidth * 0.04,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            'Once submitted, this request cannot be modified. Your manager will review and respond within 24-48 hours.',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.035),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                            ),
                            side: BorderSide(
                              color: skyBlue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: skyBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: screenWidth * 0.045,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'CONFIRM',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  fontWeight: FontWeight.w700,
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
          ),
        ) ??
        false;
  }

  Widget _buildConfirmationRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: screenWidth * 0.04),
          ),
          SizedBox(width: screenWidth * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.5),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.grey.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(double screenWidth, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
      ),
    );
  }

  Future<void> _showSuccessDialog({
    required String message,
    required String advanceId,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            color: isDarkMode ? slate : pureWhite,
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: screenWidth * 0.15,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Text(
                'Success!',
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w800,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              if (advanceId.isNotEmpty) ...[
                SizedBox(height: screenHeight * 0.025),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.03,
                  ),
                  decoration: BoxDecoration(
                    color: skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: skyBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.confirmation_number_rounded,
                        color: skyBlue,
                        size: screenWidth * 0.05,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reference ID',
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: skyBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            advanceId,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.grey.shade900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: screenHeight * 0.035),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skyBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: screenWidth * 0.045,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'View History',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        side: BorderSide(
                          color: skyBlue.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white70
                              : Colors.grey.shade700,
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
  }

  Future<void> _showErrorDialog({
    required String message,
    required String error,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            color: isDarkMode ? slate : pureWhite,
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: screenWidth * 0.15,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Text(
                'Error Occurred',
                style: TextStyle(
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? slate.withOpacity(0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(
                      Icons.error_rounded,
                      color: skyBlue,
                      size: screenWidth * 0.05,
                    ),
                    title: Text(
                      'Technical Details',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white70
                            : Colors.grey.shade800,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        margin: EdgeInsets.only(bottom: screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: isDarkMode ? slate : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                        ),
                        child: Text(
                          error,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.red,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.035),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
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

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _purposeController.clear();
    if (mounted) {
      setState(() {
        _selectedAccount = _accounts.isNotEmpty ? _accounts[0] : null;
        _selectedPaymentMode = _paymentModes.isNotEmpty
            ? _paymentModes[0]
            : null;
        _repayFromSalary = true;
      });
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AdvanceHistoryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? charcoal : offWhite,
      body: SafeArea(
        child: Column(
          children: [
            
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.015,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [slate, charcoal]
                          : [skyBlue, deepSky],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: skyBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(screenWidth * 0.01),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.05,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Advance',
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Salary advance application',
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.history_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.065,
                          ),
                          onPressed: _navigateToHistory,
                          tooltip: 'Advance History',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            
            Expanded(
              child: _isLoading
                  ? Center(
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Opacity(opacity: value, child: child);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: screenWidth * 0.15,
                              height: screenWidth * 0.15,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: skyBlue,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Text(
                              _loadingMessage,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.025,
                      ),
                      child: Column(
                        children: [
                          
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.05),
                              margin: EdgeInsets.only(
                                bottom: screenHeight * 0.025,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? slate.withOpacity(0.5)
                                    : pureWhite,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.05,
                                ),
                                border: Border.all(
                                  color: skyBlue.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: skyBlue.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(screenWidth * 0.04),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [skyBlue, deepSky],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: skyBlue.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: screenWidth * 0.07,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.04),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Salary Advance',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.w700,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.grey.shade900,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Text(
                                          'Get instant advance against your salary with 0% interest',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: isDarkMode
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.05),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? slate.withOpacity(0.5)
                                      : pureWhite,
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.05,
                                  ),
                                  border: Border.all(
                                    color: skyBlue.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: skyBlue.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      
                                      _buildFormField(
                                        label: 'Advance Amount',
                                        icon: Icons.monetization_on_rounded, // Changed to Riyal icon
                                        child: TextFormField(
                                          controller: _amountController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.grey.shade900,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter amount (﷼)', // Changed to Riyal symbol
                                            hintStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade500,
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            border: InputBorder.none,
                                            suffixText: '﷼', // Changed to Riyal symbol
                                            suffixStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade700,
                                              fontSize: screenWidth * 0.038,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Amount is required';
                                            }
                                            final amount = double.tryParse(
                                              value,
                                            );
                                            if (amount == null) {
                                              return 'Invalid amount';
                                            }
                                            if (amount <= 0) {
                                              return 'Amount must be > 0';
                                            }
                                            if (amount > 1000000) {
                                              return 'Max amount is 1,000,000 ﷼'; // Changed to Riyal symbol
                                            }
                                            return null;
                                          },
                                        ),
                                        screenWidth: screenWidth,
                                        isDarkMode: isDarkMode,
                                      ),

                                      SizedBox(height: screenHeight * 0.025),

                                      
                                      _buildFormField(
                                        label: 'Purpose of Advance',
                                        icon: Icons.description_rounded,
                                        child: TextFormField(
                                          controller: _purposeController,
                                          maxLines: 3,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.grey.shade900,
                                            height: 1.3,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Describe why you need this advance...',
                                            hintStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade500,
                                              fontSize: screenWidth * 0.035,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          maxLength: 200,
                                          maxLengthEnforcement:
                                              MaxLengthEnforcement.enforced,
                                          buildCounter:
                                              (
                                                context, {
                                                required currentLength,
                                                required isFocused,
                                                maxLength,
                                              }) {
                                                return Container(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    '$currentLength/$maxLength',
                                                    style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.03,
                                                      color: currentLength > 150
                                                          ? Colors.orange
                                                          : isDarkMode
                                                          ? Colors.grey.shade500
                                                          : Colors
                                                                .grey
                                                                .shade600,
                                                    ),
                                                  ),
                                                );
                                              },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Purpose is required';
                                            }
                                            if (value.length < 10) {
                                              return 'Minimum 10 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        screenWidth: screenWidth,
                                        isDarkMode: isDarkMode,
                                      ),

                                      SizedBox(height: screenHeight * 0.025),

                                      
                                      _buildDropdownField(
                                        label: 'Advance Account',
                                        icon: Icons.account_balance_rounded,
                                        value: _selectedAccount,
                                        items: _accounts,
                                        hint: 'Select advance account',
                                        onChanged: (value) {
                                          setState(
                                            () => _selectedAccount = value,
                                          );
                                        },
                                        screenWidth: screenWidth,
                                        isDarkMode: isDarkMode,
                                      ),

                                      SizedBox(height: screenHeight * 0.025),

                                      
                                      _buildDropdownField(
                                        label: 'Payment Mode',
                                        icon: Icons.payment_rounded,
                                        value: _selectedPaymentMode,
                                        items: _paymentModes,
                                        hint: 'Select payment mode',
                                        onChanged: (value) {
                                          setState(
                                            () => _selectedPaymentMode = value,
                                          );
                                        },
                                        screenWidth: screenWidth,
                                        isDarkMode: isDarkMode,
                                      ),

                                      SizedBox(height: screenHeight * 0.025),

                                      
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        padding: EdgeInsets.all(
                                          screenWidth * 0.04,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? slate.withOpacity(0.3)
                                              : _repayFromSalary
                                              ? Colors.green.shade50
                                              : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.04,
                                          ),
                                          border: Border.all(
                                            color: _repayFromSalary
                                                ? Colors.green.shade200
                                                : Colors.orange.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        _repayFromSalary
                                                            ? Icons
                                                                  .account_balance_wallet_rounded
                                                            : Icons
                                                                  .credit_card_rounded,
                                                        color: _repayFromSalary
                                                            ? Colors.green
                                                            : Colors.orange,
                                                        size:
                                                            screenWidth * 0.045,
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            screenWidth * 0.03,
                                                      ),
                                                      Text(
                                                        'Repay from Salary',
                                                        style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                              0.04,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : _repayFromSalary
                                                              ? Colors
                                                                    .green
                                                                    .shade800
                                                              : Colors
                                                                    .orange
                                                                    .shade800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        screenHeight * 0.008,
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      left: screenWidth * 0.075,
                                                    ),
                                                    child: Text(
                                                      _repayFromSalary
                                                          ? '✅ Amount will be deducted from your next salary'
                                                          : '⚠️ You will need to repay separately',
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.032,
                                                        color: isDarkMode
                                                            ? Colors
                                                                  .grey
                                                                  .shade400
                                                            : _repayFromSalary
                                                            ? Colors
                                                                  .green
                                                                  .shade700
                                                            : Colors
                                                                  .orange
                                                                  .shade700,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch.adaptive(
                                              value: _repayFromSalary,
                                              activeColor: Colors.green,
                                              activeTrackColor:
                                                  Colors.green.shade200,
                                              inactiveTrackColor:
                                                  Colors.orange.shade200,
                                              onChanged: (value) {
                                                setState(
                                                  () =>
                                                      _repayFromSalary = value,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: screenHeight * 0.04),

                                      
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _submitAdvance,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isSubmitting
                                                ? Colors.grey.shade400
                                                : skyBlue,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              vertical: screenHeight * 0.02,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    screenWidth * 0.04,
                                                  ),
                                            ),
                                            elevation: _isSubmitting ? 0 : 5,
                                            shadowColor: skyBlue.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          child: _isSubmitting
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      height:
                                                          screenHeight * 0.025,
                                                      width:
                                                          screenHeight * 0.025,
                                                      child:
                                                          const CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      width: screenWidth * 0.03,
                                                    ),
                                                    Text(
                                                      'SUBMITTING...',
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.045,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.send_rounded,
                                                      size: screenWidth * 0.055,
                                                    ),
                                                    SizedBox(
                                                      width: screenWidth * 0.03,
                                                    ),
                                                    Text(
                                                      'SUBMIT REQUEST',
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.045,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.5,
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

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required Widget child,
    required double screenWidth,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: screenWidth * 0.015),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? slate.withOpacity(0.3) : offWhite,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: Border.all(color: skyBlue.withOpacity(0.2), width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.02,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.01),
                  decoration: BoxDecoration(
                    color: skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(icon, color: skyBlue, size: screenWidth * 0.05),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    required double screenWidth,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: screenWidth * 0.015),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? slate.withOpacity(0.3) : offWhite,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: Border.all(color: skyBlue.withOpacity(0.2), width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.015,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.01),
                  decoration: BoxDecoration(
                    color: skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(icon, color: skyBlue, size: screenWidth * 0.05),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: skyBlue,
                        size: screenWidth * 0.06,
                      ),
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.grey.shade900,
                      ),
                      dropdownColor: isDarkMode ? slate : Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      hint: Text(
                        hint,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: isDarkMode
                              ? Colors.grey.shade500
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      items: items
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}