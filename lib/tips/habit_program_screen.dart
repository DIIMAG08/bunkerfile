import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/tips/daily_tip_service.dart';
import 'package:dream_track/tips/tips_data.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';

class HabitProgramScreen extends ConsumerStatefulWidget {
  const HabitProgramScreen({super.key});

  @override
  ConsumerState<HabitProgramScreen> createState() => _HabitProgramScreenState();
}

class _HabitProgramScreenState extends ConsumerState<HabitProgramScreen> {
  Set<int> _completedDays = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(dailyTipServiceProvider);
    final completed = await service.getCompletedDays();
    if (mounted) {
      setState(() {
        _completedDays = completed;
        _loading = false;
      });
    }
  }

  double get _completionRate => _completedDays.length / habitProgram.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressSection(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: habitProgram.length,
                        itemBuilder: (context, i) {
                          final habit = habitProgram[i];
                          final day = habit['day'] as int;
                          final isCompleted = _completedDays.contains(day);
                          return _buildHabitCard(habit, isCompleted, day);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Programa de 21 Días', style: Theme.of(context).textTheme.headlineMedium),
              Text('Hábitos para mejorar tu sueño', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Tu progreso',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${_completedDays.length}/21 días',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${(_completionRate * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _completionRate,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit, bool isCompleted, int day) {
    final categoryColor = _categoryColor(habit['category'] as String);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: isCompleted ? AppTheme.success.withOpacity(0.3) : null,
      backgroundColor: isCompleted ? AppTheme.success.withOpacity(0.05) : null,
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final service = ref.read(dailyTipServiceProvider);
              if (isCompleted) {
                await service.unmarkDay(day);
              } else {
                await service.markDayCompleted(day);
              }
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppTheme.success : AppTheme.surfaceLight,
                border: Border.all(
                  color: isCompleted ? AppTheme.success : AppTheme.cardBorder,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : Text(
                        '$day',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Día $day',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        habit['category'] as String,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          color: categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  habit['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  habit['desc'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Alimentación': return AppTheme.warning;
      case 'Ejercicio': return AppTheme.success;
      case 'Digital': return AppTheme.secondary;
      case 'Relajación': return AppTheme.primary;
      case 'Estrés': return AppTheme.error;
      case 'Ambiente': return AppTheme.info;
      case 'Reflexión': return const Color(0xFFB8C0FF);
      case 'Celebración': return const Color(0xFFFFD700);
      case 'Base': return AppTheme.textSecondary;
      default: return AppTheme.textSecondary;
    }
  }
}
