import 'package:dream_track/sleep/sleep_tracker_service.dart';
import 'package:dream_track/shared/utils/date_utils.dart';

class SleepContextBuilder {
  final SleepTrackerService _tracker;

  SleepContextBuilder(this._tracker);

  Future<String> buildContext() async {
    final records = _tracker.getLast30Days();
    if (records.isEmpty) {
      return 'Sin registros de sueño disponibles aún. El usuario acaba de comenzar.';
    }

    final avgHours = _tracker.getAverageHoursSlept(records);
    final avgQuality = _tracker.getAverageQuality(records);
    final totalRecords = records.length;
    final wakeUpsAvg = records.isNotEmpty
        ? records.map((r) => r.wakeUps).reduce((a, b) => a + b) / records.length
        : 0;
    final nightmaresCount = records.where((r) => r.hadNightmares).length;
    final soundsUsed = records.where((r) => r.usedSounds).length;
    final dndUsed = records.where((r) => r.dndActive).length;

    final buffer = StringBuffer();
    buffer.writeln('=== CONTEXTO DE SUEÑO (últimos 30 días) ===');
    buffer.writeln('Registros totales: $totalRecords días');
    buffer.writeln('Promedio de horas dormidas: ${avgHours.toStringAsFixed(1)}h');
    buffer.writeln('Calidad promedio: ${avgQuality.toStringAsFixed(1)}/5');
    buffer.writeln('Despertares promedio por noche: ${wakeUpsAvg.toStringAsFixed(1)}');
    buffer.writeln('Noches con pesadillas: $nightmaresCount');
    buffer.writeln('Noches usando sonidos: $soundsUsed');
    buffer.writeln('Noches con modo no molestar: $dndUsed');
    buffer.writeln();
    buffer.writeln('=== ÚLTIMAS 7 NOCHES ===');

    final last7 = records.take(7).toList();
    for (final record in last7) {
      buffer.writeln('${AppDateUtils.formatDate(record.bedTime)}: '
          '${record.hoursSlept.toStringAsFixed(1)}h, '
          'calidad ${record.quality}/5, '
          '${record.wakeUps} despertares'
          '${record.hadNightmares ? ", pesadillas" : ""}'
          '${record.notes != null ? ", notas: ${record.notes}" : ""}');
    }

    final notes = records
        .where((r) => r.notes != null && r.notes!.isNotEmpty)
        .take(5)
        .map((r) => r.notes!)
        .join('; ');
    if (notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== NOTAS RECIENTES ===');
      buffer.writeln(notes);
    }

    return buffer.toString();
  }
}
