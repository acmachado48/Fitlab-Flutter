import 'package:flutter/material.dart';
import 'dart:async';

class SessionPage extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;

  const SessionPage({Key? key, required this.exercises}) : super(key: key);

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  int currentIndex = 0;
  int countdown = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    timer?.cancel();
    countdown = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void nextExercise() {
    timer?.cancel();
    if (currentIndex < widget.exercises.length - 1) {
      setState(() {
        currentIndex++;
      });
      startCountdown();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sessão de treino'),
          backgroundColor: Colors.black,
        ),
        body: const Center(child: Text('Nenhum exercício disponível.')),
      );
    }

    final exercise = widget.exercises[currentIndex];

    final String gifUrl = (exercise['gifUrl'] ?? '').toString();
    final String name = (exercise['name'] ?? 'Sem Nome').toString();
    final String target = (exercise['target'] ?? 'Sem Alvo').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessão de treino'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (gifUrl.isNotEmpty)
              Image.network(
                gifUrl,
                width: 200,
                height: 200,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 100),
              )
            else
              const Icon(Icons.image_not_supported, size: 100),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Alvo: $target', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            Text(
              'Descanso: $countdown s',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: nextExercise,
              child: const Text('Próximo Exercício'),
            ),
          ],
        ),
      ),
    );
  }
}
