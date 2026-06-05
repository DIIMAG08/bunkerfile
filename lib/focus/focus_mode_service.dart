import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:shared_preferences/shared_preferences.dart';

final focusModeServiceProvider = StateNotifierProvider<FocusModeNotifier, FocusModeState>((ref) {
  return FocusModeNotifier();
});

class FocusModeState {
  final bool isActive;
  final bool dndEnabled;
  final bool screensBlocked;

  const FocusModeState({
    this.isActive = false,
    this.dndEnabled = false,
    this.screensBlocked = false,
  });

  FocusModeState copyWith({bool? isActive, bool? dndEnabled, bool? screensBlocked}) {
    return FocusModeState(
      isActive: isActive ?? this.isActive,
      dndEnabled: dndEnabled ?? this.dndEnabled,
      screensBlocked: screensBlocked ?? this.screensBlocked,
    );
  }
}

class FocusModeNotifier extends StateNotifier<FocusModeState> {
  final _dndPlugin = DoNotDisturbPlugin();

  FocusModeNotifier() : super(const FocusModeState());

  Future<void> activateSleepMode() async {
    try {
      // Activate Do Not Disturb
      final hasPerm = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasPerm == true) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.alarms);
        state = state.copyWith(isActive: true, dndEnabled: true);
      } else {
        // Request DND permission
        await _dndPlugin.openNotificationPolicyAccessSettings();
        state = state.copyWith(isActive: true, dndEnabled: false);
      }
    } catch (e) {
      // DND not available on this device
      state = state.copyWith(isActive: true, dndEnabled: false);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sleepModeActive', true);
    await prefs.setString('sleepModeStart', DateTime.now().toIso8601String());
  }

  Future<void> deactivateSleepMode() async {
    try {
      final hasPerm = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasPerm == true) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      }
    } catch (_) {}

    state = state.copyWith(isActive: false, dndEnabled: false, screensBlocked: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sleepModeActive', false);
  }

  Future<bool> get isActive async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sleepModeActive') ?? false;
  }

  Future<void> checkDndPermission() async {
    try {
      final hasPermission = await _dndPlugin.isNotificationPolicyAccessGranted();
      state = state.copyWith(dndEnabled: hasPermission ?? false);
    } catch (_) {
      state = state.copyWith(dndEnabled: false);
    }
  }
}
