import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dream_track/gamification/achievement_notification_widget.dart';
import 'package:dream_track/gamification/achievements_service.dart';
import 'package:dream_track/gamification/experience_service.dart';
import 'package:dream_track/gamification/streak_service.dart';
import 'package:dream_track/gamification/weekly_score_service.dart';
import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';

// ─── Gamification Overall State ───────────────────────────────────────────────

class GamificationOverallState {
  final int currentStreak;
  final int totalXP;
  final int currentLevel;
  final String levelName;
  final int? weeklyScore;
  final int unlockedAchievements;

  const GamificationOverallState({
    this.currentStreak = 0,
    this.totalXP = 0,
    this.currentLevel = 0,
    this.levelName = '',
    this.weeklyScore,
    this.unlockedAchievements = 0,
  });
}

// ─── Coordinator Notifier ─────────────────────────────────────────────────────

class GamificationNotifier extends StateNotifier<GamificationOverallState> {
  final Ref _ref;

  // Misc counters persisted in gamification box (keyed separately)
  static const _tipsReadKey = 'tips_read';
  static const _aiChatsKey = 'ai_chats';
  static const _breathingKey = 'breathing_sessions';
  static const _meditationKey = 'meditation_sessions';
  static const _napsKey = 'naps';
  static const _customMixesKey = 'custom_mixes';
  static const _uniqueSoundsKey = 'unique_sounds';
  static const _daysUsedKey = 'days_used';
  static const _sharedKey = 'score_shared';
  static const _shieldUsedKey = 'shield_used';
  static const _configDoneKey = 'config_done';

  late Box _box;

  GamificationNotifier(this._ref)
      : super(const GamificationOverallState()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(AppConstants.gamificationBoxName);
    await _updateDaysUsed();
    _syncState();
  }

  void _syncState() {
    final streak = _ref.read(streakProvider);
    final xp = _ref.read(experienceProvider);
    final achievements = _ref.read(achievementsProvider);
    final weekly = _ref.read(weeklyScoreProvider);

    state = GamificationOverallState(
      currentStreak: streak.currentStreak,
      totalXP: xp.totalXP,
      currentLevel: xp.currentLevel,
      levelName: xp.levelName,
      weeklyScore: weekly.current?.total,
      unlockedAchievements: achievements.unlockedCount,
    );
  }

  // ── Core Coordinator Method ──────────────────────────────────────────────────

  /// Called whenever a new [SleepRecord] is saved.
  /// Coordinates all sub-services and fires any resulting notifications.
  Future<void> onSleepRecorded(
    SleepRecord record, {
    BuildContext? context,
    double goalHours = 8.0,
    double habitCompletion = 0.0,
  }) async {
    // 1. Update streak
    final streakNotifier = _ref.read(streakProvider.notifier);
    final streakBefore = _ref.read(streakProvider).currentStreak;
    await streakNotifier.updateStreak(record, goalHours);
    final streakAfter = _ref.read(streakProvider).currentStreak;

    // 2. Award XP
    final xpNotifier = _ref.read(experienceProvider.notifier);
    await xpNotifier.onSleepRecorded();
    if (record.hoursSlept >= goalHours) await xpNotifier.onGoalMet();
    if (record.quality >= 4) await xpNotifier.onHighQuality();
    if (record.usedSounds) await xpNotifier.onSoundUsed();

    // Streak milestone XP
    if (streakBefore < 7 && streakAfter >= 7) await xpNotifier.onStreak7();
    if (streakBefore < 30 && streakAfter >= 30) await xpNotifier.onStreak30();

    // 3. Gather stats for achievement check
    final allRecords = await _getAllRecords();
    final tipsRead = _box.get(_tipsReadKey, defaultValue: 0) as int;
    final aiChats = _box.get(_aiChatsKey, defaultValue: 0) as int;
    final breathing = _box.get(_breathingKey, defaultValue: 0) as int;
    final meditation = _box.get(_meditationKey, defaultValue: 0) as int;
    final naps = _box.get(_napsKey, defaultValue: 0) as int;
    final mixes = _box.get(_customMixesKey, defaultValue: 0) as int;
    final uniqueSounds = _box.get(_uniqueSoundsKey, defaultValue: 0) as int;
    final daysUsed = _box.get(_daysUsedKey, defaultValue: 1) as int;
    final shieldUsed = _box.get(_shieldUsedKey, defaultValue: false) as bool;
    final shared = _box.get(_sharedKey, defaultValue: false) as bool;
    final configDone = _box.get(_configDoneKey, defaultValue: false) as bool;

    await _ref.read(achievementsProvider.notifier).checkAchievements(
          allRecords: allRecords,
          currentStreak: streakAfter,
          totalSleepRecords: allRecords.length,
          soundsUsed: allRecords.where((r) => r.usedSounds).length,
          uniqueSoundsUsed: uniqueSounds,
          tipsRead: tipsRead,
          aiChats: aiChats,
          habitsCompleted: 0, // updated separately
          breathingExercises: breathing,
          meditationSessions: meditation,
          naps: naps,
          customMixes: mixes,
          configComplete: configDone,
          shieldUsed: shieldUsed,
          scoreShared: shared,
          daysUsed: daysUsed,
        );

    // 4. Award XP for newly unlocked achievements
    final newlyUnlocked =
        _ref.read(achievementsProvider).newlyUnlocked;
    for (final _ in newlyUnlocked) {
      await xpNotifier.onAchievementUnlocked();
    }

    // 5. Show achievement notifications
    if (context != null && newlyUnlocked.isNotEmpty && context.mounted) {
      for (final achievement in newlyUnlocked) {
        AchievementNotificationWidget.show(context, achievement);
        await Future.delayed(const Duration(milliseconds: 600));
      }
      _ref.read(achievementsProvider.notifier).clearNewlyUnlocked();
    }

    // 6. Recalculate weekly score
    await _ref
        .read(weeklyScoreProvider.notifier)
        .calculateWeeklyScore(allRecords, habitCompletion);

    _syncState();
  }

