
library;

import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  
  String get formattedDate => DateFormat.yMMMMd().format(this);

  String get formattedTime => DateFormat.jm().format(this);

  String get formattedDateTime => '$formattedDate at $formattedTime';

  String get shortDate => DateFormat('E, MMM d').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension StringFormatting on String {
  
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}
