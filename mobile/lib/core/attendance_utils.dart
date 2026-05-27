
import 'package:flutter/material.dart';
import 'package:smart_attendance_app/app/theme.dart';
import 'package:smart_attendance_app/core/attendance_constants.dart';
import 'package:smart_attendance_app/domain/models/attendance.dart';

bool isPresentOrApproved(String status) =>
    status == kStatusPresent || status == kStatusApproved;

bool isAbsent(String status) => status == kStatusAbsent;

bool isFlagged(String status) => status == kStatusFlagged;

bool isGood(double score) => score >= kGoodScoreThreshold;

Color pctColor(double pct) {
  if (pct >= kOverallGoodPct) return SasColors.success;
  if (pct >= kOverallWarningPct) return SasColors.warning;
  return SasColors.danger;
}

Color scoreColor(double score) {
  if (score >= kGoodScoreThreshold) return SasColors.success;
  if (score >= kWarningScoreThreshold) return SasColors.warning;
  return SasColors.danger;
}

Color statusColor(String status) {
  if (status == kStatusPresent || status == kStatusApproved) {
    return SasColors.success;
  }
  if (status == kStatusFlagged) return SasColors.warning;
  return SasColors.danger;
}

int calculateStreak(List<AttendanceHistoryItem> history) {
  if (history.isEmpty) return 0;
  final sorted = [...history]
    ..sort((a, b) => b.markedAt.compareTo(a.markedAt));
  int streak = 0;
  for (final item in sorted) {
    if (isPresentOrApproved(item.status)) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

int calculateHighestStreak(List<AttendanceHistoryItem> history) {
  if (history.isEmpty) return 0;
  final sorted = [...history]
    ..sort((a, b) => a.markedAt.compareTo(b.markedAt));
  int maxStreak = 0;
  int currentStreak = 0;
  for (final item in sorted) {
    if (isPresentOrApproved(item.status)) {
      currentStreak++;
      if (currentStreak > maxStreak) maxStreak = currentStreak;
    } else {
      currentStreak = 0;
    }
  }
  return maxStreak;
}

int countPresentOrApproved(Iterable<AttendanceHistoryItem> items) =>
    items.where((h) => isPresentOrApproved(h.status)).length;

int countAbsent(Iterable<AttendanceHistoryItem> items) =>
    items.where((h) => isAbsent(h.status)).length;

int countFlagged(Iterable<AttendanceHistoryItem> items) =>
    items.where((h) => isFlagged(h.status)).length;

({int canMiss, int needToAttend}) computeAttendanceNeeds({
  required int present,
  required int total,
  required double target,
}) {
  int canMiss = 0;
  int needToAttend = 0;
  final pct = total > 0 ? (present / total * 100) : 0.0;

  if (pct >= target) {
    canMiss = ((present / (target / 100)) - total).floor().clamp(0, 999);
  } else {
    final ratio = target / 100;
    if (ratio < 1.0) {
      needToAttend =
          ((ratio * total - present) / (1 - ratio)).ceil().clamp(0, 999);
    }
  }
  return (canMiss: canMiss, needToAttend: needToAttend);
}

double computeSubjectPct(int present, int total) =>
    total > 0 ? (present / total * 100) : 0.0;

int computeWeekPresent(Iterable<AttendanceHistoryItem> history) {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekItems =
      history.where((h) => h.markedAt.isAfter(weekStart.subtract(
        const Duration(days: 1),
      )));
  return countPresentOrApproved(weekItems);
}
