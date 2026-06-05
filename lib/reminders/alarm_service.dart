import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dream_track/sleep/sleep_detection_service.dart';
import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/main.dart';

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService(ref);
});

class AlarmService {
  final Ref _ref;
  Timer? _windowTimer;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  bool _alarmFired = false;
  DateTime? _windowStart;

  AlarmService(this._ref);

  /// Schedule smart alarm with 30-min window before max wake time
  Future<void> scheduleSmartAlarm({
    required int maxWakeHour,
    required int maxWakeMinute,
    bool smartMode = true,
  }) async {
    await cancelAlarm();
    _alarmFired = false;

    const androidDetails = AndroidNotificationDetails(
      'dreamtrack_alarm',
      'Alarma DreamTrack',
      channelDescription: 'Alarma inteligente de despertar',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    if (smartMode) {
      // Start monitoring 30 min before max wake time
      final windowMinutes = maxWakeHour * 60 + maxWakeMinute - 30;
      final windowHour = windowMinutes ~/ 60;
      final windowMin = windowMinutes % 60;

      // Schedule window start notification (silent) - starts monitoring
      await _scheduleWindowStart(windowHour, windowMin < 0 ? 0 : windowMin);

      // Schedule fallback alarm at max wake time
      await _scheduleAlarm(
        maxWakeHour,
        maxWakeMinute,
        'DreamTrack ⏰',
        '¡Buenos días! Es hora de despertar.',
        androidDetails,
      );
    } else {
      // Simple alarm at exact time
      await _scheduleAlarm(
        maxWakeHour,
        maxWakeMinute,
        'DreamTrack ⏰',
        '¡Buenos días! Es hora de despertar.',
        androidDetails,
      );
    }
  }

  Future<void> _scheduleWindowStart(int hour, int minute) async {
    // In production: use WorkManager or exact alarm to start monitoring window
    // For now, schedule a check that will be triggered by the alarm system
  }

  Future<void> _scheduleAlarm(
    int hour,
    int minute,
    String title,
    String body,
    AndroidNotificationDetails androidDetails,
  ) async {
    await flutterLocalNotificationsPlugin.show(
      AppConstants.alarmId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Start monitoring for light sleep during alarm window
  void startAlarmWindow(DateTime maxWakeTime) {
    _windowStart = DateTime.now();
    _alarmFired = false;

    _accelSubscription?.cancel();
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(seconds: 5),
    ).listen((event) {
      if (_alarmFired) return;

      final detection = _ref.read(sleepDetectionProvider);
      final now = DateTime.now();

      // If in light sleep phase, trigger gentle alarm
      if (detection.currentPhase == SleepPhase.lightSleep &&
          now.difference(_windowStart!).inMinutes >= 5) {
        _triggerGentleAlarm();
      }

      // Force alarm at max wake time
      if (now.isAfter(maxWakeTime)) {
        _triggerAlarm();
      }
    });

    // Force alarm at max wake time
    _windowTimer = Timer(
      maxWakeTime.difference(DateTime.now()),
      _triggerAlarm,
    );
  }

  void _triggerGentleAlarm() {
    if (_alarmFired) return;
    _alarmFired = true;
    _fireAlarm('¡Buenos días! 🌅 Detectamos que estás en sueño ligero.', true);
  }

  void _triggerAlarm() {
    if (_alarmFired) return;
    _alarmFired = true;
    _fireAlarm('⏰ ¡Es hora de despertar! Tu día te espera.', false);
  }

  void _fireAlarm(String message, bool gentle) async {
    final androidDetails = AndroidNotificationDetails(
      'dreamtrack_alarm',
      'Alarma DreamTrack',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    await flutterLocalNotificationsPlugin.show(
      AppConstants.alarmId,
      gentle ? 'DreamTrack 🌅' : 'DreamTrack ⏰',
      message,
      NotificationDetails(android: androidDetails),
    );

    _accelSubscription?.cancel();
    _windowTimer?.cancel();
  }

  Future<void> cancelAlarm() async {
    await flutterLocalNotificationsPlugin.cancel(AppConstants.alarmId);
    _accelSubscription?.cancel();
    _windowTimer?.cancel();
    _alarmFired = false;
  }

  void dispose() {
    _accelSubscription?.cancel();
    _windowTimer?.cancel();
  }
}
