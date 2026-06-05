import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';
import 'package:dream_track/sleep/sleep_tracker_service.dart';
import 'package:dream_track/shared/utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService(ref.read(sleepTrackerServiceProvider));
});

class WeeklySleepStats {
  final double avgHours;
  final double avgQuality;
  final SleepRecord? bestNight;
  final SleepRecord? worstNight;
  final double sleepDebt;
  final List<double> dailyHours; // 7 entries Mon-Sun
  final List<double> dailyQuality;
  final double goalCompletionRate; // 0.0-1.0
  final double prevWeekAvgHours;

  const WeeklySleepStats({
    required this.avgHours,
    required this.avgQuality,
    this.bestNight,
    this.worstNight,
    required this.sleepDebt,
    required this.dailyHours,
    required this.dailyQuality,
    required this.goalCompletionRate,
    required this.prevWeekAvgHours,
  });

  double get improvementVsPrevWeek => avgHours - prevWeekAvgHours;
  bool get isImproving => improvementVsPrevWeek > 0;
}

class MonthlySleepStats {
  final double avgHours;
  final double avgQuality;
  final double totalSleepDebt;
  final SleepRecord? bestNight;
  final SleepRecord? worstNight;
  final int daysWithData;
  final Map<int, double> dailyHoursMap; // day -> hours
  final Map<int, int> dailyQualityMap; // day -> quality

  const MonthlySleepStats({
    required this.avgHours,
    required this.avgQuality,
    required this.totalSleepDebt,
    this.bestNight,
    this.worstNight,
    required this.daysWithData,
    required this.dailyHoursMap,
    required this.dailyQualityMap,
  });
}

class SleepCyclePoint {
  final DateTime time;
  final double movementLevel;
  final String phase; // 'light', 'deep', 'rem', 'awake'

  const SleepCyclePoint({
    required this.time,
    required this.movementLevel,
    required this.phase,
  });
}

class StatsService {
  final SleepTrackerService _tracker;

  StatsService(this._tracker);

