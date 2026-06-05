import 'package:flutter/material.dart';
import 'package:dream_track/shared/theme/app_theme.dart';

class ScoreHistoryWidget extends StatelessWidget {
  final List<double> scores; // Last 8 weeks of scores

  const ScoreHistoryWidget({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return Center(
        child: Text(
          'Sin historial de puntuaciones aún',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final maxScore = scores.fold(0.0, (a, b) => a > b ? a : b).clamp(1.0, 100.0);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: scores.asMap().entries.map((e) {
          final score = e.value;
          final fraction = (score / 100).clamp(0.05, 1.0);
          final color = _colorForScore(score.round());
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                score.round().toString(),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: Duration(milliseconds: 500 + e.key * 100),
                width: 28,
                height: 80 * fraction,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'S${e.key + 1}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _colorForScore(int score) {
    if (score >= 91) return const Color(0xFF74B9FF);
    if (score >= 76) return const Color(0xFF4ECDC4);
    if (score >= 61) return const Color(0xFFFFBE76);
    if (score >= 41) return const Color(0xFFF0A500);
    return const Color(0xFFFF6B6B);
  }
}
