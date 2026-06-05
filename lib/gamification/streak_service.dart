import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastRecordDate;
  final int shieldsAvailable;
  final int shieldsUsed;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastRecordDate,
    this.shieldsAvailable = 1,
    this.shieldsUsed = 0,
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastRecordDate,
    int? shieldsAvailable,
    int? shieldsUsed,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastRecordDate: lastRecordDate ?? this.lastRecordDate,
      shieldsAvailable: shieldsAvailable ?? this.shieldsAvailable,
      shieldsUsed: shieldsUsed ?? this.shieldsUsed,
    );
  }

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastRecordDate': lastRecordDate?.toIso8601String(),
        'shieldsAvailable': shieldsAvailable,
        'shieldsUsed': shieldsUsed,
      };

  factory StreakData.fromMap(Map<dynamic, dynamic> map) => StreakData(
        currentStreak: (map['currentStreak'] as int?) ?? 0,
        longestStreak: (map['longestStreak'] as int?) ?? 0,
        lastRecordDate: map['lastRecordDate'] != null
            ? DateTime.tryParse(map['lastRecordDate'] as String)
            : null,
        shieldsAvailable: (map['shieldsAvailable'] as int?) ?? 1,
        shieldsUsed: (map['shieldsUsed'] as int?) ?? 0,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<StreakData> {
  late Box _box;
  static const _key = 'streak_data';

  StreakNotifier() : super(const StreakData()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(AppConstants.gamificationBoxName);
    final raw = _box.get(_key);
    if (raw != null && raw is Map) {
      state = StreakData.fromMap(raw);
    }
  }

  Future<void> _save() async {
    await _box.put(_key, state.toMap());
  }

  // ── Public Methods ───────────────────────────────────────────────────────────

  /// Updates streak based on a new [SleepRecord] and the user's [goalHours].
  Future<void> updateStreak(SleepRecord record, double goalHours) async {
    final now = DateTime(
        record.wakeTime.year, record.wakeTime.month, record.wakeTime.day);
    final last = state.lastRecordDate;

    if (last == null) {
      // First record ever
      final metGoal = record.hoursSlept >= goalHours;
      final newStreak = metGoal ? 1 : 0;
      state = state.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > state.longestStreak ? newStreak : state.longestStreak,
        lastRecordDate: now,
      );
      await _save();
      return;
    }

    final dayDiff = now.difference(last).inDays;

    if (dayDiff == 0) {
      // Already recorded today – update if better (e.g., auto-detect correction)
      if (record.hoursSlept >= goalHours && state.currentStreak == 0) {
        final newStreak = 1;
        state = state.copyWith(
          currentStreak: newStreak,
          longestStreak:
              newStreak > state.longestStreak ? newStreak : state.longestStreak,
          lastRecordDate: now,
        );
        await _save();
      }
      return;
    }

    if (dayDiff == 1) {
      // Consecutive day
      final metGoal = record.hoursSlept >= goalHours;
      if (metGoal) {
        final newStreak = state.currentStreak + 1;
        state = state.copyWith(
          currentStreak: newStreak,
          longestStreak:
              newStreak > state.longestStreak ? newStreak : state.longestStreak,
          lastRecordDate: now,
        );
      } else {
        // Missed goal – streak broken
        state = state.copyWith(
          currentStreak: 0,
          lastRecordDate: now,
        );
      }
      await _save();
      return;
    }

    // Gap of 2+ days
    if (dayDiff == 2 && state.shieldsAvailable > 0) {
      // Auto-use shield to bridge one missed day
      final metGoal = record.hoursSlept >= goalHours;
      if (metGoal) {
        final newStreak = state.currentStreak + 1;
        state = state.copyWith(
          currentStreak: newStreak,
          longestStreak:
              newStreak > state.longestStreak ? newStreak : state.longestStreak,
          lastRecordDate: now,
          shieldsAvailable: state.shieldsAvailable - 1,
          shieldsUsed: state.shieldsUsed + 1,
        );
        await _save();
        return;
      }
    }

    // Streak broken with no shield available / gap > 2
    final metGoal = record.hoursSlept >= goalHours;
    state = state.copyWith(
      currentStreak: metGoal ? 1 : 0,
      lastRecordDate: now,
    );
    await _save();
  }

  /// Manually use a shield to protect current streak.
  Future<bool> useShield() async {
    if (state.shieldsAvailable <= 0) return false;
    state = state.copyWith(
      shieldsAvailable: state.shieldsAvailable - 1,
      shieldsUsed: state.shieldsUsed + 1,
    );
    await _save();
    return true;
  }

  /// Award a shield (e.g., milestone reward).
  Future<void> awardShield() async {
    state = state.copyWith(shieldsAvailable: state.shieldsAvailable + 1);
    await _save();
  }

  // ── Computed Properties ──────────────────────────────────────────────────────

  /// Returns the next milestone the user hasn't yet reached.
  int getNextMilestone() {
    for (final m in AppConstants.streakMilestones) {
      if (state.currentStreak < m) return m;
    }
    return AppConstants.streakMilestones.last;
  }

  /// Visual level of the streak flame.
  String get streakLevel {
    final s = state.currentStreak;
    if (s >= 90) return 'max';
    if (s >= 30) return 'large';
    if (s >= 7) return 'medium';
    return 'small';
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakData>(
  (ref) => StreakNotifier(),
);
