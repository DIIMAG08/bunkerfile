import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dream_track/shared/theme/app_theme.dart';
import 'package:dream_track/onboarding/onboarding_screen.dart';
import 'package:dream_track/dashboard/dashboard_screen.dart';
import 'package:dream_track/sleep/sleep_register_screen.dart';
import 'package:dream_track/sleep/sleep_history_screen.dart';
import 'package:dream_track/stats/stats_screen.dart';
import 'package:dream_track/tips/tips_screen.dart';
import 'package:dream_track/tips/habit_program_screen.dart';
import 'package:dream_track/ai/ai_chat_screen.dart';
import 'package:dream_track/reminders/reminder_settings_screen.dart';
import 'package:dream_track/focus/app_selector_screen.dart';
import 'package:dream_track/gamification/achievements_screen.dart';
import 'package:dream_track/gamification/weekly_score_screen.dart';
import 'package:dream_track/auth/auth_screen.dart';

class DreamTrackApp extends ConsumerWidget {
  const DreamTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'DreamTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppRouter(),
      routes: {
        '/home': (ctx) => const MainNavScreen(),
        '/register-sleep': (ctx) => const SleepRegisterScreen(),
        '/sleep-history': (ctx) => const SleepHistoryScreen(),
        '/login': (ctx) => const AuthScreen(),
        '/stats': (ctx) => const StatsScreen(),
        '/tips': (ctx) => const TipsScreen(),
        '/habits': (ctx) => const HabitProgramScreen(),
        '/ai-chat': (ctx) => const AiChatScreen(),
        '/reminders': (ctx) => const ReminderSettingsScreen(),
        '/app-blocker': (ctx) => const AppSelectorScreen(),
        '/achievements': (ctx) => const AchievementsScreen(),
        '/weekly-score': (ctx) => const WeeklyScoreScreen(),
      },
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool? _onboardingComplete;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboardingComplete') ?? false;
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (mounted) {
      setState(() {
        _onboardingComplete = done;
        _isLoggedIn = loggedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'DreamTrack',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_onboardingComplete!) {
      return _isLoggedIn ? const MainNavScreen() : const AuthScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    StatsScreen(),
    AiChatScreen(),
    TipsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Estadísticas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              activeIcon: Icon(Icons.auto_awesome_rounded),
              label: 'IA',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline_rounded),
              activeIcon: Icon(Icons.lightbulb_rounded),
              label: 'Consejos',
            ),
          ],
        ),
      ),
    );
  }
}