  // ── Incremental Event Methods ─────────────────────────────────────────────

  Future<void> onTipRead() async {
    final current = _box.get(_tipsReadKey, defaultValue: 0) as int;
    await _box.put(_tipsReadKey, current + 1);
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('curioso_sueño');
  }

  Future<void> onAIChat() async {
    final current = _box.get(_aiChatsKey, defaultValue: 0) as int;
    await _box.put(_aiChatsKey, current + 1);
    await _ref.read(experienceProvider.notifier).onAIChat();
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('hablador');
  }

  Future<void> onBreathingExercise() async {
    final current = _box.get(_breathingKey, defaultValue: 0) as int;
    await _box.put(_breathingKey, current + 1);
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('respirador');
  }

  Future<void> onMeditationCompleted() async {
    final current = _box.get(_meditationKey, defaultValue: 0) as int;
    await _box.put(_meditationKey, current + 1);
    await _ref.read(experienceProvider.notifier).onMeditationCompleted();
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('meditador');
  }

  Future<void> onNapRecorded() async {
    final current = _box.get(_napsKey, defaultValue: 0) as int;
    await _box.put(_napsKey, current + 1);
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('siestero');
  }

  Future<void> onHabitCompleted() async {
    await _ref.read(experienceProvider.notifier).onHabitCompleted();
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('estudiante');
    _syncState();
  }

  Future<void> onConfigurationComplete() async {
    await _box.put(_configDoneKey, true);
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('configuracion_completa');
  }

  Future<void> onScoreShared() async {
    await _box.put(_sharedKey, true);
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('compartidor');
  }

  Future<void> onNewSound(String soundId) async {
    // Track unique sounds in a simple list
    final key = 'sound_ids';
    final existing =
        (_box.get(key, defaultValue: <dynamic>[]) as List).cast<String>();
    if (!existing.contains(soundId)) {
      existing.add(soundId);
      await _box.put(key, existing);
      await _box.put(_uniqueSoundsKey, existing.length);
    }
  }

  Future<void> onCustomMixCreated() async {
    final current = _box.get(_customMixesKey, defaultValue: 0) as int;
    await _box.put(_customMixesKey, current + 1);
    await _ref
        .read(achievementsProvider.notifier)
        .incrementProgress('mezclador');
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Future<List<SleepRecord>> _getAllRecords() async {
    final box = await Hive.openBox<SleepRecord>(AppConstants.sleepBoxName);
    return box.values.toList();
  }

  Future<void> _updateDaysUsed() async {
    final key = 'last_use_date';
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastStr = _box.get(key, defaultValue: '') as String;
    if (lastStr != todayStr) {
      await _box.put(key, todayStr);
      final current = _box.get(_daysUsedKey, defaultValue: 0) as int;
      await _box.put(_daysUsedKey, current + 1);
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationOverallState>(
  (ref) => GamificationNotifier(ref),
);
