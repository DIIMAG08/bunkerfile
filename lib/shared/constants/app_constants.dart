class AppConstants {
  // Hive box names
  static const String sleepBoxName = 'sleep_records';
  static const String settingsBoxName = 'settings';
  static const String gamificationBoxName = 'gamification';
  static const String achievementsBoxName = 'achievements';
  static const String tipsBoxName = 'tips';
  static const String aiChatBoxName = 'ai_chat';

  // Default sleep settings
  static const int defaultSleepGoalHours = 8;
  static const String defaultBedtimeHour = '22:30';
  static const String defaultWakeTimeHour = '06:30';

  // Sleep detection thresholds
  static const int noMovementMinutes = 15;
  static const double movementThreshold = 0.5;
  static const double deepSleepThreshold = 0.1;
  static const double lightSleepThreshold = 1.0;

  // Notification IDs
  static const int sleepReminderEarlyId = 1001;
  static const int sleepReminderMidId = 1002;
  static const int sleepReminderFinalId = 1003;
  static const int alarmId = 2001;
  static const int weeklyScoreId = 3001;
  static const int achievementId = 4001;
  static const int streakReminderId = 5001;
  static const int habitReminderId = 6001;

  // Sound timer options (minutes)
  static const List<int> soundTimerOptions = [15, 30, 45, 60];

  // Score thresholds
  static const int scoreExcellent = 91;
  static const int scoreVeryGood = 76;
  static const int scoreGood = 61;
  static const int scoreFair = 41;

  // Streak milestones
  static const List<int> streakMilestones = [7, 14, 21, 30, 60, 90, 180, 365];

  // App version
  static const String appVersion = '1.0.0';
  static const String appName = 'DreamTrack';

  // Level thresholds (XP)
  static const List<int> levelThresholds = [
    0, 200, 500, 1000, 2000, 3500, 5500, 8000, 12000, 18000
  ];
  static const List<String> levelNames = [
    'Dormilón',
    'Aprendiz del Descanso',
    'Soñador Consciente',
    'Guardián del Sueño',
    'Maestro Nocturno',
    'Sabio del Descanso',
    'Arquitecto de Sueños',
    'Leyenda del Sueño',
    'Inmortal del Descanso',
    'Maestro Supremo',
  ];
}
