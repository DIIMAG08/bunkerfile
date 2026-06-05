import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dream_track/gamification/achievement_model.dart';
import 'package:dream_track/shared/theme/app_theme.dart';

/// Overlay banner that appears at the top of the screen when an achievement
/// is unlocked. Auto-dismisses after 3 seconds.
class AchievementNotificationWidget extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementNotificationWidget({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  /// Shows the notification as an overlay entry on top of the current route.
  static OverlayEntry show(
    BuildContext context,
    Achievement achievement,
  ) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AchievementNotificationWidget(
        achievement: achievement,
        onDismiss: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<AchievementNotificationWidget> createState() =>
      _AchievementNotificationWidgetState();
}

class _AchievementNotificationWidgetState
    extends State<AchievementNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
    );

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _BannerContent(
            achievement: widget.achievement,
            onTap: _dismiss,
          ),
        ),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _BannerContent({
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2260), Color(0xFF111630)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.2),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _iconEmoji(achievement.iconName),
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🏆 Logro desbloqueado',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.name,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Dismiss icon
              const SizedBox(width: 8),
              const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _iconEmoji(String iconName) {
    const map = {
      'moon_stars': '🌙',
      'calendar_week': '📅',
      'calendar_month': '🗓️',
      'settings_check': '⚙️',
      'sunrise': '🌅',
      'clock_check': '⏰',
      'fire_medium': '🔥',
      'shield_star': '🛡️',
      'crown': '👑',
      'star_filled': '⭐',
      'gold_medal': '🥇',
      'no_bell': '🔕',
      'heart_pulse': '💓',
      'music_note': '🎵',
      'mute': '🔇',
      'book_open': '📖',
      'chat_bubble': '💬',
      'equalizer': '🎚️',
      'checklist': '✅',
      'lungs': '🫁',
      'lotus': '🧘',
      'nap': '😴',
      'trophy': '🏆',
      'diamond': '💎',
      'shield': '🛡️',
      'share': '📤',
    };
    return map[iconName] ?? '🎖️';
  }
}
