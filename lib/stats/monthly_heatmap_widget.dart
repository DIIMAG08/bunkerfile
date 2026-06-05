import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/stats/stats_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/utils/date_utils.dart';

class MonthlyHeatmapWidget extends ConsumerStatefulWidget {
  const MonthlyHeatmapWidget({super.key});

  @override
  ConsumerState<MonthlyHeatmapWidget> createState() =>
      _MonthlyHeatmapWidgetState();
}

class _MonthlyHeatmapWidgetState extends ConsumerState<MonthlyHeatmapWidget> {
  MonthlySleepStats? _stats;
  bool _loading = true;
  DateTime _reference = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = ref.read(statsServiceProvider);
    final stats = await service.getMonthlyStats(_reference);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  Color _colorForDay(int day) {
    final hours = _stats?.dailyHoursMap[day];
    final quality = _stats?.dailyQualityMap[day];

    if (hours == null) return AppTheme.surfaceLight;

    if (hours >= 7 && (quality ?? 0) >= 4) {
      return AppTheme.success; // Green - good sleep
    } else if (hours >= 5) {
      return AppTheme.warning; // Yellow - fair sleep
    } else {
      return AppTheme.error; // Red - poor sleep
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final stats = _stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 16),
        _buildCalendar(),
        const SizedBox(height: 16),
        _buildLegend(),
        if (stats != null) ...[
          const SizedBox(height: 16),
          _buildMonthSummary(stats),
        ],
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            _reference = DateTime(_reference.year, _reference.month - 1, 1);
            _load();
          },
          icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textSecondary),
        ),
        Text(
          AppDateUtils.formatMonthYear(_reference),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
        IconButton(
          onPressed: _reference.month == DateTime.now().month &&
                  _reference.year == DateTime.now().year
              ? null
              : () {
                  _reference = DateTime(_reference.year, _reference.month + 1, 1);
                  _load();
                },
          icon: Icon(
            Icons.chevron_right_rounded,
            color: _reference.month == DateTime.now().month
                ? AppTheme.textMuted
                : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_reference.year, _reference.month, 1);
    final daysInMonth = DateTime(_reference.year, _reference.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon, 7=Sun

    return Column(
      children: [
        _buildWeekdayHeaders(),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday - 1 + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday - 1) {
              return const SizedBox.shrink();
            }
            final day = index - (startWeekday - 2);
            return _buildDayCell(day);
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      children: days.map((d) => Expanded(
        child: Center(
          child: Text(
            d,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDayCell(int day) {
    final color = _colorForDay(day);
    final hasData = _stats?.dailyHoursMap.containsKey(day) ?? false;
    final isToday = DateTime.now().day == day &&
        DateTime.now().month == _reference.month &&
        DateTime.now().year == _reference.year;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(hasData ? 0.8 : 0.15),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppTheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: hasData ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppTheme.success, '>7h + buena calidad'),
        const SizedBox(width: 16),
        _legendItem(AppTheme.warning, '5-7h'),
        const SizedBox(width: 16),
        _legendItem(AppTheme.error, '<5h o mala'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
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

  Widget _buildMonthSummary(MonthlySleepStats stats) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Promedio', '${stats.avgHours.toStringAsFixed(1)}h', AppTheme.primary)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Deuda', '${stats.totalSleepDebt.toStringAsFixed(1)}h', AppTheme.warning)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Registros', '${stats.daysWithData}d', AppTheme.success)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          )),
          Text(label, style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: AppTheme.textMuted,
          )),
        ],
      ),
    );
  }
}
