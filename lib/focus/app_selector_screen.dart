import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/focus/app_blocker_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';

class AppSelectorScreen extends ConsumerStatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  ConsumerState<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends ConsumerState<AppSelectorScreen> {
  // Common social media / distraction apps
  static const List<Map<String, String>> _commonApps = [
    {'name': 'Instagram', 'package': 'com.instagram.android', 'emoji': '📸'},
    {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'emoji': '🎵'},
    {'name': 'Twitter/X', 'package': 'com.twitter.android', 'emoji': '🐦'},
    {'name': 'Facebook', 'package': 'com.facebook.katana', 'emoji': '👥'},
    {'name': 'YouTube', 'package': 'com.google.android.youtube', 'emoji': '▶️'},
    {'name': 'Netflix', 'package': 'com.netflix.mediaclient', 'emoji': '🎬'},
    {'name': 'WhatsApp', 'package': 'com.whatsapp', 'emoji': '💬'},
    {'name': 'Telegram', 'package': 'org.telegram.messenger', 'emoji': '✈️'},
    {'name': 'Reddit', 'package': 'com.reddit.frontpage', 'emoji': '📱'},
    {'name': 'Spotify', 'package': 'com.spotify.music', 'emoji': '🎶'},
    {'name': 'Twitch', 'package': 'tv.twitch.android.app', 'emoji': '🎮'},
    {'name': 'Discord', 'package': 'com.discord', 'emoji': '🎧'},
    {'name': 'Snapchat', 'package': 'com.snapchat.android', 'emoji': '👻'},
    {'name': 'LinkedIn', 'package': 'com.linkedin.android', 'emoji': '💼'},
    {'name': 'Amazon', 'package': 'com.amazon.mShop.android.shopping', 'emoji': '🛒'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appBlockerServiceProvider);
    final notifier = ref.read(appBlockerServiceProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildInfo(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Apps populares de distracción',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._commonApps.map((app) {
                      final isBlocked = state.blockedApps.contains(app['package']!);
                      return _buildAppTile(app, isBlocked, notifier);
                    }),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Teléfono y mensajes de emergencia siempre permitidos',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              Text('Bloqueo de Apps', style: Theme.of(context).textTheme.headlineMedium),
              Text('Durante el modo sueño', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '💡 Las apps seleccionadas serán bloqueadas automáticamente cuando actives el modo sueño.',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          color: AppTheme.secondary,
        ),
      ),
    );
  }

  Widget _buildAppTile(
    Map<String, String> app,
    bool isBlocked,
    AppBlockerNotifier notifier,
  ) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(app['emoji']!, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app['name']!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Switch(
            value: isBlocked,
            onChanged: (v) async {
              if (v) {
                await notifier.addBlockedApp(app['package']!);
              } else {
                await notifier.removeBlockedApp(app['package']!);
              }
            },
          ),
        ],
      ),
    );
  }
}
