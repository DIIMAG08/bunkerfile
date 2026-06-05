import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dream_track/gamification/streak_service.dart';
import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';

/// Dashboard widget that shows the current streak with animated glow,
/// a weekly mini-calendar, and the next milestone progress bar.
class StreakWidget extends ConsumerStatefulWidget {
  /// Recent sleep records used to build the weekly calendar.
  final List<SleepRecord> recentRecords;

  /// The user's sleep goal in hours.
  final double goalHours;

  const StreakWidget({
    super.key,
    required this.recentRecords,
    this.goalHours = 8.0,
  });

  @override
  ConsumerState<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends ConsumerState<StreakWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color _glowColor(String level) {
    switch (level) {
      case 'max':
        return AppTheme.streakMax;
      case 'large':
        return AppTheme.streakLarge;
      case 'medium':
        return AppTheme.streakMedium;
      default:
        return AppTheme.streakSmall;
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);
    final notifier = ref.read(streakProvider.notifier);
    final level = notifier.streakLevel;
    final glowColor = _glowColor(level);
    final nextMilestone = notifier.getNextMilestone();
    final prevMilestone = _prevMilestone(streak.currentStreak);
    final milestoneProgress = nextMilestone <= prevMilestone
        ? 1.0
        : (streak.currentStreak - prevMilestone) /
            (nextMilestone - prevMilestone);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Racha de Sueño',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (streak.shieldsAvailable > 0)
                _ShieldBadge(count: streak.shieldsAvailable),
            ],
          ),
          const SizedBox(height: 20),

          // ── Big Streak Number with animated glow ───────────────────────────
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor
                          .withOpacity(_glowAnimation.value * 0.5),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                  border: Border.all(
                    color: glowColor
                        .withOpacity(_glowAnimation.value * 0.7),
                    width: 2,
                  ),
                ),
                child: child,
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                Text(
                  '${streak.currentStreak}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text(
            streak.currentStreak == 1
                ? '1 día seguido'
                : '${streak.currentStreak} días seguidos',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),

          if (streak.longestStreak > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Mejor racha: ${streak.longestStreak} días',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Milestone Progress Bar ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximo hito: $nextMilestone días',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '${streak.currentStreak}/$nextMilestone',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: milestoneProgress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppTheme.cardBorder,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_glowColor(level)),
                minHeight: 8,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Weekly Calendar ───────────────────────────────────────────────
          _WeeklyCalendar(
            recentRecords: widget.recentRecords,
            goalHours: widget.goalHours,
          ),
        ],
      ),
    );
  }

  int _prevMilestone(int current) {
    int prev = 0;
    for (final m in AppConstants.streakMilestones) {
      if (current >= m) prev = m;
    }
    return prev;
  }
}

// ─── Shield Badge ─────────────────────────────────────────────────────────────

class _ShieldBadge extends StatelessWidget {
  final int count;
  const _ShieldBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            'x$count',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Weekly Calendar ─────────────────────────────────────────────────────────

class _WeeklyCalendar extends StatelessWidget {
  final List<SleepRecord> recentRecords;
  final double goalHours;

  const _WeeklyCalendar({
    required this.recentRecords,
    required this.goalHours,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    // Map date → record (wakeTime date)
    final Map<DateTime, SleepRecord?> dayMap = {};
    for (final d in days) {
      SleepRecord? found;
      for (final r in recentRecords) {
        final w = DateTime(r.wakeTime.year, r.wakeTime.month, r.wakeTime.day);
        if (w == d) {
          found = r;
          break;
        }
      }
      dayMap[d] = found;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = days[i];
        final record = dayMap[day];
        final isToday = day ==
            DateTime(now.year, now.month, now.day);
        final metGoal = record != null && record.hoursSlept >= goalHours;
        final missed = record == null && day.isBefore(DateTime.now());

        Color dotColor;
        if (record != null) {
          dotColor = metGoal ? AppTheme.success : AppTheme.error;
        } else if (missed) {
          dotColor = AppTheme.error.withOpacity(0.4);
        } else {
          dotColor = AppTheme.cardBorder;
        }

        return Column(
          children: [
            Text(
              dayLabels[day.weekday - 1],
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: isToday ? AppTheme.primary : AppTheme.textMuted,
                fontWeight:
                    isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor.withOpacity(0.18),
                border: Border.all(
                  color: isToday
                      ? AppTheme.primary
                      : dotColor.withOpacity(0.5),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Center(
                child: record != null
                    ? Icon(
                        metGoal ? Icons.check : Icons.close,
                        size: 14,
                        color: dotColor,
                      )
                    : Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          color: AppTheme.textMuted.withOpacity(0.6),
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
