class LeaveApprovedModel {
  final String employeeName;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String status;
  final String reason;

  LeaveApprovedModel({
    required this.employeeName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.reason,
  });

  factory LeaveApprovedModel.fromJson(Map<String, dynamic> json) {
    return LeaveApprovedModel(
      employeeName: json['employee_name'] ?? '',
      leaveType: json['leave_type'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}
