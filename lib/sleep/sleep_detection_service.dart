import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dream_track/shared/constants/app_constants.dart';

enum SleepPhase { awake, lightSleep, deepSleep, rem }

class SleepDetectionState {
  final bool isSleeping;
  final SleepPhase currentPhase;
  final DateTime? sleepStartTime;
  final List<double> recentMovements;
  final double currentMovementLevel;

  const SleepDetectionState({
    this.isSleeping = false,
    this.currentPhase = SleepPhase.awake,
    this.sleepStartTime,
    this.recentMovements = const [],
    this.currentMovementLevel = 0,
  });

  SleepDetectionState copyWith({
    bool? isSleeping,
    SleepPhase? currentPhase,
    DateTime? sleepStartTime,
    List<double>? recentMovements,
    double? currentMovementLevel,
  }) {
    return SleepDetectionState(
      isSleeping: isSleeping ?? this.isSleeping,
      currentPhase: currentPhase ?? this.currentPhase,
      sleepStartTime: sleepStartTime ?? this.sleepStartTime,
      recentMovements: recentMovements ?? this.recentMovements,
      currentMovementLevel: currentMovementLevel ?? this.currentMovementLevel,
    );
  }
}

final sleepDetectionProvider =
    StateNotifierProvider<SleepDetectionNotifier, SleepDetectionState>((ref) {
  return SleepDetectionNotifier();
});

class SleepDetectionNotifier extends StateNotifier<SleepDetectionState> {
  SleepDetectionNotifier() : super(const SleepDetectionState());

  StreamSubscription<AccelerometerEvent>? _subscription;
  Timer? _detectionTimer;
  final List<double> _movementBuffer = [];
  DateTime? _lastMovementTime;
  static const int _bufferSize = 60; // 60 samples

  void startDetection() {
    _subscription?.cancel();
    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(seconds: 1),
    ).listen(_onAccelerometerEvent);

    _detectionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _analyzeMovement(),
    );
  }

  void stopDetection() {
    _subscription?.cancel();
    _detectionTimer?.cancel();
    _subscription = null;
    _detectionTimer = null;
    state = const SleepDetectionState();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate magnitude of acceleration vector (excluding gravity baseline)
    final magnitude = _calculateMagnitude(event.x, event.y, event.z);
    final adjustedMag = (magnitude - 9.81).abs(); // Remove gravity component

    _movementBuffer.add(adjustedMag);
    if (_movementBuffer.length > _bufferSize) {
      _movementBuffer.removeAt(0);
    }

    final avgMovement = _movementBuffer.isEmpty
        ? 0.0
        : _movementBuffer.reduce((a, b) => a + b) / _movementBuffer.length;

    if (adjustedMag > AppConstants.movementThreshold) {
      _lastMovementTime = DateTime.now();
    }

    state = state.copyWith(
      currentMovementLevel: avgMovement,
      recentMovements: List.from(_movementBuffer),
    );
  }

  void _analyzeMovement() {
    if (_movementBuffer.isEmpty) return;

    final avgMovement = _movementBuffer.reduce((a, b) => a + b) / _movementBuffer.length;
    final now = DateTime.now();
    final minutesSinceLastMove = _lastMovementTime != null
        ? now.difference(_lastMovementTime!).inMinutes
        : 0;

    SleepPhase newPhase;
    bool sleeping = state.isSleeping;

    if (avgMovement < AppConstants.deepSleepThreshold) {
      newPhase = SleepPhase.deepSleep;
    } else if (avgMovement < AppConstants.lightSleepThreshold) {
      newPhase = SleepPhase.lightSleep;
    } else {
      newPhase = SleepPhase.awake;
    }

    // Detect sleep onset: no movement for 15+ minutes
    if (!sleeping && minutesSinceLastMove >= AppConstants.noMovementMinutes) {
      sleeping = true;
      state = state.copyWith(
        isSleeping: true,
        sleepStartTime: _lastMovementTime ?? now,
        currentPhase: SleepPhase.lightSleep,
      );
      return;
    }

    // Detect wake: significant movement after sleeping
    if (sleeping && avgMovement > AppConstants.lightSleepThreshold * 3) {
      sleeping = false;
      state = state.copyWith(
        isSleeping: false,
        currentPhase: SleepPhase.awake,
      );
      return;
    }

    state = state.copyWith(
      isSleeping: sleeping,
      currentPhase: newPhase,
    );
  }

  double _calculateMagnitude(double x, double y, double z) {
    return (x * x + y * y + z * z).clamp(0.0, double.infinity);
  }

  bool get isInLightSleep =>
      state.isSleeping && state.currentPhase == SleepPhase.lightSleep;

  @override
  void dispose() {
    stopDetection();
    super.dispose();
  }
}
