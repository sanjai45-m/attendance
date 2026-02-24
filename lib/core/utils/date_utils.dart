import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Returns date string in "yyyy-MM-dd" format
  static String toDateString(DateTime date) => _dateFormat.format(date);

  /// Returns display-friendly date: "23 Feb 2026"
  static String toDisplayDate(DateTime date) => _displayDateFormat.format(date);

  /// Returns time string: "09:30 AM"
  static String toTimeString(DateTime date) => _timeFormat.format(date);

  /// Returns full date-time string: "23 Feb 2026, 09:30 AM"
  static String toDateTimeString(DateTime date) => _dateTimeFormat.format(date);

  /// Today's date as "yyyy-MM-dd"
  static String todayString() => toDateString(DateTime.now());

  /// Calculate hours between two DateTimes
  static double calculateHours(DateTime start, DateTime end) {
    return end.difference(start).inMinutes / 60.0;
  }

  /// Check if a time is late based on threshold
  static bool isLate(DateTime punchIn, String workStartTime, int thresholdMinutes) {
    final parts = workStartTime.split(':');
    final startHour = int.parse(parts[0]);
    final startMinute = int.parse(parts[1]);

    final threshold = DateTime(
      punchIn.year,
      punchIn.month,
      punchIn.day,
      startHour,
      startMinute + thresholdMinutes,
    );

    return punchIn.isAfter(threshold);
  }

  /// Parse date string "yyyy-MM-dd" to DateTime
  static DateTime parseDate(String dateStr) => _dateFormat.parse(dateStr);
}
