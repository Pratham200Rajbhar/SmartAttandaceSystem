
class StudentStats {
  final int currentStreak;
  final int highestStreak;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int flaggedCount;
  final int excusedCount;
  final double attendancePercentage;

  const StudentStats({
    required this.currentStreak,
    required this.highestStreak,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.flaggedCount,
    required this.excusedCount,
    required this.attendancePercentage,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      currentStreak: json['current_streak'] as int,
      highestStreak: json['highest_streak'] as int,
      totalClasses: json['total_classes'] as int,
      presentCount: json['present_count'] as int,
      absentCount: json['absent_count'] as int,
      flaggedCount: json['flagged_count'] as int,
      excusedCount: json['excused_count'] as int,
      attendancePercentage: (json['attendance_percentage'] as num).toDouble(),
    );
  }
}
