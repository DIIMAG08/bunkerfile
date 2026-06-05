import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/sleep/sleep_tracker_service.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';
import 'package:dream_track/shared/utils/date_utils.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref.read(sleepTrackerServiceProvider));
});

class AiService {
  final SleepTrackerService _tracker;

  AiService(this._tracker);

  // Offline is always true, no API keys needed!
  Future<bool> hasApiKey() async => true;
  Future<void> saveApiKey(String apiKey) async {}
  void resetSession() {}

  // --- Offline Expert sleep Q&A database ---
  static const Map<String, List<String>> _keywordDatabase = {
    'insomnio': [
      'dormir rápido', 'conciliar', 'insomnio', 'no puedo dormir', 'dar vueltas'
    ],
    'cansado': [
      'cansado', 'cansada', 'fatiga', 'fatigado', 'despertar cansado', 'sueño ligero'
    ],
    'despertar': [
      'despertar', 'despertarme', 'despertares', 'interrupciones', 'despierto'
    ],
    'sonidos': [
      'música', 'sonidos', 'ruido blanco', 'lluvia', 'audios', 'relajación'
    ],
    'profundo': [
      'sueño profundo', 'profundo', 'rem', 'fases', 'etapas'
    ],
    'gamificacion': [
      'racha', 'nivel', 'logros', 'experiencia', 'puntos', 'xp'
    ],
  };

  static const Map<String, String> _responses = {
    'insomnio': 'Para combatir el insomnio y conciliar el sueño más rápido, te recomiendo aplicar la **técnica de respiración 4-7-8** (inhala durante 4s, retén el aire 7s y exhala despacio en 8s). Además, asegúrate de apagar cualquier pantalla de celular o TV al menos 30 minutos antes de acostarte. La luz azul bloquea la hormona natural del sueño (melatonina). Mantener la habitación fresca, entre 18 y 20°C, también le indica a tu cuerpo que es momento de descansar.',
    'cansado': 'Si duermes tus 8 horas pero sigues con cansancio, la causa suele ser la fragmentación del sueño o la falta de **sueño profundo (Fase Delta)**. Intenta evitar la cafeína después de las 2:00 PM y el alcohol por las noches; aunque este último da somnolencia, sabotea por completo tus ciclos de sueño REM. La consistencia en tu hora de despertar es el pilar más importante para programar tu ritmo circadiano.',
    'despertar': 'Despertarse brevemente 2 o 3 veces por noche es un comportamiento biológico normal a medida que transicionamos de un ciclo de sueño a otro. Sin embargo, si te cuesta volver a dormirte, evita mirar la hora en el teléfono (esto genera ansiedad cerebral). Si pasas más de 20 minutos despierto en la cama, levántate y realiza una lectura ligera a media luz hasta que el sueño regrese naturalmente.',
    'sonidos': 'Los sonidos relajantes son excelentes para enmascarar los ruidos ambientales molestos y calmar el sistema nervioso autónomo. En DreamTrack, te sugerimos utilizar nuestra mezcla interactiva de **Lluvia suave y Ruido Blanco** a volumen bajo. Los ruidos continuos o el ruido rosa ayudan a sincronizar las ondas cerebrales lentas para estabilizar la profundidad de tu descanso.',
    'profundo': 'El sueño profundo es la fase más importante para la recuperación física y celular. Para incrementarlo de forma natural: 1. Realiza actividad física regular durante el día (evítala 3 horas antes de dormir). 2. Toma una ducha tibia una hora antes de ir a la cama (ayuda a descender la temperatura interna). 3. Duerme en completa oscuridad. ¡Cada detalle le enseña a tu cerebro a entrar en ciclos delta óptimos!',
    'gamificacion': '¡El sistema de racha y experiencia de DreamTrack está diseñado para premiar tu constancia! Registrar tu descanso diariamente mantiene tu **fuego de racha** encendido, lo que te otorga bonificaciones especiales de XP para subir de nivel y desbloquear más de 25 logros interactivos. Si un día no logras dormir a tiempo, recuerda usar tus **Escudos protectores** para proteger tu progreso.',
  };

