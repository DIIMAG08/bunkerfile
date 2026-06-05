import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dream_track/shared/theme/app_theme.dart';

/// Animated circular gauge displaying a score from 0 to 100.
/// Color changes by range, score number in center, label below.
class ScoreGaugeWidget extends StatefulWidget {
  final int score;
  final double size;
  final bool animate;

  const ScoreGaugeWidget({
    super.key,
    required this.score,
    this.size = 180,
    this.animate = true,
  });

  @override
  State<ScoreGaugeWidget> createState() => _ScoreGaugeWidgetState();
}

class _ScoreGaugeWidgetState extends State<ScoreGaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fillAnimation = Tween<double>(
      begin: 0,
      end: widget.score / 100.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ScoreGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _fillAnimation = Tween<double>(
        begin: oldWidget.score / 100.0,
        end: widget.score / 100.0,
      ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(int score) {
    if (score >= 91) return const Color(0xFF4F9EF7); // bright blue
    if (score >= 76) return AppTheme.success;         // green
    if (score >= 61) return AppTheme.warning;          // yellow
    if (score >= 41) return const Color(0xFFFF9F43);  // orange
    return AppTheme.error;                             // red
  }

  String _scoreLabel(int score) {
    if (score >= 91) return 'Excelente';
    if (score >= 76) return 'Muy bien';
    if (score >= 61) return 'Buen trabajo';
    if (score >= 41) return 'Puedes hacerlo mejor';
    return 'Necesitas mejorar';
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(widget.score);
    final label = _scoreLabel(widget.score);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _fillAnimation,
          builder: (context, _) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _GaugePainter(
                fill: _fillAnimation.value,
                color: color,
                trackColor: AppTheme.cardBorder,
              ),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_fillAnimation.value * 100).round()}',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: widget.size * 0.22,
                          color: color,
                        ),
                      ),
                      Text(
                        'puntos',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: widget.size * 0.075,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            label,
            key: ValueKey(label),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Custom Painter ──────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  final double fill;   // 0.0 – 1.0
  final Color color;
  final Color trackColor;

  const _GaugePainter({
    required this.fill,
    required this.color,
    required this.trackColor,
  });

  static const double _startAngle = 140 * (math.pi / 180);
  static const double _sweepFull = 260 * (math.pi / 180);
  static const double _strokeWidth = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (background arc)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _sweepFull, false, trackPaint);

    // Filled arc
    if (fill > 0) {
      final fillPaint = Paint()
        ..color = color
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        _startAngle,
        _sweepFull * fill,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.fill != fill || old.color != color;
}
