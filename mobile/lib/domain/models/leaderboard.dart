class LeaderboardEntry {
  final String studentId;
  final String name;
  final int points;
  final int currentStreak;

  const LeaderboardEntry({
    required this.studentId,
    required this.name,
    required this.points,
    required this.currentStreak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        studentId: json['student_id'] as String,
        name: json['name'] as String,
        points: json['points'] as int,
        currentStreak: json['current_streak'] as int? ?? 0,
      );
}

class LeaderboardResponse {
  final List<LeaderboardEntry> leaderboard;
  final int? userRank;
  final int userPoints;

  const LeaderboardResponse({
    required this.leaderboard,
    this.userRank,
    required this.userPoints,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) =>
      LeaderboardResponse(
        leaderboard: (json['leaderboard'] as List<dynamic>)
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        userRank: json['user_rank'] as int?,
        userPoints: json['user_points'] as int? ?? 0,
      );
}
