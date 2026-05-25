
class LeaveRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String enrollmentNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? documentUrl;
  final String status; 
  final String? approvedBy;
  final String? approverNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.enrollmentNumber,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.documentUrl,
    required this.status,
    this.approvedBy,
    this.approverNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      enrollmentNumber: json['enrollment_number'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String,
      documentUrl: json['document_url'] as String?,
      status: json['status'] as String,
      approvedBy: json['approved_by'] as String?,
      approverNote: json['approver_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'enrollment_number': enrollmentNumber,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'reason': reason,
      'document_url': documentUrl,
      'status': status,
      'approved_by': approvedBy,
      'approver_note': approverNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class LeaveRequestListResponse {
  final List<LeaveRequest> leaves;
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const LeaveRequestListResponse({
    required this.leaves,
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory LeaveRequestListResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestListResponse(
      leaves: (json['leaves'] as List)
          .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      pending: json['pending'] as int,
      approved: json['approved'] as int,
      rejected: json['rejected'] as int,
    );
  }
}
