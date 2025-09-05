import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Timer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const PomodoroTimer(),
    );
  }
}

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  static const int _initialWorkMinutes = 25;
  static const int _initialRestMinutes = 5;

  int _workMinutes = _initialWorkMinutes;
  int _restMinutes = _initialRestMinutes;
  late int _totalSeconds;
  late int _currentSeconds;
  Timer? _timer;
  bool _isWorking = true;
  bool _isPaused = true;

  final TextEditingController _workController = TextEditingController(
    text: _initialWorkMinutes.toString(),
  );
  final TextEditingController _restController = TextEditingController(
    text: _initialRestMinutes.toString(),
  );

  List<String> _quotes = [];
  late Future<bool> _isInitialized;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _workMinutes * 60;
    _currentSeconds = _totalSeconds;
    _isInitialized = _loadQuotes();
    // Non è divertente ina cattiva
  }

  Future<bool> _loadQuotes() async {
    try {
      final String quotesString = await rootBundle.loadString(
        'assets/motivational_quotes.txt',
      );
      _quotes = quotesString.split('\n').where((q) => q.isNotEmpty).toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showQuoteDialog() {
    if (_quotes.isNotEmpty) {
      final randomQuote = _quotes[Random().nextInt(_quotes.length)];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Well Done!'),
          content: Text(randomQuote),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        setState(() {
          _currentSeconds--;
        });
      } else {
        _timer!.cancel();
        if (_isWorking) {
          _showQuoteDialog();
        }
        setState(() {
          _isWorking = !_isWorking;
          _totalSeconds = (_isWorking ? _workMinutes : _restMinutes) * 60;
          _currentSeconds = _totalSeconds;
          _isPaused = true;
        });
      }
    });
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _isPaused = true;
    });
  }

  void _resetTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _isWorking = true;
      _totalSeconds = _workMinutes * 60;
      _currentSeconds = _totalSeconds;
      _isPaused = true;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _updateDurations() {
    setState(() {
      _workMinutes = int.tryParse(_workController.text) ?? _initialWorkMinutes;
      _restMinutes = int.tryParse(_restController.text) ?? _initialRestMinutes;
      if (_isWorking) {
        _totalSeconds = _workMinutes * 60;
        _currentSeconds = _totalSeconds;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isInitialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == false) {
          return const Scaffold(
            body: Center(child: Text("Error loading quotes")),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Pomodoro Timer'), elevation: 0),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isWorking ? 'Work' : 'Rest',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _totalSeconds > 0
                                ? _currentSeconds / _totalSeconds
                                : 0,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isWorking ? Colors.red : Colors.green,
                            ),
                          ),
                          Center(
                            child: Text(
                              _formatTime(_currentSeconds),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isPaused)
                          ElevatedButton(
                            onPressed: _startTimer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                            ),
                            child: const Text('Start'),
                          )
                        else
                          ElevatedButton(
                            onPressed: _pauseTimer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                            ),
                            child: const Text('Pause'),
                          ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: _resetTimer,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _workController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Work (minutes)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextField(
                            controller: _restController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Rest (minutes)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateDurations,
                      child: const Text('Set Durations'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _workController.dispose();
    _restController.dispose();
    super.dispose();
  }
}
