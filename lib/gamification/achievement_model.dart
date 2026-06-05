import 'package:hive/hive.dart';

part 'achievement_model.g.dart';

@HiveType(typeId: 1)
class Achievement extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late bool isUnlocked;

  @HiveField(5)
  DateTime? unlockedAt;

  @HiveField(6)
  late int progress;

  @HiveField(7)
  late int goal;

  @HiveField(8)
  late String iconName;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.goal = 1,
    required this.iconName,
  });

  /// Whether this achievement tracks progress (goal > 1).
  bool get isProgressBased => goal > 1;

  /// Progress ratio clamped to 0.0–1.0.
  double get progressRatio => goal <= 0 ? 0.0 : (progress / goal).clamp(0.0, 1.0);

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    int? goal,
    String? iconName,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      goal: goal ?? this.goal,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  String toString() =>
      'Achievement(id: $id, name: $name, isUnlocked: $isUnlocked, progress: $progress/$goal)';
}
