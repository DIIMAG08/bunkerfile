import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  static String formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);
  static String formatShortDate(DateTime dt) => DateFormat('dd/MM').format(dt);
  static String formatDayName(DateTime dt) => DateFormat('EEE', 'es').format(dt);
  static String formatFullDayName(DateTime dt) => DateFormat('EEEE', 'es').format(dt);
  static String formatMonthYear(DateTime dt) => DateFormat('MMMM yyyy', 'es').format(dt);

  static double calculateHoursSlept(DateTime bedTime, DateTime wakeTime) {
    DateTime adjustedWake = wakeTime;
    if (wakeTime.isBefore(bedTime)) {
      adjustedWake = wakeTime.add(const Duration(days: 1));
    }
    final difference = adjustedWake.difference(bedTime);
    return difference.inMinutes / 60.0;
  }

  static String formatHoursSlept(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime startOfWeek(DateTime dt) {
    final weekday = dt.weekday;
    return startOfDay(dt.subtract(Duration(days: weekday - 1)));
  }

  static DateTime startOfMonth(DateTime dt) => DateTime(dt.year, dt.month, 1);

  static List<DateTime> daysInWeek(DateTime reference) {
    final start = startOfWeek(reference);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  static List<DateTime> daysInMonth(DateTime reference) {
    final start = startOfMonth(reference);
    final daysCount = DateTime(reference.year, reference.month + 1, 0).day;
    return List.generate(daysCount, (i) => start.add(Duration(days: i)));
  }

  static String greetingByHour() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '¡Buenos días';
    if (hour >= 12 && hour < 18) return '¡Buenas tardes';
    return '¡Buenas noches';
  }

  static String timeUntil(DateTime future) {
    final diff = future.difference(DateTime.now());
    if (diff.isNegative) return 'Pasado';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
    return '${diff.inMinutes}min';
  }

  static DateTime nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }
}
