import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class WeeklyScore {
  final int total;
  final int hoursScore;
  final int regularityScore;
  final int qualityScore;
  final int habitScore;
  final DateTime weekStartDate;

  const WeeklyScore({
    required this.total,
    required this.hoursScore,
    required this.regularityScore,
    required this.qualityScore,
    required this.habitScore,
    required this.weekStartDate,
  });

  Map<String, dynamic> toMap() => {
        'total': total,
        'hoursScore': hoursScore,
        'regularityScore': regularityScore,
        'qualityScore': qualityScore,
        'habitScore': habitScore,
        'weekStartDate': weekStartDate.toIso8601String(),
      };

  factory WeeklyScore.fromMap(Map<dynamic, dynamic> map) => WeeklyScore(
        total: (map['total'] as int?) ?? 0,
        hoursScore: (map['hoursScore'] as int?) ?? 0,
        regularityScore: (map['regularityScore'] as int?) ?? 0,
        qualityScore: (map['qualityScore'] as int?) ?? 0,
        habitScore: (map['habitScore'] as int?) ?? 0,
        weekStartDate: map['weekStartDate'] != null
            ? DateTime.tryParse(map['weekStartDate'] as String) ??
                DateTime.now()
            : DateTime.now(),
      );

  /// Human-readable label.
  String get label {
    if (total >= AppConstants.scoreExcellent) return 'Excelente';
    if (total >= AppConstants.scoreVeryGood) return 'Muy bien';
    if (total >= AppConstants.scoreGood) return 'Buen trabajo';
    if (total >= AppConstants.scoreFair) return 'Puedes hacerlo mejor';
    return 'Necesitas mejorar';
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class WeeklyScoreState {
  final WeeklyScore? current;
  final List<WeeklyScore> history; // newest first

  const WeeklyScoreState({this.current, this.history = const []});

  WeeklyScore? get previous =>
      history.length >= 2 ? history[1] : null;

  /// Difference between current and previous (positive = better).
  int? get weekOverWeekDelta {
    if (current == null || previous == null) return null;
    return current!.total - previous!.total;
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class WeeklyScoreNotifier extends StateNotifier<WeeklyScoreState> {
  late Box _box;
  static const _historyKey = 'weekly_score_history';

  WeeklyScoreNotifier() : super(const WeeklyScoreState()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(AppConstants.gamificationBoxName);
    _loadHistory();
  }

  void _loadHistory() {
    final raw = _box.get(_historyKey);
    if (raw == null) return;
    final list = (raw as List).cast<Map>();
    final scores = list.map((m) => WeeklyScore.fromMap(m)).toList();
    state = WeeklyScoreState(
      current: scores.isNotEmpty ? scores.first : null,
      history: scores,
    );
  }

  Future<void> _saveHistory(List<WeeklyScore> scores) async {
    await _box.put(
        _historyKey, scores.map((s) => s.toMap()).toList());
  }

  // ── Calculation ───────────────────────────────────────────────────────────

  /// Calculate weekly score from [records] (last 7 days) and [habitCompletion]
  /// (0.0–1.0 ratio of habits done this week).
  Future<WeeklyScore> calculateWeeklyScore(
    List<SleepRecord> records,
    double habitCompletion,
  ) async {
    final weekStart = DateTime.now().subtract(const Duration(days: 6));
    final weekStartDay =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    // Filter to last 7 days
    final weekRecords = records.where((r) {
      final d = DateTime(r.wakeTime.year, r.wakeTime.month, r.wakeTime.day);
      return !d.isBefore(weekStartDay);
    }).toList();

    // ── Factor 1: Hours vs Goal (35 pts) ─────────────────────────────────────
    final daysMet = weekRecords.where((r) => r.hoursSlept >= 7.0).length;
    final daysMissed = 7 - daysMet.clamp(0, 7);
    final hoursScore = (35 - (daysMissed * 5)).clamp(0, 35);

    // ── Factor 2: Schedule Regularity (25 pts) ────────────────────────────────
    int regularityScore = 25;
    if (weekRecords.length >= 2) {
      int irregularDays = 0;
      final sorted = [...weekRecords]
        ..sort((a, b) => a.bedTime.compareTo(b.bedTime));
      for (int i = 1; i < sorted.length; i++) {
        final prevBedMins = sorted[i - 1].bedTime.hour * 60 +
            sorted[i - 1].bedTime.minute;
        final curBedMins =
            sorted[i].bedTime.hour * 60 + sorted[i].bedTime.minute;
        if ((curBedMins - prevBedMins).abs() > 30) {
          irregularDays++;
        }
      }
      regularityScore = (25 - (irregularDays * 3)).clamp(0, 25);
    }

    // ── Factor 3: Average Quality (25 pts) ────────────────────────────────────
    int qualityScore = 0;
    if (weekRecords.isNotEmpty) {
      final avgQuality =
          weekRecords.map((r) => r.quality).reduce((a, b) => a + b) /
              weekRecords.length;
      if (avgQuality >= 4.5) {
        qualityScore = 25;
      } else if (avgQuality >= 3.5) {
        qualityScore = 20;
      } else if (avgQuality >= 2.5) {
        qualityScore = 15;
      } else if (avgQuality >= 1.5) {
        qualityScore = 10;
      } else {
        qualityScore = 5;
      }
    }

    // ── Factor 4: Habit Completion (15 pts) ───────────────────────────────────
    final habitScore = (habitCompletion * 15).round().clamp(0, 15);

    final total =
        (hoursScore + regularityScore + qualityScore + habitScore).clamp(0, 100);

    final score = WeeklyScore(
      total: total,
      hoursScore: hoursScore,
      regularityScore: regularityScore,
      qualityScore: qualityScore,
      habitScore: habitScore,
      weekStartDate: weekStartDay,
    );

    // Prepend to history and trim to 16 weeks
    final history = [score, ...state.history]
      ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
    final trimmed = history.take(16).toList();

    state = WeeklyScoreState(current: score, history: trimmed);
    await _saveHistory(trimmed);
    return score;
  }

  /// Get last N weekly scores (newest first).
  List<WeeklyScore> getLastNWeeks(int n) =>
      state.history.take(n).toList();
}

// ─── Provider ────────────────────────────────────────────────────────────────

final weeklyScoreProvider =
    StateNotifierProvider<WeeklyScoreNotifier, WeeklyScoreState>(
  (ref) => WeeklyScoreNotifier(),
);
