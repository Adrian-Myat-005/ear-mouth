import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';

enum DrumType { kick, snare, hat, clap }

class AudioEngine {
  static final AudioEngine _instance = AudioEngine._internal();
  factory AudioEngine() => _instance;
  AudioEngine._internal();

  bool _initialized = false;
  double _bpm = 120;
  int _currentStep = 0;
  final int _totalSteps = 16;
  Timer? _timer;

  // Track patterns: map of DrumType to a list of 16 booleans (active/inactive)
  final Map<DrumType, List<bool>> patterns = {
    DrumType.kick: List.generate(16, (index) => index % 4 == 0),
    DrumType.snare: List.generate(16, (index) => index % 8 == 4),
    DrumType.hat: List.generate(16, (index) => index % 2 == 0),
    DrumType.clap: List.generate(16, (index) => false),
  };

  double get bpm => _bpm;
  set bpm(double value) {
    _bpm = value;
    if (isPlaying) {
      stop();
      play();
    }
  }

  bool get isPlaying => _timer?.isActive ?? false;
  int get currentStep => _currentStep;

  Future<void> init() async {
    if (_initialized) return;
    await SoLoud.instance.init();
    _initialized = true;
  }

  Future<void> startRecording() async {
    // Start capturing the master output
    // Note: soloud_recorder is usually a separate plugin or part of soloud
    // We will use a conceptual placeholder for professional export
  }

  void play() {
    if (!_initialized) return;
    final stepDuration = Duration(milliseconds: (60000 / _bpm / 4).round());
    _timer = Timer.periodic(stepDuration, (timer) {
      _triggerStep();
      _currentStep = (_currentStep + 1) % _totalSteps;
    });
  }

  void stop() {
    _timer?.cancel();
    _currentStep = 0;
  }

  void _triggerStep() {
    patterns.forEach((type, steps) {
      if (steps[_currentStep]) {
        _playSound(type);
      }
    });
  }

  void _playSound(DrumType type) {
    switch (type) {
      case DrumType.kick:
        _playKick();
        break;
      case DrumType.snare:
        _playSnare();
        break;
      case DrumType.hat:
        _playHat();
        break;
      case DrumType.clap:
        _playClap();
        break;
    }
  }

  // --- From-scratch Synthesis ---

  void _playKick() {
    final sound = SoLoud.instance.playOscillator(
      waveform: Waveform.sin,
      frequency: 60,
    );
    // Exponential volume decay for a "thump"
    SoLoud.instance.setVolume(sound, 1.0);
    Future.delayed(const Duration(milliseconds: 50), () {
      SoLoud.instance.fadeVolume(sound, 0.0, const Duration(milliseconds: 150));
      Future.delayed(const Duration(milliseconds: 150), () {
        SoLoud.instance.stop(sound);
      });
    });
  }

  void _playSnare() {
    final sound = SoLoud.instance.playOscillator(
      waveform: Waveform.whiteNoise,
    );
    SoLoud.instance.setVolume(sound, 0.8);
    // High-pass filter simulation + quick decay
    Future.delayed(const Duration(milliseconds: 20), () {
      SoLoud.instance.fadeVolume(sound, 0.0, const Duration(milliseconds: 100));
      Future.delayed(const Duration(milliseconds: 100), () {
        SoLoud.instance.stop(sound);
      });
    });
  }

  void _playHat() {
    final sound = SoLoud.instance.playOscillator(
      waveform: Waveform.whiteNoise,
    );
    SoLoud.instance.setVolume(sound, 0.4);
    // Very short decay
    Future.delayed(const Duration(milliseconds: 5), () {
      SoLoud.instance.fadeVolume(sound, 0.0, const Duration(milliseconds: 40));
      Future.delayed(const Duration(milliseconds: 40), () {
        SoLoud.instance.stop(sound);
      });
    });
  }

  void _playClap() {
    // Claps are traditionally multiple quick noise bursts
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 15), () {
        final sound = SoLoud.instance.playOscillator(waveform: Waveform.whiteNoise);
        SoLoud.instance.setVolume(sound, 0.6);
        SoLoud.instance.fadeVolume(sound, 0.0, const Duration(milliseconds: 80));
        Future.delayed(const Duration(milliseconds: 80), () {
          SoLoud.instance.stop(sound);
        });
      });
    }
  }

  Future<void> dispose() async {
    stop();
    await SoLoud.instance.deinit();
  }
}
