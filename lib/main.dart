import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const BeatMakerApp());
}

class BeatMakerApp extends StatelessWidget {
  const BeatMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.orangeAccent,
      ),
      home: const BeatMakerScreen(),
    );
  }
}

class BeatMakerScreen extends StatefulWidget {
  const BeatMakerScreen({super.key});

  @override
  _BeatMakerScreenState createState() => _BeatMakerScreenState();
}

class _BeatMakerScreenState extends State<BeatMakerScreen> {
  final AudioEngine _audio = AudioEngine();
  bool _isPlaying = false;
  double _bpm = 120.0;
  int _currentStep = 0;
  late final Stream<int> _stepStream;

  @override
  void initState() {
    super.initState();
    _initAudio();
    // Simplified step sync for UI
    _stepStream = Stream.periodic(
      Duration(milliseconds: (60000 / _bpm / 4).round()),
      (count) => count % 16,
    ).asBroadcastStream();
  }

  Future<void> _initAudio() async {
    await _audio.init();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _audio.play();
      } else {
        _audio.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BEAT MAKER PRO', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.orangeAccent),
            onPressed: () {
              // Export functionality placeholder
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTransportBar(),
          const Divider(color: Colors.white24),
          Expanded(child: _buildSequencerGrid()),
          _buildDrumPads(),
        ],
      ),
    );
  }

  Widget _buildTransportBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPlaying ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                border: Border.all(color: _isPlaying ? Colors.redAccent : Colors.greenAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, 
                color: _isPlaying ? Colors.redAccent : Colors.greenAccent, size: 30),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BPM: ${_bpm.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Slider(
                  value: _bpm,
                  min: 60,
                  max: 200,
                  activeColor: Colors.orangeAccent,
                  onChanged: (val) {
                    setState(() {
                      _bpm = val;
                      _audio.bpm = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequencerGrid() {
    return ListView(
      children: [
        _buildTrackRow(DrumType.kick, 'KICK', Colors.orangeAccent),
        _buildTrackRow(DrumType.snare, 'SNARE', Colors.blueAccent),
        _buildTrackRow(DrumType.hat, 'HI-HAT', Colors.yellowAccent),
        _buildTrackRow(DrumType.clap, 'CLAP', Colors.purpleAccent),
      ],
    );
  }

  Widget _buildTrackRow(DrumType type, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(16, (index) {
                final isActive = _audio.patterns[type]![index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _audio.patterns[type]![index] = !isActive;
                    });
                  },
                  child: Container(
                    width: 35,
                    height: 45,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isActive ? color : Colors.white12,
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text('${index + 1}', 
                        style: TextStyle(color: isActive ? Colors.black : Colors.white38, fontSize: 10)),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrumPads() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildPad(DrumType.kick, 'KICK', Colors.orangeAccent),
          _buildPad(DrumType.snare, 'SNARE', Colors.blueAccent),
          _buildPad(DrumType.hat, 'HAT', Colors.yellowAccent),
          _buildPad(DrumType.clap, 'CLAP', Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _buildPad(DrumType type, String label, Color color) {
    return GestureDetector(
      onTapDown: (_) => _audio.playSound(type), // Match updated public API
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white12,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// Extension to AudioEngine for one-shots
extension on AudioEngine {
  void playOneShot(DrumType type) {
    playSound(type);
  }
}
