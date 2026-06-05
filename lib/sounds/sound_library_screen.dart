import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/sounds/sound_player_service.dart';
import 'package:dream_track/sounds/sound_mixer_widget.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';
import 'package:dream_track/shared/constants/app_constants.dart';

class SoundLibraryScreen extends ConsumerStatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  ConsumerState<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends ConsumerState<SoundLibraryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int? _selectedTimerMinutes;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(soundPlayerServiceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(state),
              if (state.isAnyPlaying) ...[
                _buildTimerSection(state),
                if (state.activeTracks.length > 1) const SoundMixerWidget(),
              ],
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: SoundPlayerNotifier.allSounds.length,
                  itemBuilder: (context, i) {
                    final sound = SoundPlayerNotifier.allSounds[i];
                    final isActive = state.activeTracks.any((t) => t.id == sound.id);
                    return _buildSoundCard(sound, isActive, state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SoundPlayerState state) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sonidos Relajantes', style: Theme.of(context).textTheme.headlineMedium),
                Text(
                  state.isAnyPlaying
                    ? '${state.activeTracks.length}/3 sonidos activos'
                    : 'Selecciona hasta 3 sonidos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (state.isAnyPlaying)
            GestureDetector(
              onTap: () => ref.read(soundPlayerServiceProvider.notifier).stopAll(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stop_rounded, color: AppTheme.error, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(SoundPlayerState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            state.timerEndTime != null
              ? 'Apagado en ${state.timerEndTime!.difference(DateTime.now()).inMinutes}min'
              : 'Temporizador',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ...AppConstants.soundTimerOptions.map((min) => GestureDetector(
            onTap: () {
              ref.read(soundPlayerServiceProvider.notifier).startTimer(min);
              setState(() => _selectedTimerMinutes = min);
            },
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedTimerMinutes == min && state.timerEndTime != null
                  ? AppTheme.primary
                  : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${min}m',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: _selectedTimerMinutes == min && state.timerEndTime != null
                    ? Colors.white
                    : AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSoundCard(SoundTrack sound, bool isActive, SoundPlayerState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: isActive ? AppTheme.primaryGradient : AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.cardBorder,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final notifier = ref.read(soundPlayerServiceProvider.notifier);
            if (isActive) {
              await notifier.stopSound(sound.id);
            } else if (state.activeTracks.length < 3) {
              await notifier.playSound(sound);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Máximo 3 sonidos simultáneos'),
                  backgroundColor: AppTheme.warning,
                ),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Text(
                    sound.emoji,
                    style: TextStyle(
                      fontSize: 36 + (_pulseController.value * 4),
                    ),
                  ),
                )
              else
                Text(sound.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                sound.name,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (isActive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.graphic_eq_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'Reproduciendo',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
