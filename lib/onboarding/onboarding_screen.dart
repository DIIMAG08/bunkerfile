import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/shared/widgets/common_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  double _sleepGoal = 8.0;
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);

  final List<Map<String, dynamic>> _pages = [
    {
      'emoji': '🌙',
      'title': 'Bienvenido a DreamTrack',
      'subtitle': 'Tu asistente completo para mejorar la calidad de tu sueño y despertar con energía cada día.',
      'color': AppTheme.primary,
    },
    {
      'emoji': '📊',
      'title': 'Seguimiento inteligente',
      'subtitle': 'Registra tu sueño automáticamente usando el acelerómetro. Visualiza ciclos, gráficas y estadísticas detalladas.',
      'color': AppTheme.secondary,
    },
    {
      'emoji': '🤖',
      'title': 'IA especializada',
      'subtitle': 'Chatea con tu asistente de sueño personal. Recibe análisis y recomendaciones basadas en TU historial.',
      'color': AppTheme.success,
    },
    {
      'emoji': '🎮',
      'title': 'Gamificación & Logros',
      'subtitle': 'Mantén tu racha de sueño, sube de nivel y desbloquea más de 25 logros mejorando tu descanso.',
      'color': AppTheme.warning,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToSetup();
    }
  }

  void _goToSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, i) => _buildPage(_pages[i]),
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    final isWelcome = page['title'] == 'Bienvenido a DreamTrack';
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: (page['color'] as Color).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isWelcome
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Text(
                      page['emoji'] as String,
                      style: const TextStyle(fontSize: 56),
                    ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page['title'] as String,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page['subtitle'] as String,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i ? AppTheme.primary : AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: Text(
                _currentPage < _pages.length - 1 ? 'Siguiente' : 'Comenzar',
              ),
            ),
          ),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _goToSetup,
              child: const Text(
                'Saltar',
                style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito'),
              ),
            ),
        ],
      ),
    );
  }
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  double _sleepGoal = 8.0;
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  int _step = 0;
  bool _requestingPermissions = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _requestPermissions() async {
    setState(() => _requestingPermissions = true);

    await [
      Permission.notification,
      Permission.microphone,
      Permission.activityRecognition,
    ].request();

    // Request Do Not Disturb permission
    try {
      final dndPlugin = DoNotDisturbPlugin();
      final hasPerm = await dndPlugin.isNotificationPolicyAccessGranted();
      if (hasPerm != true) {
        await dndPlugin.openNotificationPolicyAccessSettings();
      }
    } catch (e) {
      debugPrint('Error requesting Do Not Disturb permission: $e');
    }

    setState(() => _requestingPermissions = false);
    _finishSetup();
  }

  Future<void> _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());
    await prefs.setString('userPassword', _passwordController.text.trim());
    await prefs.setDouble('sleepGoalHours', _sleepGoal);
    await prefs.setInt('bedHour', _bedtime.hour);
    await prefs.setInt('bedMinute', _bedtime.minute);
    await prefs.setInt('wakeHour', _wakeTime.hour);
    await prefs.setInt('wakeMinute', _wakeTime.minute);
    await prefs.setBool('onboardingComplete', true);
    await prefs.setBool('isLoggedIn', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  _step == 0 ? '¿Cómo te llamas?' :
                  _step == 1 ? 'Tu meta de sueño' :
                  _step == 2 ? 'Tu horario' : '¡Casi listo!',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 0 ? 'Personalizaremos la app para ti.' :
                  _step == 1 ? 'La recomendación estándar es 7-9 horas.' :
                  _step == 2 ? 'Configuraremos tus recordatorios.' :
                  'Solo necesitamos algunos permisos para funcionar.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 40),
                Expanded(child: _buildStepContent()),
                _buildStepButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildGoalStep();
      case 2:
        return SingleChildScrollView(child: _buildScheduleStep());
      case 3:
        return SingleChildScrollView(child: _buildPermissionsStep());
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Nunito', fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'Tu nombre...',
            prefixIcon: Icon(Icons.person_rounded, color: AppTheme.textMuted),
          ),
          autofocus: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Nunito', fontSize: 18),
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Contraseña de seguridad (mín. 4 caracteres)...',
            prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.textMuted),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          '${_sleepGoal.toStringAsFixed(0)} horas',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        Slider(
          value: _sleepGoal,
          min: 5,
          max: 12,
          divisions: 14,
          onChanged: (v) => setState(() => _sleepGoal = v),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5h', style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito')),
            Text('12h', style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito')),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      children: [
        GlassCard(
          onTap: () => _pickTime(true),
          child: Row(
            children: [
              const Icon(Icons.bedtime_rounded, color: AppTheme.secondary, size: 28),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hora de dormir', style: Theme.of(context).textTheme.bodyMedium),
                Text(_bedtime.format(context), style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.secondary,
                )),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          onTap: () => _pickTime(false),
          child: Row(
            children: [
              const Icon(Icons.alarm_rounded, color: AppTheme.warning, size: 28),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hora de despertar', style: Theme.of(context).textTheme.bodyMedium),
                Text(_wakeTime.format(context), style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.warning,
                )),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsStep() {
    final perms = [
      {'icon': '🔔', 'name': 'Notificaciones', 'desc': 'Para recordatorios y alarmas'},
      {'icon': '🎙️', 'name': 'Micrófono', 'desc': 'Para detectar patrones de sueño'},
      {'icon': '🏃', 'name': 'Actividad física', 'desc': 'Para el acelerómetro de sueño'},
      {'icon': '🌙', 'name': 'No interrumpir', 'desc': 'Para silenciar notificaciones al dormir'},
    ];

    return Column(
      children: perms.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          child: Row(
            children: [
              Text(p['icon']!, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name']!, style: Theme.of(context).textTheme.titleMedium),
                    Text(p['desc']!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildStepButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestingPermissions ? null : () async {
              if (_step == 0) {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Por favor, ingresa tu nombre', style: TextStyle(fontFamily: 'Nunito')),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  return;
                }
                if (_passwordController.text.trim().length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('La contraseña debe tener al menos 4 caracteres', style: TextStyle(fontFamily: 'Nunito')),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  return;
                }
              }
              if (_step < 3) {
                setState(() => _step++);
              } else {
                await _requestPermissions();
              }
            },
            child: _requestingPermissions
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text(_step < 3 ? 'Continuar' : 'Otorgar permisos y comenzar'),
          ),
        ),
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Atrás', style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito')),
          ),
        if (_step == 3)
          TextButton(
            onPressed: _finishSetup,
            child: const Text('Saltar permisos', style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito')),
          ),
      ],
    );
  }
}
