import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dream_track/shared/constants/app_constants.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class ExperienceState {
  final int totalXP;
  final int currentLevel;
  final String levelName;
  final double progressToNextLevel;
  final int xpForCurrentLevel;
  final int xpForNextLevel;

  const ExperienceState({
    required this.totalXP,
    required this.currentLevel,
    required this.levelName,
    required this.progressToNextLevel,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
  });

  factory ExperienceState.fromXP(int xp) {
    final thresholds = AppConstants.levelThresholds;
    final names = AppConstants.levelNames;

    int level = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (xp >= thresholds[i]) {
        level = i;
      } else {
        break;
      }
    }

    final isMaxLevel = level >= thresholds.length - 1;
    final xpCurrent = thresholds[level];
    final xpNext = isMaxLevel ? thresholds.last : thresholds[level + 1];
    final progress = isMaxLevel
        ? 1.0
        : ((xp - xpCurrent) / (xpNext - xpCurrent)).clamp(0.0, 1.0);

    return ExperienceState(
      totalXP: xp,
      currentLevel: level,
      levelName: names[level.clamp(0, names.length - 1)],
      progressToNextLevel: progress,
      xpForCurrentLevel: xpCurrent,
      xpForNextLevel: xpNext,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ExperienceNotifier extends StateNotifier<ExperienceState> {
  late Box _box;
  static const _xpKey = 'total_xp';

  ExperienceNotifier() : super(ExperienceState.fromXP(0)) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(AppConstants.gamificationBoxName);
    final stored = _box.get(_xpKey, defaultValue: 0) as int;
    state = ExperienceState.fromXP(stored);
  }

  Future<void> _addXP(int amount) async {
    final newXP = state.totalXP + amount;
    state = ExperienceState.fromXP(newXP);
    await _box.put(_xpKey, newXP);
  }

  // ── XP Award Methods ─────────────────────────────────────────────────────────

  /// Awarded when any sleep record is saved.
  Future<void> onSleepRecorded() => _addXP(10);

  /// Awarded when the user's sleep goal is met for the night.
  Future<void> onGoalMet() => _addXP(20);

  /// Awarded when quality ≥ 4.
  Future<void> onHighQuality() => _addXP(15);

  /// Awarded when a sleep hygiene habit is completed.
  Future<void> onHabitCompleted() => _addXP(10);

  /// Awarded when any achievement is unlocked.
  Future<void> onAchievementUnlocked() => _addXP(50);

  /// Awarded when a sleep sound session is started.
  Future<void> onSoundUsed() => _addXP(5);

  /// Awarded when a meditation session is completed.
  Future<void> onMeditationCompleted() => _addXP(15);

  /// Awarded for each AI chat interaction.
  Future<void> onAIChat() => _addXP(5);

  /// Awarded when user reaches a 7-day streak milestone.
  Future<void> onStreak7() => _addXP(100);

  /// Awarded when user reaches a 30-day streak milestone.
  Future<void> onStreak30() => _addXP(500);

  /// Arbitrary XP award (e.g., bonus events).
  Future<void> awardXP(int amount) => _addXP(amount);
}

// ─── Provider ────────────────────────────────────────────────────────────────

final experienceProvider =
    StateNotifierProvider<ExperienceNotifier, ExperienceState>(
  (ref) => ExperienceNotifier(),
);
