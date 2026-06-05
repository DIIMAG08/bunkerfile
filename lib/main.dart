import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dream_track/app.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';
import 'package:dream_track/gamification/achievement_model.dart';
import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:intl/date_symbol_data_local.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Register Hive adapters
  Hive.registerAdapter(SleepRecordAdapter());
  Hive.registerAdapter(AchievementAdapter());

  // Open Hive boxes
  await Hive.openBox<SleepRecord>(AppConstants.sleepBoxName);
  await Hive.openBox(AppConstants.settingsBoxName);
  await Hive.openBox(AppConstants.gamificationBoxName);
  await Hive.openBox<Achievement>(AppConstants.achievementsBoxName);
  await Hive.openBox(AppConstants.tipsBoxName);
  await Hive.openBox(AppConstants.aiChatBoxName);

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: _onNotificationTap,
  );

  runApp(const ProviderScope(child: DreamTrackApp()));
}

void _onNotificationTap(NotificationResponse response) {
  // Handle notification tap
}
