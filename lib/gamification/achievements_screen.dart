import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dream_track/gamification/achievement_model.dart';
import 'package:dream_track/gamification/achievements_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = AchievementsState.categories;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(achievementsProvider);
    final total = state.achievements.length;
    final unlocked = state.unlockedCount;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Logros', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Header counter
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏆 ', style: TextStyle(fontSize: 18)),
                    Text(
                      '$unlocked / $total desbloqueados',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? unlocked / total : 0,
                    backgroundColor: AppTheme.cardBorder,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tab bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w400, fontSize: 13),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((category) {
          final items = state.byCategory(category);
          return _CategoryGrid(achievements: items);
        }).toList(),
      ),
    );
  }
}

// ─── Category Grid ────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<Achievement> achievements;

  const _CategoryGrid({required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return const Center(
        child: Text('Sin logros en esta categoría',
            style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito')),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _AchievementCard(achievement: achievements[index]);
      },
    );
  }
}

// ─── Achievement Card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatefulWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnimation =
        Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    if (widget.achievement.isUnlocked) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    final locked = !a.isUnlocked;

    return GestureDetector(
      onTap: () => _showDetail(context, a),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: locked
                    ? AppTheme.cardBorder
                    : AppTheme.primary.withOpacity(_glowAnimation.value * 0.6),
                width: locked ? 1 : 1.5,
              ),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.primary
                            .withOpacity(_glowAnimation.value * 0.25),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: locked
                      ? AppTheme.surfaceLight
                      : AppTheme.primary.withOpacity(0.15),
                ),
                child: Center(
                  child: Text(
                    _iconEmoji(a.iconName),
                    style: TextStyle(
                      fontSize: 26,
                      color: locked ? Colors.transparent : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Name
              Text(
                a.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: locked ? AppTheme.textMuted : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Progress or locked text
              if (a.isProgressBased && !a.isUnlocked) ...[
                const SizedBox(height: 6),
                Text(
                  '${a.progress} / ${a.goal}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.progressRatio,
                    backgroundColor: AppTheme.cardBorder,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    minHeight: 5,
                  ),
                ),
              ] else if (a.isUnlocked) ...[
                const SizedBox(height: 4),
                const Text('✓ Desbloqueado',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    )),
              ] else ...[
                const SizedBox(height: 4),
                const Text('🔒 Bloqueado',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Achievement a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AchievementDetailSheet(achievement: a),
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

// ─── Detail Sheet ─────────────────────────────────────────────────────────────

class _AchievementDetailSheet extends StatelessWidget {
  final Achievement achievement;

  const _AchievementDetailSheet({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _iconEmoji(a.iconName),
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 16),
          Text(
            a.name,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              a.category,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            a.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          if (a.isProgressBased) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progreso',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        color: AppTheme.textSecondary,
                        fontSize: 13)),
                Text('${a.progress} / ${a.goal}',
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: a.progressRatio,
                backgroundColor: AppTheme.cardBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 10,
              ),
            ),
          ],
          if (a.isUnlocked && a.unlockedAt != null) ...[
            const SizedBox(height: 16),
            Text(
              'Desbloqueado el ${_formatDate(a.unlockedAt!)}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppTheme.success,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
