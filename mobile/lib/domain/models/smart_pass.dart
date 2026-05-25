
class SmartPass {
  final String qrToken;
  final DateTime expiresAt;
  final String studentName;
  final String enrollmentNumber;

  const SmartPass({
    required this.qrToken,
    required this.expiresAt,
    required this.studentName,
    required this.enrollmentNumber,
  });

  factory SmartPass.fromJson(Map<String, dynamic> json) {
    return SmartPass(
      qrToken: json['qr_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      studentName: json['student_name'] as String,
      enrollmentNumber: json['enrollment_number'] as String,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}
