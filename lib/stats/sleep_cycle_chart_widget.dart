import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dream_track/stats/stats_service.dart';
import 'package:dream_track/sleep/sleep_tracker_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/utils/date_utils.dart';

class SleepCycleChartWidget extends ConsumerStatefulWidget {
  const SleepCycleChartWidget({super.key});

  @override
  ConsumerState<SleepCycleChartWidget> createState() =>
      _SleepCycleChartWidgetState();
}

class _SleepCycleChartWidgetState extends ConsumerState<SleepCycleChartWidget> {
  List<SleepCyclePoint>? _cycles;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tracker = ref.read(sleepTrackerServiceProvider);
    final lastRecord = tracker.getLastRecord();
    if (lastRecord != null) {
      final service = ref.read(statsServiceProvider);
      final cycles = service.estimateSleepCycles(lastRecord);
      if (mounted) {
        setState(() {
          _cycles = cycles;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _colorForPhase(String phase) {
    switch (phase) {
      case 'deep': return AppTheme.primary;
      case 'rem': return AppTheme.secondary;
      case 'light': return AppTheme.info;
      default: return AppTheme.textMuted;
    }
  }

  double _valueForPhase(String phase) {
    switch (phase) {
      case 'deep': return 1;
      case 'rem': return 2;
      case 'light': return 3;
      default: return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final cycles = _cycles;
    if (cycles == null || cycles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhaseLegend(),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildChart(cycles),
        ),
        const SizedBox(height: 12),
        _buildPhaseStats(cycles),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bedtime_outlined, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'Sin datos de ciclos de sueño',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Registra una noche para ver tus ciclos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseLegend() {
    return Row(
      children: [
        _legendChip('Sueño profundo', AppTheme.primary),
        const SizedBox(width: 8),
        _legendChip('REM', AppTheme.secondary),
        const SizedBox(width: 8),
        _legendChip('Sueño ligero', AppTheme.info),
      ],
    );
  }

  Widget _legendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<SleepCyclePoint> cycles) {
    final spots = cycles.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        _valueForPhase(e.value.phase),
      );
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 5,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppTheme.cardBorder,
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: cycles.length / 4,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt().clamp(0, cycles.length - 1);
                return Text(
                  AppDateUtils.formatTime(cycles[idx].time),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontFamily: 'Nunito',
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 1: return const Text('Prof', style: TextStyle(color: AppTheme.primary, fontFamily: 'Nunito', fontSize: 10));
                  case 2: return const Text('REM', style: TextStyle(color: AppTheme.secondary, fontFamily: 'Nunito', fontSize: 10));
                  case 3: return const Text('Lig', style: TextStyle(color: AppTheme.info, fontFamily: 'Nunito', fontSize: 10));
                  case 4: return const Text('Des', style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito', fontSize: 10));
                  default: return const SizedBox.shrink();
                }
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primary.withOpacity(0.3),
                  AppTheme.primary.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseStats(List<SleepCyclePoint> cycles) {
    final deep = cycles.where((c) => c.phase == 'deep').length;
    final rem = cycles.where((c) => c.phase == 'rem').length;
    final light = cycles.where((c) => c.phase == 'light').length;
    final total = cycles.length;

    return Row(
      children: [
        _phaseBar('Profundo', deep / total, AppTheme.primary),
        const SizedBox(width: 4),
        _phaseBar('REM', rem / total, AppTheme.secondary),
        const SizedBox(width: 4),
        _phaseBar('Ligero', light / total, AppTheme.info),
      ],
    );
  }

  Widget _phaseBar(String label, double fraction, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            width: double.infinity,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, color: AppTheme.textMuted),
          ),
          Text(
            '${(fraction * 100).round()}%',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
