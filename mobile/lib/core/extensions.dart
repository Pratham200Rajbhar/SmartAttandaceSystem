// Utility extensions for common data transformations.
library;

import 'package:intl/intl.dart';

/// DateTime formatting helpers used across UI screens.
extension DateTimeFormatting on DateTime {
  /// "May 24, 2026"
  String get formattedDate => DateFormat.yMMMMd().format(this);

  /// "2:06 PM"
  String get formattedTime => DateFormat.jm().format(this);

  /// "May 24, 2026 at 2:06 PM"
  String get formattedDateTime => '$formattedDate at $formattedTime';

  /// "Mon, May 24"
  String get shortDate => DateFormat('E, MMM d').format(this);

  /// Checks if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

/// String helpers for display formatting.
extension StringFormatting on String {
  /// Capitalizes the first letter of this string.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncates to [maxLength] with trailing ellipsis.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}
