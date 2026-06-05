import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:dream_track/gamification/achievement_model.dart';
import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class AchievementsState {
  final List<Achievement> achievements;
  final List<Achievement> newlyUnlocked; // cleared after reading

  const AchievementsState({
    required this.achievements,
    this.newlyUnlocked = const [],
  });

  AchievementsState copyWith({
    List<Achievement>? achievements,
    List<Achievement>? newlyUnlocked,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      newlyUnlocked: newlyUnlocked ?? this.newlyUnlocked,
    );
  }

  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

  List<Achievement> byCategory(String category) =>
      achievements.where((a) => a.category == category).toList();

  static const List<String> categories = [
    'Primeros Pasos',
    'Constancia',
    'Calidad',
    'Exploración',
    'Hábitos',
    'Especial',
  ];
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  late Box<Achievement> _box;

  AchievementsNotifier() : super(const AchievementsState(achievements: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<Achievement>(AppConstants.achievementsBoxName);
    if (_box.isEmpty) {
      await _seedAchievements();
    }
    state = AchievementsState(achievements: _box.values.toList());
  }

  // ── Seeding ─────────────────────────────────────────────────────────────────

  Future<void> _seedAchievements() async {
    final defaults = _buildDefaultAchievements();
    for (final a in defaults) {
      await _box.put(a.id, a);
    }
  }

  List<Achievement> _buildDefaultAchievements() {
    return [
      // ── Primeros Pasos ──────────────────────────────────────────────────────
      Achievement(
        id: 'primera_noche',
        name: 'Primera Noche',
        description: 'Registra tu primera noche de sueño',
        category: 'Primeros Pasos',
        goal: 1,
        iconName: 'moon_stars',
      ),
      Achievement(
        id: 'primera_semana',
        name: 'Primera Semana',
        description: 'Registra 7 noches seguidas',
        category: 'Primeros Pasos',
        goal: 7,
        iconName: 'calendar_week',
      ),
      Achievement(
        id: 'primer_mes',
        name: 'Primer Mes',
        description: 'Registra 30 noches en total',
        category: 'Primeros Pasos',
        goal: 30,
        iconName: 'calendar_month',
      ),
      Achievement(
        id: 'configuracion_completa',
        name: 'Todo Listo',
        description: 'Completa toda la configuración inicial',
        category: 'Primeros Pasos',
        goal: 1,
        iconName: 'settings_check',
      ),

      // ── Constancia ──────────────────────────────────────────────────────────
      Achievement(
        id: 'madrugador',
        name: 'Madrugador',
        description: 'Levántate antes de las 7am 5 veces',
        category: 'Constancia',
        goal: 5,
        iconName: 'sunrise',
      ),
      Achievement(
        id: 'mismo_horario',
        name: 'Reloj Biológico',
        description: 'Mantén el mismo horario de sueño 7 días seguidos',
        category: 'Constancia',
        goal: 7,
        iconName: 'clock_check',
      ),
      Achievement(
        id: 'maquina_dormir',
        name: 'Máquina de Dormir',
        description: 'Alcanza una racha de 21 días',
        category: 'Constancia',
        goal: 21,
        iconName: 'fire_medium',
      ),
      Achievement(
        id: 'guerrero_sueño',
        name: 'Guerrero del Sueño',
        description: 'Alcanza una racha de 60 días',
        category: 'Constancia',
        goal: 60,
        iconName: 'shield_star',
      ),
      Achievement(
        id: 'leyenda_descanso',
        name: 'Leyenda del Descanso',
        description: 'Alcanza una racha de 365 días',
        category: 'Constancia',
        goal: 365,
        iconName: 'crown',
      ),

      // ── Calidad ─────────────────────────────────────────────────────────────
      Achievement(
        id: 'noche_de_10',
        name: 'Noche de 10',
        description: 'Registra una noche con calidad máxima',
        category: 'Calidad',
        goal: 1,
        iconName: 'star_filled',
      ),
      Achievement(
        id: 'semana_de_oro',
        name: 'Semana de Oro',
        description: 'Obtén calidad 5 durante 7 noches seguidas',
        category: 'Calidad',
        goal: 7,
        iconName: 'gold_medal',
      ),
      Achievement(
        id: 'sin_interrupciones',
        name: 'Sin Interrupciones',
        description: 'Duerme sin despertarte 5 noches seguidas',
        category: 'Calidad',
        goal: 5,
        iconName: 'no_bell',
      ),
      Achievement(
        id: 'sueño_reparador',
        name: 'Sueño Reparador',
        description: 'Logra 10 noches con puntuación semanal > 80',
        category: 'Calidad',
        goal: 10,
        iconName: 'heart_pulse',
      ),

      // ── Exploración ─────────────────────────────────────────────────────────
      Achievement(
        id: 'melomano',
        name: 'Melómano',
        description: 'Usa 5 sonidos diferentes para dormir',
        category: 'Exploración',
        goal: 5,
        iconName: 'music_note',
      ),
      Achievement(
        id: 'maestro_silencio',
        name: 'Maestro del Silencio',
        description: 'Duerme en modo silencio 10 veces',
        category: 'Exploración',
        goal: 10,
        iconName: 'mute',
      ),
      Achievement(
        id: 'curioso_sueño',
        name: 'Curioso del Sueño',
        description: 'Lee 10 consejos de sueño',
        category: 'Exploración',
        goal: 10,
        iconName: 'book_open',
      ),
      Achievement(
        id: 'hablador',
        name: 'Hablador',
        description: 'Chatea con la IA 20 veces',
        category: 'Exploración',
        goal: 20,
        iconName: 'chat_bubble',
      ),
      Achievement(
        id: 'mezclador',
        name: 'Mezclador',
        description: 'Crea 3 mezclas de sonidos personalizadas',
        category: 'Exploración',
        goal: 3,
        iconName: 'equalizer',
      ),

      // ── Hábitos ─────────────────────────────────────────────────────────────
      Achievement(
        id: 'estudiante',
        name: 'Estudiante Aplicado',
        description: 'Completa 30 hábitos de higiene del sueño',
        category: 'Hábitos',
        goal: 30,
        iconName: 'checklist',
      ),
      Achievement(
        id: 'respirador',
        name: 'Maestro de la Respiración',
        description: 'Completa 15 ejercicios de respiración',
        category: 'Hábitos',
        goal: 15,
        iconName: 'lungs',
      ),
      Achievement(
        id: 'meditador',
        name: 'Meditador',
        description: 'Completa 10 sesiones de meditación',
        category: 'Hábitos',
        goal: 10,
        iconName: 'lotus',
      ),
      Achievement(
        id: 'siestero',
        name: 'Siestero Pro',
        description: 'Registra 5 siestas cortas',
        category: 'Hábitos',
        goal: 5,
        iconName: 'nap',
      ),

      // ── Especial ─────────────────────────────────────────────────────────────
      Achievement(
        id: 'año_completo',
        name: 'Año Completo',
        description: 'Usa DreamTrack durante 365 días',
        category: 'Especial',
        goal: 365,
        iconName: 'trophy',
      ),
      Achievement(
        id: 'noche_perfecta',
        name: 'Noche Perfecta',
        description: 'Calidad 5, sin interrupciones y meta cumplida',
        category: 'Especial',
        goal: 1,
        iconName: 'diamond',
      ),
      Achievement(
        id: 'guardian',
        name: 'Guardián',
        description: 'Usa un escudo de racha por primera vez',
        category: 'Especial',
        goal: 1,
        iconName: 'shield',
      ),
      Achievement(
        id: 'compartidor',
        name: 'Compartidor',
        description: 'Comparte tu puntuación semanal',
        category: 'Especial',
        goal: 1,
        iconName: 'share',
      ),
    ];
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Clear newly unlocked list (call after showing notifications).
  void clearNewlyUnlocked() {
    state = state.copyWith(newlyUnlocked: []);
  }

  /// Main check: evaluate all achievements against current app data.
  Future<void> checkAchievements({
    required List<SleepRecord> allRecords,
    required int currentStreak,
    required int totalSleepRecords,
    int soundsUsed = 0,
    int uniqueSoundsUsed = 0,
    int tipsRead = 0,
    int aiChats = 0,
    int habitsCompleted = 0,
    int breathingExercises = 0,
    int meditationSessions = 0,
    int naps = 0,
    int customMixes = 0,
    bool configComplete = false,
    bool shieldUsed = false,
    bool scoreShared = false,
    int daysUsed = 0,
  }) async {
    final newly = <Achievement>[];

    Future<void> tryUnlock(
      String id, {
      int? newProgress,
    }) async {
      final a = _box.get(id);
      if (a == null || a.isUnlocked) return;

      final updated = Achievement(
        id: a.id,
        name: a.name,
        description: a.description,
        category: a.category,
        isUnlocked: newProgress == null
            ? true
            : newProgress >= a.goal,
        unlockedAt:
            (newProgress == null || newProgress >= a.goal) ? DateTime.now() : null,
        progress: newProgress ?? a.goal,
        goal: a.goal,
        iconName: a.iconName,
      );
      await _box.put(id, updated);
      if (updated.isUnlocked) newly.add(updated);
    }

    Future<void> updateProgress(String id, int progress) async {
      final a = _box.get(id);
      if (a == null || a.isUnlocked) return;
      if (progress > a.progress) {
        await tryUnlock(id, newProgress: progress);
      }
    }

    // ── Primeros Pasos ──────────────────────────────────────────────────────
    if (totalSleepRecords >= 1) await tryUnlock('primera_noche');
    await updateProgress('primera_semana', currentStreak.clamp(0, 7));
    await updateProgress('primer_mes', totalSleepRecords.clamp(0, 30));
    if (configComplete) await tryUnlock('configuracion_completa');

    // ── Constancia ──────────────────────────────────────────────────────────
    // Madrugador: woke before 7am
    final earlyRises = allRecords
        .where((r) => r.wakeTime.hour < 7)
        .length;
    await updateProgress('madrugador', earlyRises.clamp(0, 5));

    // Mismo horario: consistent bed/wake times within 30 min for 7 days
    final consistentDays = _countConsistentDays(allRecords);
    await updateProgress('mismo_horario', consistentDays.clamp(0, 7));

    await updateProgress('maquina_dormir', currentStreak.clamp(0, 21));
    await updateProgress('guerrero_sueño', currentStreak.clamp(0, 60));
    await updateProgress('leyenda_descanso', currentStreak.clamp(0, 365));

    // ── Calidad ─────────────────────────────────────────────────────────────
    if (allRecords.any((r) => r.quality == 5)) await tryUnlock('noche_de_10');

    // Semana de oro: 7 consecutive quality-5 nights
    final q5Streak = _maxConsecutiveQuality(allRecords, 5);
    await updateProgress('semana_de_oro', q5Streak.clamp(0, 7));

    // Sin interrupciones: 5 consecutive nights with 0 wake-ups
    final noWakeStreak = _maxConsecutiveNoWakeups(allRecords);
    await updateProgress('sin_interrupciones', noWakeStreak.clamp(0, 5));

    await updateProgress('sueño_reparador', 0); // updated by weekly score service

    // ── Exploración ─────────────────────────────────────────────────────────
    await updateProgress('melomano', uniqueSoundsUsed.clamp(0, 5));
    final silenceNights =
        allRecords.where((r) => !r.usedSounds).length;
    await updateProgress('maestro_silencio', silenceNights.clamp(0, 10));
    await updateProgress('curioso_sueño', tipsRead.clamp(0, 10));
    await updateProgress('hablador', aiChats.clamp(0, 20));
    await updateProgress('mezclador', customMixes.clamp(0, 3));

    // ── Hábitos ─────────────────────────────────────────────────────────────
    await updateProgress('estudiante', habitsCompleted.clamp(0, 30));
    await updateProgress('respirador', breathingExercises.clamp(0, 15));
    await updateProgress('meditador', meditationSessions.clamp(0, 10));
    await updateProgress('siestero', naps.clamp(0, 5));

    // ── Especial ─────────────────────────────────────────────────────────────
    await updateProgress('año_completo', daysUsed.clamp(0, 365));

    // Noche perfecta: quality 5, 0 wakeups, met goal
    if (allRecords.any(
        (r) => r.quality == 5 && r.wakeUps == 0 && r.hoursSlept >= 7.0)) {
      await tryUnlock('noche_perfecta');
    }
    if (shieldUsed) await tryUnlock('guardian');
    if (scoreShared) await tryUnlock('compartidor');

    // Reload state
    state = AchievementsState(
      achievements: _box.values.toList(),
      newlyUnlocked: newly,
    );
  }

  /// Manually increment a single achievement's progress (e.g., from other services).
  Future<void> incrementProgress(String id, {int by = 1}) async {
    final a = _box.get(id);
    if (a == null || a.isUnlocked) return;
    final newProgress = (a.progress + by).clamp(0, a.goal);
    final nowUnlocked = newProgress >= a.goal;
    final updated = Achievement(
      id: a.id,
      name: a.name,
      description: a.description,
      category: a.category,
      isUnlocked: nowUnlocked,
      unlockedAt: nowUnlocked ? DateTime.now() : null,
      progress: newProgress,
      goal: a.goal,
      iconName: a.iconName,
    );
    await _box.put(id, updated);
    final newly = nowUnlocked ? [updated] : <Achievement>[];
    state = AchievementsState(
      achievements: _box.values.toList(),
      newlyUnlocked: [...state.newlyUnlocked, ...newly],
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Count how many of the last N records have consistent bed/wake within ±30 min.
  int _countConsistentDays(List<SleepRecord> records) {
    if (records.length < 2) return 0;
    final sorted = [...records]..sort((a, b) => a.bedTime.compareTo(b.bedTime));
    int streak = 0;
    int best = 0;
    for (int i = 1; i < sorted.length; i++) {
      final prevBed = sorted[i - 1].bedTime;
      final curBed = sorted[i].bedTime;
      final bedDiff = (curBed.hour * 60 + curBed.minute) -
          (prevBed.hour * 60 + prevBed.minute);
      if (bedDiff.abs() <= 30) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 0;
      }
    }
    return best;
  }

  int _maxConsecutiveQuality(List<SleepRecord> records, int minQuality) {
    if (records.isEmpty) return 0;
    final sorted = [...records]..sort((a, b) => a.bedTime.compareTo(b.bedTime));
    int streak = 0;
    int best = 0;
    for (final r in sorted) {
      if (r.quality >= minQuality) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 0;
      }
    }
    return best;
  }

  int _maxConsecutiveNoWakeups(List<SleepRecord> records) {
    if (records.isEmpty) return 0;
    final sorted = [...records]..sort((a, b) => a.bedTime.compareTo(b.bedTime));
    int streak = 0;
    int best = 0;
    for (final r in sorted) {
      if (r.wakeUps == 0) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 0;
      }
    }
    return best;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>(
  (ref) => AchievementsNotifier(),
);
