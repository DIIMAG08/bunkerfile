import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dream_track/shared/constants/app_constants.dart';

class SleepBackgroundService {
  static const String _channelId = 'dreamtrack_sleep_channel';
  static const String _channelName = 'DreamTrack Monitoreo de Sueño';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'DreamTrack está monitoreando tu sueño',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'DreamTrack',
        initialNotificationContent: 'Monitoreando tu sueño...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.microphone],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onServiceStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Monitor accelerometer in background
  final List<double> movements = [];
  DateTime? lastMovementTime;
  bool isSleeping = false;

  accelerometerEventStream(
    samplingPeriod: const Duration(seconds: 2),
  ).listen((event) {
    final magnitude = ((event.x * event.x + event.y * event.y + event.z * event.z) - 9.81).abs();
    movements.add(magnitude);
    if (movements.length > 30) movements.removeAt(0);

    if (magnitude > AppConstants.movementThreshold) {
      lastMovementTime = DateTime.now();
    }

    final avgMovement = movements.isEmpty
        ? 0.0
        : movements.reduce((a, b) => a + b) / movements.length;

    final minutesSinceMove = lastMovementTime != null
        ? DateTime.now().difference(lastMovementTime!).inMinutes
        : 0;

    if (!isSleeping && minutesSinceMove >= AppConstants.noMovementMinutes) {
      isSleeping = true;
      service.invoke('sleepDetected', {
        'sleepStartTime': (lastMovementTime ?? DateTime.now()).toIso8601String(),
      });
    }

    if (isSleeping && avgMovement > AppConstants.lightSleepThreshold * 3) {
      isSleeping = false;
      service.invoke('wakeDetected', {
        'wakeTime': DateTime.now().toIso8601String(),
      });
    }

    // Send state updates
    service.invoke('updateState', {
      'isSleeping': isSleeping,
      'movementLevel': avgMovement,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (service is AndroidServiceInstance) {
      if (isSleeping) {
        service.setForegroundNotificationInfo(
          title: 'DreamTrack 🌙',
          content: 'Monitoreando tu sueño...',
        );
      }
    }
  });
}
