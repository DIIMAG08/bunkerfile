import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/sounds/sound_player_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';

class SoundMixerWidget extends ConsumerWidget {
  const SoundMixerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(soundPlayerServiceProvider);
    final notifier = ref.read(soundPlayerServiceProvider.notifier);

    if (state.activeTracks.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Mezclador',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.activeTracks.map((track) => _buildTrackSlider(
            context, track, notifier,
          )),
        ],
      ),
    );
  }

  Widget _buildTrackSlider(
    BuildContext context,
    SoundTrack track,
    SoundPlayerNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(track.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Slider(
                  value: track.volume,
                  onChanged: (v) => notifier.setVolume(track.id, v),
                  min: 0,
                  max: 1,
                  activeColor: AppTheme.primary,
                  inactiveColor: AppTheme.cardBorder,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => notifier.stopSound(track.id),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: AppTheme.error, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