  /// Main Q&A matching logic with procedural spin/fallback
  Future<String> sendMessage(String message) async {
    // Artificial slight delay for typing feedback realism
    await Future.delayed(const Duration(milliseconds: 600));

    final query = message.toLowerCase().trim();
    if (query.isEmpty) return 'Por favor, dime tu pregunta sobre el sueño y con gusto te ayudaré.';

    String? matchedCategory;
    for (var entry in _keywordDatabase.entries) {
      for (var keyword in entry.value) {
        if (query.contains(keyword)) {
          matchedCategory = entry.key;
          break;
        }
      }
      if (matchedCategory != null) break;
    }

    if (matchedCategory != null) {
      return _responses[matchedCategory]!;
    }

    // Procedural Fallback (spinning the question)
    return 'Entiendo tu inquietud sobre tu consulta. Como tu asesor de sueño, te sugiero canalizar tu rutina hacia hábitos saludables. Aunque no tengo una respuesta exacta para esa frase particular, puedo ayudarte a combatir el insomnio, entender por qué te despiertas de noche, o sugerirte la mejor música relajante.\n\nComo recomendación general: mantener horarios de acostarte consistentes y crear una transición de relajación antes de la cama son las llaves maestras para mejorar cualquier aspecto de tu descanso. ¡Pregúntame sobre alguno de estos temas!';
  }

  /// Procedural local offline weekly report based on actual sleep history
  Future<String> generateWeeklyReport() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final records = _tracker.getAllRecords();

    if (records.isEmpty) {
      return '### Tu reporte de sueño semanal\n\nNo he encontrado registros de sueño guardados en la base de datos de esta semana.\n\n* **Recomendación**: Comienza registrando tu sueño presionando el botón **Dormir Ahora** en tu panel principal. ¡Tu constancia encenderá tu racha!';
    }

    final avgHours = _tracker.getAverageHoursSlept(records.take(7).toList());
    final avgQuality = _tracker.getAverageQuality(records.take(7).toList());
    final metGoalsCount = records.take(7).where((r) => r.hoursSlept >= 7.0).length;

    String highlight;
    String improvement;
    if (avgHours >= 7.0) {
      highlight = '¡Excelente duración! Has promediado ${avgHours.toStringAsFixed(1)} horas de sueño por noche, cumpliendo con la meta básica recomendada para la recuperación del cuerpo.';
      improvement = 'Para maximizar los beneficios, concéntrate ahora en mejorar la regularidad de tu horario de acostarte, intentando que no varíe más de 30 minutos entre días.';
    } else {
      highlight = 'Buen intento. Has mantenido ${metGoalsCount} noches cumpliendo con tu meta de descanso esta semana.';
      improvement = 'Tu promedio de sueño es de ${avgHours.toStringAsFixed(1)} horas, lo que genera una leve deuda de sueño. Prioriza acostarte 20 minutos antes cada noche para recuperar tu energía celular.';
    }

    return '''
### 📊 Reporte Semanal DreamTrack (Offline)

* **¿Qué salió bien esta semana?**
  $highlight Tu calidad de descanso promedio fue de ${avgQuality.toStringAsFixed(1)}/5 estrellas.

* **¿Qué necesita mejorar?**
  $improvement Evitar distracciones de pantallas antes del descanso optimizará tu producción de melatonina.

* **Recomendaciones específicas:**
  1. Mantén la regularidad en tu hora de despertar, incluso los fines de semana.
  2. Activa el **Modo Sueño** usando el botón del Inicio para blindar tus horas de descanso.
  3. Practica 3 minutos de respiración profunda antes de acostarte.
''';
  }

  /// Procedural local offline sound recommendation based on historical quality
  Future<String> getSoundRecommendation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final records = _tracker.getAllRecords();
    
    if (records.isEmpty) {
      return 'Como aún no tienes un historial registrado de sueño, te recomiendo iniciar tu noche con una mezcla de **Lluvia suave y Ruido Blanco** a volumen moderado para calmar la mente.';
    }

    final soundRecords = records.where((r) => r.usedSounds && r.soundUsed != null).toList();
    if (soundRecords.isEmpty) {
      return 'Te recomiendo probar nuestro sonido de **Lluvia suave** mezclado con **Ruido Rosa** para tu descanso de hoy. Esta combinación estabiliza el sueño profundo.';
    }

    final bestRecord = soundRecords.reduce((a, b) => a.quality > b.quality ? a : b);
    return 'Analizando tus datos, lograste tu mejor calidad de sueño (${bestRecord.qualityLabel}) usando el sonido **${bestRecord.soundUsed}**. Te sugiero mantener esta pista esta noche a volumen bajo para propiciar un descanso reparador.';
  }
}
