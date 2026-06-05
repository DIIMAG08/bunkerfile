import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dream_track/gamification/score_gauge_widget.dart';
import 'package:dream_track/gamification/weekly_score_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';

class WeeklyScoreScreen extends ConsumerWidget {
  const WeeklyScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklyScoreProvider);
    final current = state.current;
    final delta = state.weekOverWeekDelta;
    final history = ref
        .read(weeklyScoreProvider.notifier)
        .getLastNWeeks(8)
        .reversed
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Puntuación Semanal',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.primary),
            tooltip: 'Compartir',
            onPressed: () => _onShare(context, current),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Gauge ─────────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  ScoreGaugeWidget(
                    score: current?.total ?? 0,
                    size: 200,
                  ),
                  if (delta != null) ...[
                    const SizedBox(height: 16),
                    _DeltaChip(delta: delta),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Factor Breakdown ──────────────────────────────────────────────
            if (current != null) ...[
              _FactorCard(
                title: '💤 Horas de Sueño',
                description: 'Días que cumpliste tu meta',
                score: current.hoursScore,
                maxScore: 35,
              ),
              const SizedBox(height: 10),
              _FactorCard(
                title: '⏰ Regularidad de Horarios',
                description: 'Consistencia de hora de dormir',
                score: current.regularityScore,
                maxScore: 25,
              ),
              const SizedBox(height: 10),
              _FactorCard(
                title: '⭐ Calidad Promedio',
                description: 'Calidad de sueño reportada',
                score: current.qualityScore,
                maxScore: 25,
              ),
              const SizedBox(height: 10),
              _FactorCard(
                title: '✅ Hábitos Completados',
                description: 'Rutinas de higiene del sueño',
                score: current.habitScore,
                maxScore: 15,
              ),
              const SizedBox(height: 16),
            ],

            // ── History Chart ─────────────────────────────────────────────────
            if (history.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Últimas 8 semanas',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: _ScoreLineChart(history: history),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _onShare(BuildContext context, WeeklyScore? score) {
    if (score == null) return;
    final text =
        '🌙 Mi puntuación semanal en DreamTrack: ${score.total}/100 – ${score.label}\n'
        '💤 Horas: ${score.hoursScore}/35  ⏰ Regularidad: ${score.regularityScore}/25\n'
        '⭐ Calidad: ${score.qualityScore}/25  ✅ Hábitos: ${score.habitScore}/15';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡Compartido! $text',
          maxLines: 3,
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
        backgroundColor: AppTheme.surface,
      ),
    );
  }
}

// ─── Delta Chip ───────────────────────────────────────────────────────────────

class _DeltaChip extends StatelessWidget {
  final int delta;
  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final better = delta >= 0;
    final color = better ? AppTheme.success : AppTheme.error;
    final icon = better ? '↑' : '↓';
    final text = better
        ? '+$delta pts que la semana pasada'
        : '$delta pts que la semana pasada';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$icon $text',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Factor Card ──────────────────────────────────────────────────────────────

class _FactorCard extends StatelessWidget {
  final String title;
  final String description;
  final int score;
  final int maxScore;

  const _FactorCard({
    required this.title,
    required this.description,
    required this.score,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore > 0 ? score / maxScore : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$score / $maxScore',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppTheme.cardBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Line Chart ───────────────────────────────────────────────────────────────

class _ScoreLineChart extends StatelessWidget {
  final List<WeeklyScore> history; // oldest first

  const _ScoreLineChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(history.length, (i) {
      return FlSpot(i.toDouble(), history[i].total.toDouble());
    });

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.cardBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= history.length) {
                  return const SizedBox.shrink();
                }
                final d = history[idx].weekStartDate;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.day}/${d.month}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      color: AppTheme.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppTheme.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primary,
                strokeWidth: 1.5,
                strokeColor: AppTheme.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.25),
                  AppTheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
