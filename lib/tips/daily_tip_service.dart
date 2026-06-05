import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_track/tips/tips_data.dart';

final dailyTipServiceProvider = Provider<DailyTipService>((ref) {
  return DailyTipService();
});

final dailyTipProvider = FutureProvider<Map<String, String>>((ref) async {
  return ref.read(dailyTipServiceProvider).getDailyTip();
});

class DailyTipService {
  Future<Map<String, String>> getDailyTip() async {
    final dayOfYear = _dayOfYear(DateTime.now());
    final index = dayOfYear % sleepTips.length;
    return Map<String, String>.from(sleepTips[index]);
  }

  Future<void> markTipAsRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final readTips = prefs.getStringList('readTips') ?? [];
    if (!readTips.contains('$index')) {
      readTips.add('$index');
      await prefs.setStringList('readTips', readTips);
    }
  }

  Future<int> getReadTipsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('readTips') ?? []).length;
  }

  Future<List<Map<String, String>>> getTipsByCategory(String category) async {
    return sleepTips
        .where((t) => t['category'] == category)
        .map((t) => Map<String, String>.from(t))
        .toList();
  }

  List<String> get categories {
    return sleepTips.map((t) => t['category']!).toSet().toList();
  }

  // Habit program methods
  Future<Set<int>> getCompletedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('completedHabitDays') ?? [];
    return completed.map(int.parse).toSet();
  }

  Future<void> markDayCompleted(int day) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('completedHabitDays') ?? [];
    if (!completed.contains('$day')) {
      completed.add('$day');
      await prefs.setStringList('completedHabitDays', completed);
    }
  }

  Future<void> unmarkDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('completedHabitDays') ?? [];
    completed.remove('$day');
    await prefs.setStringList('completedHabitDays', completed);
  }

  Future<double> getHabitCompletionRate() async {
    final completed = await getCompletedDays();
    return completed.length / habitProgram.length;
  }

  int _dayOfYear(DateTime dt) {
    return dt.difference(DateTime(dt.year, 1, 1)).inDays;
  }
}
