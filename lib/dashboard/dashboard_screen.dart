import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_track/dashboard/sleep_summary_widget.dart';
import 'package:dream_track/dashboard/quick_actions_widget.dart';
import 'package:dream_track/tips/daily_tip_service.dart';
import 'package:dream_track/focus/focus_mode_service.dart';
import 'package:dream_track/sleep/sleep_background_service.dart';
import 'package:dream_track/sleep/sleep_tracker_service.dart';
import 'package:dream_track/sleep/sleep_record_model.dart';
import 'package:dream_track/sleep/sleep_register_screen.dart';
import 'package:dream_track/gamification/streak_widget.dart';
import 'package:dream_track/gamification/level_widget.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/utils/date_utils.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _userName = '';
  bool _isBackgroundRunning = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _checkBackgroundService();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('userName') ?? '');
    }
  }

  Future<void> _checkBackgroundService() async {
    final running = await SleepBackgroundService.isRunning();
    if (mounted) setState(() => _isBackgroundRunning = running);
  }

  @override
  Widget build(BuildContext context) {
    final dailyTip = ref.watch(dailyTipProvider);
    final focusState = ref.watch(focusModeServiceProvider);
    final weeklyRecords = ref.watch(weeklyRecordsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lastSleepRecordProvider);
              ref.invalidate(dailyTipProvider);
              await _checkBackgroundService();
            },
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(focusState.isActive)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SleepSummaryWidget(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: QuickActionsWidget(
                    sleepModeActive: focusState.isActive,
                    onSleepMode: _toggleSleepMode,
                    onWakeAndRegister: _despertarYRegistrar,
                    onAiChat: () => Navigator.pushNamed(context, '/ai-chat'),
                    onRegisterSleep: () => Navigator.pushNamed(context, '/sleep-history'),
                    onStats: () => Navigator.pushNamed(context, '/stats'),
                    onReminders: () => Navigator.pushNamed(context, '/reminders'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGamificationRow(weeklyRecords),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: dailyTip.when(
                    data: (tip) => _buildDailyTipCard(tip),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: _buildStatusCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool sleepModeActive) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppDateUtils.greetingByHour()}${_userName.isNotEmpty ? ", $_userName" : ""}! 👋',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  AppDateUtils.formatFullDayName(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (sleepModeActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingDot(color: AppTheme.primary),
                  const SizedBox(width: 6),
                  const Text(
                    'Modo Sueño',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/achievements'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppTheme.warning, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showProfileBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder, width: 1),
              ),
              child: const Icon(Icons.person_rounded, color: AppTheme.primaryLight, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationRow(List<SleepRecord> weeklyRecords) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreakWidget(recentRecords: weeklyRecords),
        const SizedBox(height: 12),
        const LevelWidget(),
      ],
    );
  }

  Widget _buildDailyTipCard(Map<String, String> tip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        onTap: () => Navigator.pushNamed(context, '/tips'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(tip['icon'] ?? '💡', style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ Consejo del día',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip['tip'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Row(
          children: [
            PulsingDot(
              color: _isBackgroundRunning ? AppTheme.success : AppTheme.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isBackgroundRunning
                      ? 'Seguimiento activo'
                      : 'Seguimiento inactivo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _isBackgroundRunning ? AppTheme.success : AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    _isBackgroundRunning
                      ? 'Monitoreando tu sueño en segundo plano'
                      : 'Activa el modo sueño para comenzar',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSleepMode() async {
    final focusNotifier = ref.read(focusModeServiceProvider.notifier);
    final focusState = ref.read(focusModeServiceProvider);

    if (focusState.isActive) {
      await focusNotifier.deactivateSleepMode();
      await SleepBackgroundService.stopService();
      setState(() => _isBackgroundRunning = false);
    } else {
      await focusNotifier.activateSleepMode();
      await SleepBackgroundService.startService();
      setState(() => _isBackgroundRunning = true);
    }
  }

  Future<void> _despertarYRegistrar() async {
    final focusNotifier = ref.read(focusModeServiceProvider.notifier);
    
    // 1. Deactivate sleep mode and stop background service
    await focusNotifier.deactivateSleepMode();
    await SleepBackgroundService.stopService();
    setState(() => _isBackgroundRunning = false);

    // 2. Read sleep start time from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString('sleepModeStart');
    final DateTime bedTime = startStr != null 
        ? DateTime.parse(startStr) 
        : DateTime.now().subtract(const Duration(hours: 8));
    final DateTime wakeTime = DateTime.now();

    // 3. Navigate to SleepRegisterScreen with autocompleted times
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SleepRegisterScreen(
            bedTime: bedTime,
            wakeTime: wakeTime,
          ),
        ),
      ).then((_) {
        // Refresh dashboard statistics
        ref.invalidate(lastSleepRecordProvider);
        ref.invalidate(weeklyRecordsProvider);
      });
    }
  }

  Future<void> _showProfileBottomSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final sleepGoal = prefs.getDouble('sleepGoalHours') ?? 8.0;
    final bedHour = prefs.getInt('bedHour') ?? 22;
    final bedMinute = prefs.getInt('bedMinute') ?? 30;
    final wakeHour = prefs.getInt('wakeHour') ?? 6;
    final wakeMinute = prefs.getInt('wakeMinute') ?? 30;
    final userInitials = _userName.isNotEmpty ? _userName.substring(0, 1).toUpperCase() : 'U';

    final bedTimeStr = '${bedHour.toString().padLeft(2, '0')}:${bedMinute.toString().padLeft(2, '0')}';
    final wakeTimeStr = '${wakeHour.toString().padLeft(2, '0')}:${wakeMinute.toString().padLeft(2, '0')}';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userInitials,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Text(
                    'Miembro de DreamTrack 🌙',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Column(
                            children: [
                              const Icon(Icons.bedtime_rounded, color: AppTheme.secondary, size: 24),
                              const SizedBox(height: 8),
                              const Text(
                                'Horario Objetivo',
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$bedTimeStr - $wakeTimeStr',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Column(
                            children: [
                              const Icon(Icons.stars_rounded, color: AppTheme.warning, size: 24),
                              const SizedBox(height: 8),
                              const Text(
                                'Meta de Sueño',
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sleepGoal.toStringAsFixed(0)} horas',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _logout();
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.error, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Tendrás que ingresar tu contraseña la próxima vez que abras la aplicación.',
          style: TextStyle(fontFamily: 'Nunito', color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sesión cerrada correctamente', style: TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppTheme.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}
