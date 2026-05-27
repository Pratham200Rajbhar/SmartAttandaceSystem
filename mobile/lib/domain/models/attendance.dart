
class AttendanceAnalysisResult {
  final double faceScore;
  final double livenessScore;
  final double backgroundScore;
  final double finalAiScore;
  final String predictedStatus;
  final String reviewToken;

  const AttendanceAnalysisResult({
    required this.faceScore,
    required this.livenessScore,
    required this.backgroundScore,
    required this.finalAiScore,
    required this.predictedStatus,
    required this.reviewToken,
  });

  bool get wouldBePresent => predictedStatus == 'Present';
  bool get wouldBeFlagged => predictedStatus == 'Flagged';

  factory AttendanceAnalysisResult.fromJson(Map<String, dynamic> json) =>
      AttendanceAnalysisResult(
        faceScore: (json['face_score'] as num).toDouble(),
        livenessScore: (json['liveness_score'] as num).toDouble(),
        backgroundScore: (json['background_score'] as num).toDouble(),
        finalAiScore: (json['final_ai_score'] as num).toDouble(),
        predictedStatus: json['predicted_status'] as String,
        reviewToken: json['review_token'] as String,
      );
}

class AttendanceResult {
  final String id;
  final String studentId;
  final String sessionId;
  final String status;
  final double faceScore;
  final double livenessScore;
  final double backgroundScore;
  final double finalAiScore;
  final double gpsLatitude;
  final double gpsLongitude;
  final DateTime createdAt;

  const AttendanceResult({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.status,
    required this.faceScore,
    required this.livenessScore,
    required this.backgroundScore,
    required this.finalAiScore,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.createdAt,
  });

  bool get isPresent => status == 'Present';
  bool get isFlagged => status == 'Flagged';

  factory AttendanceResult.fromJson(Map<String, dynamic> json) =>
      AttendanceResult(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        sessionId: json['session_id'] as String,
        status: json['status'] as String,
        faceScore: (json['face_score'] as num).toDouble(),
        livenessScore: (json['liveness_score'] as num).toDouble(),
        backgroundScore: (json['background_score'] as num).toDouble(),
        finalAiScore: (json['final_ai_score'] as num).toDouble(),
        gpsLatitude: (json['gps_latitude'] as num).toDouble(),
        gpsLongitude: (json['gps_longitude'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class AttendanceHistoryItem {
  final String attendanceId;
  final String classId;
  final String className;
  final String subject;
  final String sessionId;
  final String status;
  final DateTime markedAt;
  final double? faceScore;
  final double? livenessScore;
  final double? backgroundScore;
  final double? finalAiScore;
  final String? teacherNote;

  const AttendanceHistoryItem({
    required this.attendanceId,
    required this.classId,
    required this.className,
    required this.subject,
    required this.sessionId,
    required this.status,
    required this.markedAt,
    this.faceScore,
    this.livenessScore,
    this.backgroundScore,
    this.finalAiScore,
    this.teacherNote,
  });

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) =>
      AttendanceHistoryItem(
        attendanceId: json['attendance_id'] as String,
        classId: json['class_id'] as String,
        className: json['class_name'] as String,
        subject: json['subject'] as String,
        sessionId: json['session_id'] as String,
        status: json['status'] as String,
        markedAt: DateTime.parse(json['marked_at'] as String),
        faceScore: (json['face_score'] as num?)?.toDouble(),
        livenessScore: (json['liveness_score'] as num?)?.toDouble(),
        backgroundScore: (json['background_score'] as num?)?.toDouble(),
        finalAiScore: (json['final_ai_score'] as num?)?.toDouble(),
        teacherNote: json['teacher_note'] as String?,
      );
}

class AttendanceHistoryResponse {
  final String studentId;
  final double overallAttendancePercentage;
  final List<AttendanceHistoryItem> history;

  const AttendanceHistoryResponse({
    required this.studentId,
    required this.overallAttendancePercentage,
    required this.history,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) =>
      AttendanceHistoryResponse(
        studentId: json['student_id'] as String,
        overallAttendancePercentage:
            (json['overall_attendance_percentage'] as num).toDouble(),
        history: (json['history'] as List<dynamic>)
            .map((item) =>
                AttendanceHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class StudentClass {
  final String classId;
  final String className;
  final String subject;
  final String teacherName;
  final String? activeSessionId;
  final DateTime? sessionEndTime;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;

  const StudentClass({
    required this.classId,
    required this.className,
    required this.subject,
    required this.teacherName,
    this.activeSessionId,
    this.sessionEndTime,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  factory StudentClass.fromJson(Map<String, dynamic> json) => StudentClass(
        classId: json['class_id'] as String,
        className: json['class_name'] as String,
        subject: json['subject'] as String,
        teacherName: json['teacher_name'] as String,
        activeSessionId: json['active_session_id'] as String?,
        sessionEndTime: json['session_end_time'] != null
            ? DateTime.tryParse(json['session_end_time'] as String)
            : null,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        radiusMeters: (json['radius_meters'] as num?)?.toDouble(),
      );
}
