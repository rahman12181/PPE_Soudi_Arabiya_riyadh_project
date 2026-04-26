class EmployeeAdvanceModel {
  final String id;
  final String employee;
  final double amount;
  final String purpose;
  final String status;
  final DateTime appliedDate;
  final DateTime? approvedDate;
  final String? approvedBy;
  final String modeOfPayment;
  final String advanceAccount;
  final bool repayFromSalary;
  final String? company;
  final String? currency;

  EmployeeAdvanceModel({
    required this.id,
    required this.employee,
    required this.amount,
    required this.purpose,
    required this.status,
    required this.appliedDate,
    this.approvedDate,
    this.approvedBy,
    required this.modeOfPayment,
    required this.advanceAccount,
    required this.repayFromSalary,
    this.company,
    this.currency,
  });

  factory EmployeeAdvanceModel.fromJson(Map<String, dynamic> json) {
    final amountStr = json['advance_amount']?.toString() ?? '0';
    final amount = double.tryParse(amountStr.replaceAll(',', '')) ?? 0.0;
    
    DateTime parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr.split(' ').first);
      } catch (_) {
        return DateTime.now();
      }
    }
    
    final repayValue = json['repay_unclaimed_amount_from_salary'] ?? json['repay_from_salary'] ?? 0;
    final repayFromSalary = repayValue == 1 || repayValue == true || (repayValue is String && repayValue.toLowerCase() == 'yes');
    
    String currencyValue = json['currency']?.toString() ?? 'SAR';
    if (currencyValue.isEmpty) currencyValue = 'SAR';
    
    return EmployeeAdvanceModel(
      id: json['name']?.toString() ?? '',
      employee: json['employee']?.toString() ?? '',
      amount: amount,
      purpose: json['purpose']?.toString() ?? 'No purpose specified',
      status: _parseStatus(json['status']?.toString() ?? 'Draft'),
      appliedDate: parseDate(json['posting_date']?.toString()),
      approvedDate: json['approved_date'] != null ? parseDate(json['approved_date'].toString()) : null,
      approvedBy: json['approved_by']?.toString(),
      modeOfPayment: json['mode_of_payment']?.toString() ?? 'Cash',
      advanceAccount: json['advance_account']?.toString() ?? '',
      repayFromSalary: repayFromSalary,
      company: json['company']?.toString(),
      currency: currencyValue,
    );
  }

  static String _parseStatus(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('approved') || lowerStatus == '1') return 'Approved';
    if (lowerStatus.contains('rejected') || lowerStatus.contains('cancel')) return 'Rejected';
    if (lowerStatus.contains('pending') || lowerStatus == '0') return 'Pending';
    if (lowerStatus.contains('draft')) return 'Draft';
    return status;
  }

  Map<String, dynamic> toDisplayMap() {
    return {
      'name': id,
      'employee': employee,
      'advance_amount': amount,
      'purpose': purpose,
      'status': status,
      'posting_date': appliedDate.toIso8601String(),
      'approved_date': approvedDate?.toIso8601String(),
      'approved_by': approvedBy,
      'mode_of_payment': modeOfPayment,
      'advance_account': advanceAccount,
      'repay_from_salary': repayFromSalary ? 1 : 0,
      'company': company,
      'currency': currency ?? 'SAR',
    };
  }
}