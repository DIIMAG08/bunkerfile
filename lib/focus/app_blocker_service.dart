import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appBlockerServiceProvider = StateNotifierProvider<AppBlockerNotifier, AppBlockerState>((ref) {
  return AppBlockerNotifier();
});

class AppBlockerState {
  final List<String> blockedApps;
  final bool isMonitoring;

  const AppBlockerState({
    this.blockedApps = const [],
    this.isMonitoring = false,
  });

  AppBlockerState copyWith({List<String>? blockedApps, bool? isMonitoring}) {
    return AppBlockerState(
      blockedApps: blockedApps ?? this.blockedApps,
      isMonitoring: isMonitoring ?? this.isMonitoring,
    );
  }
}

class AppBlockerNotifier extends StateNotifier<AppBlockerState> {
  AppBlockerNotifier() : super(const AppBlockerState()) {
    _loadBlockedApps();
  }

  static const List<String> _allowedApps = [
    'com.android.phone',
    'com.samsung.android.messaging',
    'com.google.android.apps.messaging',
    'com.android.dialer',
  ];

  Future<void> _loadBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final blocked = prefs.getStringList('blockedApps') ?? [];
    state = state.copyWith(blockedApps: blocked);
  }

  Future<void> setBlockedApps(List<String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blockedApps', apps);
    state = state.copyWith(blockedApps: apps);
  }

  Future<void> addBlockedApp(String packageName) async {
    if (!_allowedApps.contains(packageName)) {
      final newList = [...state.blockedApps, packageName];
      await setBlockedApps(newList);
    }
  }

  Future<void> removeBlockedApp(String packageName) async {
    final newList = state.blockedApps.where((a) => a != packageName).toList();
    await setBlockedApps(newList);
  }

  bool isBlocked(String packageName) {
    if (_allowedApps.contains(packageName)) return false;
    return state.blockedApps.contains(packageName);
  }

  bool isAllowed(String packageName) => _allowedApps.contains(packageName);
}
