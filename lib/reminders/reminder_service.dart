import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_track/shared/constants/app_constants.dart';
import 'package:dream_track/main.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

class ReminderService {
  static const List<String> _reminderMessages = [
    '🌙 Es hora de prepararte para dormir. Tu cuerpo te lo agradecerá.',
    '✨ Un buen descanso comienza con una buena rutina. ¡Empieza ya!',
    '🌟 Los mejores días comienzan con las mejores noches. ¡Hora de dormir!',
    '💤 Tu cerebro necesita descansar para brillar mañana.',
    '🌙 La magia del sueño está a punto de comenzar. ¡Prepárate!',
    '🌌 El universo del descanso te espera. Cierra los ojos.',
    '🦉 Como el búho sabio, sabe cuándo es hora de descansar.',
    '💫 Cada hora de sueño es una inversión en tu bienestar.',
    '🌙 Tus sueños te esperan. Es hora de encontrarlos.',
    '🌸 La mejor versión de ti descansa esta noche.',
    '⭐ Regálate el descanso que mereces. ¡Es hora!',
    '🌙 Tu mente necesita silencio. Dale lo que pide.',
    '🌊 Déjate llevar por las olas del sueño reparador.',
    '✨ Mañana será increíble si descansas bien hoy.',
    '💤 Tu cuerpo tiene memoria. Acuéstate a la misma hora.',
    '🌙 El descanso no es un lujo, es una necesidad. ¡A dormir!',
    '🌟 Los grandes logros nacen en noches de buen sueño.',
    '🎯 Meta de hoy: dormir bien. Lo tienes todo para lograrlo.',
    '🌙 La noche es tu aliada. Úsala para recargar energías.',
    '💫 Tu racha de buen sueño continúa esta noche. ¡No la rompas!',
  ];

  static const List<String> _urgentMessages = [
    '🔔 ¡10 minutos! Ponte cómodo y apaga las pantallas.',
    '⏰ Ya casi es hora. Prepara tu espacio de descanso.',
    '🌙 En 10 minutos, tu cuerpo debe estar listo para dormir.',
    '💤 Última llamada para prepararte. ¡Apaga el teléfono!',
    '🌟 El momento de tu descanso está llegando.',
  ];

  static const List<String> _finalMessages = [
    '🌙 ¡Es la hora! Activa el modo sueño y descansa.',
    '💤 Tu hora de dormir ha llegado. DreamTrack te cuida.',
    '✨ ¡Buenas noches! Que tus sueños sean increíbles.',
    '🌌 El descanso comienza ahora. Cierra los ojos.',
    '⭐ Hora oficial de dormir. ¡Tu racha te espera!',
  ];

  int _messageIndex = 0;
  int _urgentIndex = 0;
  int _finalIndex = 0;

  Future<void> scheduleReminders({
    required int bedHour,
    required int bedMinute,
  }) async {
    await cancelAllReminders();

    // 30 minutes before
    final early30 = _adjustTime(bedHour, bedMinute, -30);
    await _scheduleNotification(
      id: AppConstants.sleepReminderEarlyId,
      title: 'DreamTrack 🌙',
      body: _nextMessage(),
      hour: early30[0],
      minute: early30[1],
    );

    // 10 minutes before
    final early10 = _adjustTime(bedHour, bedMinute, -10);
    await _scheduleNotification(
      id: AppConstants.sleepReminderMidId,
      title: 'DreamTrack ⏰',
      body: _nextUrgentMessage(),
      hour: early10[0],
      minute: early10[1],
    );

    // At bedtime
    await _scheduleNotification(
      id: AppConstants.sleepReminderFinalId,
      title: 'DreamTrack 💤',
      body: _nextFinalMessage(),
      hour: bedHour,
      minute: bedMinute,
    );

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bedHour', bedHour);
    await prefs.setInt('bedMinute', bedMinute);
    await prefs.setBool('remindersEnabled', true);
  }

  Future<void> scheduleStreakReminder() async {
    await _scheduleNotification(
      id: AppConstants.streakReminderId,
      title: 'DreamTrack 🔥',
      body: '¡No olvides mantener tu racha activa esta noche! Tu récord te espera.',
      hour: 20,
      minute: 0,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dreamtrack_reminders',
      'Recordatorios DreamTrack',
      channelDescription: 'Recordatorios de hora de dormir',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.periodicallyShowWithDuration(
      id,
      title,
      body,
      const Duration(days: 1),
      notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancel(AppConstants.sleepReminderEarlyId);
    await flutterLocalNotificationsPlugin.cancel(AppConstants.sleepReminderMidId);
    await flutterLocalNotificationsPlugin.cancel(AppConstants.sleepReminderFinalId);
  }

  Future<void> snoozeReminder(int minutes) async {
    await Future.delayed(Duration(minutes: minutes));
    await flutterLocalNotificationsPlugin.show(
      AppConstants.sleepReminderFinalId + 1,
      'DreamTrack 🌙',
      'Hora de dormir (pospuesto)',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dreamtrack_reminders',
          'Recordatorios DreamTrack',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  List<int> _adjustTime(int hour, int minute, int offsetMinutes) {
    int totalMinutes = hour * 60 + minute + offsetMinutes;
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    if (totalMinutes >= 24 * 60) totalMinutes -= 24 * 60;
    return [totalMinutes ~/ 60, totalMinutes % 60];
  }

  String _nextMessage() {
    final msg = _reminderMessages[_messageIndex % _reminderMessages.length];
    _messageIndex++;
    return msg;
  }

  String _nextUrgentMessage() {
    final msg = _urgentMessages[_urgentIndex % _urgentMessages.length];
    _urgentIndex++;
    return msg;
  }

  String _nextFinalMessage() {
    final msg = _finalMessages[_finalIndex % _finalMessages.length];
    _finalIndex++;
    return msg;
  }
}