  Future<double> _getSleepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('sleepGoalHours') ?? 8.0;
  }

  Future<WeeklySleepStats> getWeeklyStats(DateTime reference) async {
    final goalHours = await _getSleepGoal();
    final days = AppDateUtils.daysInWeek(reference);
    final prevDays = AppDateUtils.daysInWeek(
        reference.subtract(const Duration(days: 7)));

    final records = <SleepRecord?>[];
    final prevRecords = <SleepRecord?>[];

    for (final day in days) {
      records.add(_tracker.getRecordForDate(day));
    }
    for (final day in prevDays) {
      prevRecords.add(_tracker.getRecordForDate(day));
    }

    final validRecords = records.whereType<SleepRecord>().toList();
    final prevValid = prevRecords.whereType<SleepRecord>().toList();

    final dailyHours = records.map((r) => r?.hoursSlept ?? 0.0).toList();
    final dailyQuality = records.map((r) => r?.quality.toDouble() ?? 0.0).toList();

    final daysMetGoal = validRecords.where((r) => r.hoursSlept >= goalHours).length;
    final goalRate = validRecords.isEmpty ? 0.0 : daysMetGoal / 7.0;

    double sleepDebt = 0;
    for (final r in validRecords) {
      final diff = goalHours - r.hoursSlept;
      if (diff > 0) sleepDebt += diff;
    }

    SleepRecord? best, worst;
    if (validRecords.isNotEmpty) {
      best = validRecords.reduce((a, b) => a.hoursSlept > b.hoursSlept ? a : b);
      worst = validRecords.reduce((a, b) => a.hoursSlept < b.hoursSlept ? a : b);
    }

    return WeeklySleepStats(
      avgHours: validRecords.isEmpty
          ? 0
          : validRecords.map((r) => r.hoursSlept).reduce((a, b) => a + b) / validRecords.length,
      avgQuality: validRecords.isEmpty
          ? 0
          : validRecords.map((r) => r.quality.toDouble()).reduce((a, b) => a + b) / validRecords.length,
      bestNight: best,
      worstNight: worst,
      sleepDebt: sleepDebt,
      dailyHours: dailyHours,
      dailyQuality: dailyQuality,
      goalCompletionRate: goalRate,
      prevWeekAvgHours: prevValid.isEmpty
          ? 0
          : prevValid.map((r) => r.hoursSlept).reduce((a, b) => a + b) / prevValid.length,
    );
  }

  Future<MonthlySleepStats> getMonthlyStats(DateTime reference) async {
    final goalHours = await _getSleepGoal();
    final days = AppDateUtils.daysInMonth(reference);

    final dailyHoursMap = <int, double>{};
    final dailyQualityMap = <int, int>{};
    final records = <SleepRecord>[];

    for (final day in days) {
      final record = _tracker.getRecordForDate(day);
      if (record != null) {
        dailyHoursMap[day.day] = record.hoursSlept;
        dailyQualityMap[day.day] = record.quality;
        records.add(record);
      }
    }

    double totalDebt = 0;
    for (final r in records) {
      final diff = goalHours - r.hoursSlept;
      if (diff > 0) totalDebt += diff;
    }

    SleepRecord? best, worst;
    if (records.isNotEmpty) {
      best = records.reduce((a, b) => a.hoursSlept > b.hoursSlept ? a : b);
      worst = records.reduce((a, b) => a.hoursSlept < b.hoursSlept ? a : b);
    }

    return MonthlySleepStats(
      avgHours: records.isEmpty
          ? 0
          : records.map((r) => r.hoursSlept).reduce((a, b) => a + b) / records.length,
      avgQuality: records.isEmpty
          ? 0
          : records.map((r) => r.quality.toDouble()).reduce((a, b) => a + b) / records.length,
      totalSleepDebt: totalDebt,
      bestNight: best,
      worstNight: worst,
      daysWithData: records.length,
      dailyHoursMap: dailyHoursMap,
      dailyQualityMap: dailyQualityMap,
    );
  }

  List<SleepCyclePoint> estimateSleepCycles(SleepRecord record) {
    if (record.accelerometerData == null || record.accelerometerData!.isEmpty) {
      return _generateSimulatedCycles(record);
    }

    final data = record.accelerometerData!;
    final duration = record.hoursSlept;
    final points = <SleepCyclePoint>[];
    final startTime = record.bedTime;
    final stepMinutes = (duration * 60 / data.length).clamp(1.0, 10.0);

    for (int i = 0; i < data.length; i++) {
      final movement = data[i];
      String phase;
      if (movement < 0.1) {
        phase = 'deep';
      } else if (movement < 0.5) {
        phase = i % 90 < 20 ? 'rem' : 'light'; // REM approx every 90 min
      } else {
        phase = 'awake';
      }

      points.add(SleepCyclePoint(
        time: startTime.add(Duration(minutes: (i * stepMinutes).round())),
        movementLevel: movement,
        phase: phase,
      ));
    }
    return points;
  }

  List<SleepCyclePoint> _generateSimulatedCycles(SleepRecord record) {
    final points = <SleepCyclePoint>[];
    final duration = record.hoursSlept * 60; // in minutes
    final startTime = record.bedTime;
    const stepMinutes = 5;

    for (int min = 0; min < duration; min += stepMinutes) {
      double movement;
      String phase;

      // Simulate typical 90-min sleep cycles
      final cyclePosition = min % 90;
      if (cyclePosition < 10) {
        phase = 'light';
        movement = 0.3;
      } else if (cyclePosition < 40) {
        phase = 'deep';
        movement = 0.05;
      } else if (cyclePosition < 70) {
        phase = 'deep';
        movement = 0.08;
      } else if (cyclePosition < 80) {
        phase = 'rem';
        movement = 0.2;
      } else {
        phase = 'light';
        movement = 0.35;
      }

      // Add some variation
      movement += (min / duration) * 0.1; // More movement as night progresses

      points.add(SleepCyclePoint(
        time: startTime.add(Duration(minutes: min)),
        movementLevel: movement,
        phase: phase,
      ));
    }
    return points;
  }
}
