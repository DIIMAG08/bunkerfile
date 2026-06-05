import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'sleep_record_model.g.dart';

@HiveType(typeId: 0)
class SleepRecord extends HiveObject {
  @HiveField(0)
  late DateTime bedTime;

  @HiveField(1)
  late DateTime wakeTime;

  @HiveField(2)
  late double hoursSlept;

  @HiveField(3)
  late int quality; // 1-5

  @HiveField(4)
  String? notes;

  @HiveField(5)
  late bool hadNightmares;

  @HiveField(6)
  late bool hadDreams;

  @HiveField(7)
  late int wakeUps;

  @HiveField(8)
  late bool autoDetected;

  @HiveField(9)
  late DateTime recordedAt;

  @HiveField(10)
  List<double>? accelerometerData; // Raw accel readings

  @HiveField(11)
  double? avgSoundLevel;

  @HiveField(12)
  late bool usedSounds;

  @HiveField(13)
  String? soundUsed;

  @HiveField(14)
  late bool dndActive;

  SleepRecord({
    required this.bedTime,
    required this.wakeTime,
    required this.hoursSlept,
    required this.quality,
    this.notes,
    this.hadNightmares = false,
    this.hadDreams = false,
    this.wakeUps = 0,
    this.autoDetected = false,
    DateTime? recordedAt,
    this.accelerometerData,
    this.avgSoundLevel,
    this.usedSounds = false,
    this.soundUsed,
    this.dndActive = false,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Color get qualityColor {
    switch (quality) {
      case 5:
        return const Color(0xFF4ECDC4);
      case 4:
        return const Color(0xFF74B9FF);
      case 3:
        return const Color(0xFFFFBE76);
      case 2:
        return const Color(0xFFF0A500);
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  String get qualityLabel {
    switch (quality) {
      case 5:
        return 'Excelente';
      case 4:
        return 'Bueno';
      case 3:
        return 'Regular';
      case 2:
        return 'Malo';
      default:
        return 'Muy malo';
    }
  }

  bool get metGoal {
    // Default 8h goal, overridden by settings
    return hoursSlept >= 7.0;
  }
}
