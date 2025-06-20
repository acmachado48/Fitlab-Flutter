import 'dart:async';
import 'package:flutter/material.dart';

class WorkoutTimerPage extends StatefulWidget {
  const WorkoutTimerPage({super.key});

  @override
  State<WorkoutTimerPage> createState() => _WorkoutTimerPageState();
}

class _WorkoutTimerPageState extends State<WorkoutTimerPage> {
  int selectedTime = 60;
  int remainingTime = 60;
  Timer? _timer;
  bool isRunning = false;

  void _startTimer() {
    _stopTimer();
    setState(() {
      remainingTime = selectedTime;
      isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        _stopTimer();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() => remainingTime = selectedTime);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => isRunning = false);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeOptions = [30, 45, 60, 90, 120, 180];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronômetro de Treino'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // <- centralização vertical
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tempo selecionado:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: selectedTime,
                items: timeOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value segundos'),
                  );
                }).toList(),
                onChanged: isRunning
                    ? null
                    : (newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedTime = newValue;
                            remainingTime = newValue;
                          });
                        }
                      },
              ),
              const SizedBox(height: 30),
              Text(
                _formatTime(remainingTime),
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isRunning ? null : _startTimer,
                    child: const Text('Iniciar'),
                  ),
                  ElevatedButton(
                    onPressed: isRunning ? _pauseTimer : null,
                    child: const Text('Pausar'),
                  ),
                  ElevatedButton(
                    onPressed: _resetTimer,
                    child: const Text('Reiniciar'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
