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

  // Sound source properties
  AudioSource? _kickSource;
  AudioSource? _snareSource;
  AudioSource? _hatSource;
  AudioSource? _clapSource;

  // Track patterns: map of DrumType to a list of 16 booleans
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
    
    // Load waveforms for professional synthesis
    _kickSource = await SoLoud.instance.loadWaveform(WaveForm.sin, superWave: true);
    _snareSource = await SoLoud.instance.loadWaveform(WaveForm.fSaw);
    _hatSource = await SoLoud.instance.loadWaveform(WaveForm.fSaw);
    _clapSource = await SoLoud.instance.loadWaveform(WaveForm.fSaw);

    _initialized = true;
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
        playSound(type);
      }
    });
  }

  void playSound(DrumType type) {
    if (!_initialized) return;
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

  void _playKick() {
    if (_kickSource == null) return;
    SoLoud.instance.play(_kickSource!, volume: 1.0).then((handle) {
      // Quick pitch drop and volume decay for professional kick
      SoLoud.instance.fadeVolume(handle, 0.0, const Duration(milliseconds: 150));
      Future.delayed(const Duration(milliseconds: 150), () => SoLoud.instance.stop(handle));
    });
  }

  void _playSnare() {
    if (_snareSource == null) return;
    SoLoud.instance.play(_snareSource!, volume: 0.7).then((handle) {
      SoLoud.instance.fadeVolume(handle, 0.0, const Duration(milliseconds: 100));
      Future.delayed(const Duration(milliseconds: 100), () => SoLoud.instance.stop(handle));
    });
  }

  void _playHat() {
    if (_hatSource == null) return;
    SoLoud.instance.play(_hatSource!, volume: 0.3).then((handle) {
      SoLoud.instance.fadeVolume(handle, 0.0, const Duration(milliseconds: 40));
      Future.delayed(const Duration(milliseconds: 40), () => SoLoud.instance.stop(handle));
    });
  }

  void _playClap() {
    if (_clapSource == null) return;
    // Multi-trigger for clap feel
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 15), () {
        SoLoud.instance.play(_clapSource!, volume: 0.5).then((handle) {
          SoLoud.instance.fadeVolume(handle, 0.0, const Duration(milliseconds: 80));
          Future.delayed(const Duration(milliseconds: 80), () => SoLoud.instance.stop(handle));
        });
      });
    }
  }

  Future<void> dispose() async {
    stop();
    await SoLoud.instance.deinit();
  }
}
