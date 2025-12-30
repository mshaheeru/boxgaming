import 'package:intl/intl.dart';

class DateFormatters {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String formatTime(String time) {
    // Time is in HH:mm format, format to 12-hour format
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String formatDisplayDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDisplayDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  static String formatDayWithDate(DateTime date) {
    // Format: "Monday, 1 Jan" or "Sunday, 31 Dec"
    final dayName = DateFormat('EEEE', 'en_US').format(date);
    final day = date.day;
    final month = DateFormat('MMM', 'en_US').format(date);
    return '$dayName, $day $month';
  }

  static String formatDayWithDateFull(DateTime date) {
    // Format: "Monday, 1st Jan 2024"
    final dayName = DateFormat('EEEE', 'en_US').format(date);
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final month = DateFormat('MMM', 'en_US').format(date);
    final year = date.year;
    return '$dayName, $day$suffix $month $year';
  }

  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  static DateTime addHoursToTime(String timeStr, int hours) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final date = DateTime(2000, 1, 1, hour, minute);
    return date.add(Duration(hours: hours));
  }

  static String formatTimeRange(String startTime, int durationHours) {
    final start = formatTime(startTime);
    final endDate = addHoursToTime(startTime, durationHours);
    // Handle overnight hours (e.g., 23:00 + 2hr = 01:00 next day)
    final endHour = endDate.hour;
    final endMin = endDate.minute;
    final end = formatTime('${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}');
    return '$start - $end ($durationHours${durationHours == 2 ? 'hr' : 'hr'})';
  }
}



