import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';
import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/shared/utils/date_utils.dart';

final sleepTrackerServiceProvider = Provider<SleepTrackerService>((ref) {
  return SleepTrackerService();
});

final allSleepRecordsProvider = Provider<List<SleepRecord>>((ref) {
  final service = ref.watch(sleepTrackerServiceProvider);
  return service.getAllRecords();
});

final lastSleepRecordProvider = Provider<SleepRecord?>((ref) {
  final service = ref.watch(sleepTrackerServiceProvider);
  return service.getLastRecord();
});

final weeklyRecordsProvider = Provider<List<SleepRecord>>((ref) {
  final service = ref.watch(sleepTrackerServiceProvider);
  return service.getRecordsForWeek(DateTime.now());
});

final monthlyRecordsProvider = Provider<List<SleepRecord>>((ref) {
  final service = ref.watch(sleepTrackerServiceProvider);
  return service.getRecordsForMonth(DateTime.now());
});

class SleepTrackerService {
  Box<SleepRecord> get _box => Hive.box<SleepRecord>(AppConstants.sleepBoxName);

  Future<void> saveRecord(SleepRecord record) async {
    await _box.add(record);
  }

  Future<void> updateRecord(int index, SleepRecord record) async {
    await _box.putAt(index, record);
  }

  Future<void> deleteRecord(int index) async {
    await _box.deleteAt(index);
  }

  List<SleepRecord> getAllRecords() {
    return _box.values.toList()
      ..sort((a, b) => b.bedTime.compareTo(a.bedTime));
  }

  SleepRecord? getLastRecord() {
    final records = getAllRecords();
    return records.isEmpty ? null : records.first;
  }

  SleepRecord? getRecordForDate(DateTime date) {
    try {
      return _box.values.firstWhere(
        (r) => AppDateUtils.isSameDay(r.bedTime, date) ||
               AppDateUtils.isSameDay(r.wakeTime, date),
      );
    } catch (_) {
      return null;
    }
  }

  List<SleepRecord> getRecordsForWeek(DateTime reference) {
    final days = AppDateUtils.daysInWeek(reference);
    return days
        .map((day) => getRecordForDate(day))
        .whereType<SleepRecord>()
        .toList();
  }

  List<SleepRecord> getRecordsForMonth(DateTime reference) {
    final days = AppDateUtils.daysInMonth(reference);
    return days
        .map((day) => getRecordForDate(day))
        .whereType<SleepRecord>()
        .toList();
  }

  List<SleepRecord> getLast30Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return getAllRecords().where((r) => r.bedTime.isAfter(cutoff)).toList();
  }

  double getAverageHoursSlept(List<SleepRecord> records) {
    if (records.isEmpty) return 0;
    return records.map((r) => r.hoursSlept).reduce((a, b) => a + b) / records.length;
  }

  double getAverageQuality(List<SleepRecord> records) {
    if (records.isEmpty) return 0;
    return records.map((r) => r.quality.toDouble()).reduce((a, b) => a + b) / records.length;
  }

  double getSleepDebt(double goalHours, int days) {
    final records = getLast30Days().take(days).toList();
    double debt = 0;
    for (var r in records) {
      final diff = goalHours - r.hoursSlept;
      if (diff > 0) debt += diff;
    }
    return debt;
  }

  SleepRecord createFromTimes({
    required DateTime bedTime,
    required DateTime wakeTime,
    required int quality,
    String? notes,
    bool hadNightmares = false,
    bool hadDreams = false,
    int wakeUps = 0,
    bool usedSounds = false,
    String? soundUsed,
    bool dndActive = false,
  }) {
    final hours = AppDateUtils.calculateHoursSlept(bedTime, wakeTime);
    return SleepRecord(
      bedTime: bedTime,
      wakeTime: wakeTime,
      hoursSlept: hours,
      quality: quality,
      notes: notes,
      hadNightmares: hadNightmares,
      hadDreams: hadDreams,
      wakeUps: wakeUps,
      usedSounds: usedSounds,
      soundUsed: soundUsed,
      dndActive: dndActive,
    );
  }
}
