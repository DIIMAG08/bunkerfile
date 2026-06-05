import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dream_track/ai/ai_service.dart';
import 'package:dream_track/shared/constants/app_constants.dart';

class AiReport {
  final String content;
  final DateTime generatedAt;
  final String weekRange;

  AiReport({
    required this.content,
    required this.generatedAt,
    required this.weekRange,
  });

  Map<String, dynamic> toMap() => {
    'content': content,
    'generatedAt': generatedAt.toIso8601String(),
    'weekRange': weekRange,
  };

  factory AiReport.fromMap(Map<String, dynamic> map) => AiReport(
    content: map['content'] as String,
    generatedAt: DateTime.parse(map['generatedAt'] as String),
    weekRange: map['weekRange'] as String,
  );
}

final aiReportServiceProvider = Provider<AiReportService>((ref) {
  return AiReportService(ref.read(aiServiceProvider));
});

class AiReportService {
  final AiService _aiService;

  AiReportService(this._aiService);

  Box get _box => Hive.box(AppConstants.aiChatBoxName);

  Future<AiReport?> generateWeeklyReport() async {
    final content = await _aiService.generateWeeklyReport();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final report = AiReport(
      content: content,
      generatedAt: now,
      weekRange: '${_fmt(weekStart)} - ${_fmt(weekEnd)}',
    );

    await _saveReport(report);
    return report;
  }

  Future<void> _saveReport(AiReport report) async {
    final reports = _getReportsList();
    reports.insert(0, report.toMap());
    if (reports.length > 12) reports.removeLast(); // Keep last 12 weeks
    await _box.put('weekly_reports', reports);
  }

  List<AiReport> getAllReports() {
    return _getReportsList()
        .map((m) => AiReport.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  AiReport? getLastReport() {
    final reports = getAllReports();
    return reports.isEmpty ? null : reports.first;
  }

  bool shouldGenerateNewReport() {
    final lastReport = getLastReport();
    if (lastReport == null) return true;
    final daysSince = DateTime.now().difference(lastReport.generatedAt).inDays;
    return daysSince >= 7;
  }

  List<dynamic> _getReportsList() {
    return List<dynamic>.from(_box.get('weekly_reports', defaultValue: []));
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}';
}
