import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dream_track/sleep/sleep_tracker_service.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';
import 'package:dream_track/shared/utils/date_utils.dart';
import 'package:dream_track/gamification/gamification_service.dart';

class SleepRegisterScreen extends ConsumerStatefulWidget {
  final DateTime? bedTime;
  final DateTime? wakeTime;

  const SleepRegisterScreen({
    super.key,
    this.bedTime,
    this.wakeTime,
  });

  @override
  ConsumerState<SleepRegisterScreen> createState() => _SleepRegisterScreenState();
}

class _SleepRegisterScreenState extends ConsumerState<SleepRegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  late DateTime _bedTime;
  late DateTime _wakeTime;
  int _quality = 3;
  bool _hadNightmares = false;
  bool _hadDreams = false;
  int _wakeUps = 0;
  bool _usedSounds = false;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bedTime = widget.bedTime ?? DateTime.now().subtract(const Duration(hours: 8));
    _wakeTime = widget.wakeTime ?? DateTime.now();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isBedtime) async {
    final initial = isBedtime ? _bedTime : _wakeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        if (isBedtime) {
          _bedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
          // If bedtime is after current time, assume previous day
          if (_bedTime.isAfter(now)) {
            _bedTime = _bedTime.subtract(const Duration(days: 1));
          }
        } else {
          _wakeTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final service = ref.read(sleepTrackerServiceProvider);
      final record = service.createFromTimes(
        bedTime: _bedTime,
        wakeTime: _wakeTime,
        quality: _quality,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        hadNightmares: _hadNightmares,
        hadDreams: _hadDreams,
        wakeUps: _wakeUps,
        usedSounds: _usedSounds,
      );
      await service.saveRecord(record);

      // Invalidate sleep record providers to ensure the UI refreshes
      ref.invalidate(allSleepRecordsProvider);
      ref.invalidate(lastSleepRecordProvider);
      ref.invalidate(weeklyRecordsProvider);
      ref.invalidate(monthlyRecordsProvider);

      // Update gamification
      await ref.read(gamificationProvider.notifier).onSleepRecorded(record, context: context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success),
                const SizedBox(width: 12),
                Text(
                  '¡Registro guardado! ${AppDateUtils.formatHoursSlept(record.hoursSlept)} dormidas',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Nunito'),
                ),
              ],
            ),
            backgroundColor: AppTheme.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double get _hoursSlept => AppDateUtils.calculateHoursSlept(_bedTime, _wakeTime);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      children: [
                        _buildHoursSummary(),
                        const SizedBox(height: 16),
                        _buildTimeSection(),
                        const SizedBox(height: 16),
                        _buildQualitySection(),
                        const SizedBox(height: 16),
                        _buildDetailsSection(),
                        const SizedBox(height: 16),
                        _buildNotesSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSaveButton(),
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
              Text('Registrar Sueño', style: Theme.of(context).textTheme.headlineMedium),
              Text('¿Cómo dormiste?', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoursSummary() {
    final hours = _hoursSlept;
    final isGood = hours >= 7;
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isGood ? Icons.nightlight_round : Icons.warning_amber_rounded,
            color: isGood ? AppTheme.success : AppTheme.warning,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppDateUtils.formatHoursSlept(hours),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: isGood ? AppTheme.success : AppTheme.warning,
                ),
              ),
              Text(
                isGood ? '¡Buen descanso!' : 'Por debajo de tu meta',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Horario de sueño', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTimeTile(
                icon: Icons.bedtime_rounded,
                label: 'Me acosté',
                time: _bedTime,
                color: AppTheme.secondary,
                onTap: () => _pickTime(true),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeTile(
                icon: Icons.wb_sunny_rounded,
                label: 'Me desperté',
                time: _wakeTime,
                color: AppTheme.warning,
                onTap: () => _pickTime(false),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String label,
    required DateTime time,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              AppDateUtils.formatTime(time),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calidad del sueño', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _qualityLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: StarRating(
              rating: _quality,
              onRatingChanged: (r) => setState(() => _quality = r),
              size: 42,
            ),
          ),
        ],
      ),
    );
  }

  String get _qualityLabel {
    switch (_quality) {
      case 1: return 'Muy malo 😴';
      case 2: return 'Malo 😕';
      case 3: return 'Regular 😐';
      case 4: return 'Bueno 😊';
      case 5: return 'Excelente 🌟';
      default: return '';
    }
  }

  Widget _buildDetailsSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalles adicionales', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildToggleRow(
            icon: Icons.dark_mode_rounded,
            label: 'Tuve pesadillas',
            value: _hadNightmares,
            onChanged: (v) => setState(() => _hadNightmares = v),
          ),
          _buildToggleRow(
            icon: Icons.cloud_rounded,
            label: 'Recuerdo sueños',
            value: _hadDreams,
            onChanged: (v) => setState(() => _hadDreams = v),
          ),
          _buildToggleRow(
            icon: Icons.music_note_rounded,
            label: 'Usé sonidos relajantes',
            value: _usedSounds,
            onChanged: (v) => setState(() => _usedSounds = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.sync_rounded, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Veces que me desperté:', style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(width: 12),
              _buildCounter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () { if (_wakeUps > 0) setState(() => _wakeUps--); },
          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.textSecondary, size: 22),
        ),
        const SizedBox(width: 8),
        Text(
          '$_wakeUps',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(width: 8),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => setState(() => _wakeUps++),
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 22),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notas (opcional)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Nunito'),
            decoration: InputDecoration(
              hintText: '¿Cómo te sentiste al despertar?',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito'),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_rounded, color: Colors.white),
          label: Text(
            _isSaving ? 'Guardando...' : 'Guardar registro',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ),
    );
  }
}
