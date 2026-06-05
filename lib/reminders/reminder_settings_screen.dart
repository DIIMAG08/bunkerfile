import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_track/reminders/reminder_service.dart';
import 'package:dream_track/reminders/alarm_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  bool _remindersEnabled = true;
  bool _smartAlarmEnabled = true;
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('remindersEnabled') ?? true;
      _smartAlarmEnabled = prefs.getBool('smartAlarmEnabled') ?? true;
      _bedtime = TimeOfDay(
        hour: prefs.getInt('bedHour') ?? 22,
        minute: prefs.getInt('bedMinute') ?? 30,
      );
      _wakeTime = TimeOfDay(
        hour: prefs.getInt('wakeHour') ?? 6,
        minute: prefs.getInt('wakeMinute') ?? 30,
      );
    });
  }

  Future<void> _pickTime(bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isBedtime) _bedtime = picked;
        else _wakeTime = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remindersEnabled', _remindersEnabled);
      await prefs.setBool('smartAlarmEnabled', _smartAlarmEnabled);
      await prefs.setInt('bedHour', _bedtime.hour);
      await prefs.setInt('bedMinute', _bedtime.minute);
      await prefs.setInt('wakeHour', _wakeTime.hour);
      await prefs.setInt('wakeMinute', _wakeTime.minute);

      final reminderService = ref.read(reminderServiceProvider);
      if (_remindersEnabled) {
        await reminderService.scheduleReminders(
          bedHour: _bedtime.hour,
          bedMinute: _bedtime.minute,
        );
        await reminderService.scheduleStreakReminder();
      } else {
        await reminderService.cancelAllReminders();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Configuración guardada! 🎉'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    children: [
                      _buildBedtimeSection(),
                      const SizedBox(height: 16),
                      _buildAlarmSection(),
                      const SizedBox(height: 16),
                      _buildTogglesSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: Text(_isSaving ? 'Guardando...' : 'Guardar configuración'),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recordatorios', style: Theme.of(context).textTheme.headlineMedium),
              Text('Configura tus horarios', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBedtimeSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_rounded, color: AppTheme.secondary, size: 24),
              const SizedBox(width: 12),
              Text('Hora de dormir', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _pickTime(true),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  _bedtime.format(context),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Los recordatorios se enviarán a las ${_formatMinus30()}, ${_formatMinus10()} y a esta hora',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_rounded, color: AppTheme.warning, size: 24),
              const SizedBox(width: 12),
              Text('Hora máxima de despertar', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _pickTime(false),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  _wakeTime.format(context),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSmartAlarmToggle(),
        ],
      ),
    );
  }

  Widget _buildSmartAlarmToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _smartAlarmEnabled
            ? AppTheme.primary.withOpacity(0.1)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _smartAlarmEnabled
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: _smartAlarmEnabled ? AppTheme.primary : AppTheme.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alarma inteligente', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  'Se activa en sueño ligero (ventana de 30 min)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: _smartAlarmEnabled, onChanged: (v) => setState(() => _smartAlarmEnabled = v)),
        ],
      ),
    );
  }

  Widget _buildTogglesSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Opciones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.notifications_rounded, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Recordatorios activos', style: Theme.of(context).textTheme.bodyLarge),
              ),
              Switch(value: _remindersEnabled, onChanged: (v) => setState(() => _remindersEnabled = v)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMinus30() {
    int total = _bedtime.hour * 60 + _bedtime.minute - 30;
    if (total < 0) total += 1440;
    final h = total ~/ 60;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _formatMinus10() {
    int total = _bedtime.hour * 60 + _bedtime.minute - 10;
    if (total < 0) total += 1440;
    final h = total ~/ 60;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
