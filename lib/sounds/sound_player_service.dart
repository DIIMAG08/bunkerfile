import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundTrack {
  final String id;
  final String name;
  final String emoji;
  final String url;
  double volume;
  bool isPlaying;

  SoundTrack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.url,
    this.volume = 0.5,
    this.isPlaying = false,
  });
}

final soundPlayerServiceProvider =
    StateNotifierProvider<SoundPlayerNotifier, SoundPlayerState>((ref) {
  return SoundPlayerNotifier();
});

class SoundPlayerState {
  final List<SoundTrack> activeTracks;
  final bool isMixerActive;
  final int? timerMinutes;
  final DateTime? timerEndTime;
  final bool isAnyPlaying;

  const SoundPlayerState({
    this.activeTracks = const [],
    this.isMixerActive = false,
    this.timerMinutes,
    this.timerEndTime,
    this.isAnyPlaying = false,
  });

  SoundPlayerState copyWith({
    List<SoundTrack>? activeTracks,
    bool? isMixerActive,
    int? timerMinutes,
    DateTime? timerEndTime,
    bool? isAnyPlaying,
  }) {
    return SoundPlayerState(
      activeTracks: activeTracks ?? this.activeTracks,
      isMixerActive: isMixerActive ?? this.isMixerActive,
      timerMinutes: timerMinutes,
      timerEndTime: timerEndTime,
      isAnyPlaying: isAnyPlaying ?? this.isAnyPlaying,
    );
  }
}

class SoundPlayerNotifier extends StateNotifier<SoundPlayerState> {
  SoundPlayerNotifier() : super(const SoundPlayerState());

  static final List<SoundTrack> allSounds = [
    SoundTrack(
      id: 'rain',
      name: 'Lluvia suave',
      emoji: '🌧️',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ),
    SoundTrack(
      id: 'white_noise',
      name: 'Ruido blanco',
      emoji: '📻',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    SoundTrack(
      id: 'pink_noise',
      name: 'Ruido rosa',
      emoji: '🎵',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
    SoundTrack(
      id: 'ocean',
      name: 'Olas del mar',
      emoji: '🌊',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    ),
    SoundTrack(
      id: 'forest',
      name: 'Bosque nocturno',
      emoji: '🌲',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    ),
    SoundTrack(
      id: 'fire',
      name: 'Fuego de chimenea',
      emoji: '🔥',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    ),
    SoundTrack(
      id: 'fan',
      name: 'Ventilador',
      emoji: '🌀',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    ),
    SoundTrack(
      id: 'heartbeat',
      name: 'Latidos suaves',
      emoji: '💓',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    ),
    SoundTrack(
      id: 'bowls',
      name: 'Cuencos tibetanos',
      emoji: '🔔',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
    ),
    SoundTrack(
      id: 'piano',
      name: 'Piano suave',
      emoji: '🎹',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
    ),
  ];

  final Map<String, AudioPlayer> _players = {};
  Timer? _sleepTimer;
  int _usageCount = 0;

  Future<void> playSound(SoundTrack track) async {
    if (state.activeTracks.length >= 3) return; // Max 3 simultaneous

    final player = AudioPlayer();
    _players[track.id] = player;
    await player.setUrl(track.url);
    await player.setLoopMode(LoopMode.one);
    await player.setVolume(track.volume);
    await player.play();

    track.isPlaying = true;
    final newTracks = [...state.activeTracks, track];
    state = state.copyWith(
      activeTracks: newTracks,
      isMixerActive: newTracks.length > 1,
      isAnyPlaying: true,
    );

    // Track usage for gamification
    _usageCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSoundUsed', track.id);
    await prefs.setInt('soundUsageCount_${track.id}', 
      (prefs.getInt('soundUsageCount_${track.id}') ?? 0) + 1);
  }

  Future<void> stopSound(String trackId) async {
    await _players[trackId]?.stop();
    await _players[trackId]?.dispose();
    _players.remove(trackId);

    final newTracks = state.activeTracks.where((t) => t.id != trackId).toList();
    state = state.copyWith(
      activeTracks: newTracks,
      isMixerActive: newTracks.length > 1,
      isAnyPlaying: newTracks.isNotEmpty,
    );
  }

  Future<void> stopAll() async {
    for (final player in _players.values) {
      await player.stop();
      await player.dispose();
    }
    _players.clear();
    state = state.copyWith(
      activeTracks: [],
      isMixerActive: false,
      isAnyPlaying: false,
      timerMinutes: null,
      timerEndTime: null,
    );
    _sleepTimer?.cancel();
  }

  Future<void> setVolume(String trackId, double volume) async {
    await _players[trackId]?.setVolume(volume);
    final updatedTracks = state.activeTracks.map((t) {
      if (t.id == trackId) t.volume = volume;
      return t;
    }).toList();
    state = state.copyWith(activeTracks: updatedTracks);
  }

  void startTimer(int minutes) {
    _sleepTimer?.cancel();
    final endTime = DateTime.now().add(Duration(minutes: minutes));
    state = state.copyWith(
      timerMinutes: minutes,
      timerEndTime: endTime,
    );
    _sleepTimer = Timer(Duration(minutes: minutes), stopAll);
  }

  void cancelTimer() {
    _sleepTimer?.cancel();
    state = state.copyWith(timerMinutes: null, timerEndTime: null);
  }

  bool isPlaying(String trackId) => _players[trackId]?.playing ?? false;

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}
