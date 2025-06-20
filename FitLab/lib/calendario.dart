import 'package:flutter/material.dart';

class Calendario extends StatefulWidget {
  const Calendario({super.key});

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  DateTime selectedDate = DateTime.now();
  final List<String> aulasInscritas = []; // lista de aulas inscritas

  final List<Map<String, String>> classes = [
    {
      'name': 'FitDance',
      'time': '08:00',
      'type': 'Aula Coletiva',
    },
    {
      'name': 'Pilates',
      'time': '10:00',
      'type': 'Aula Coletiva',
    },
    {
      'name': 'Spinning',
      'time': '14:00',
      'type': 'Aula Coletiva',
    },
    {
      'name': 'Yoga',
      'time': '18:00',
      'type': 'Aula Coletiva',
    },
  ];

  void _checkIn(String className) {
    setState(() {
      if (!aulasInscritas.contains(className)) {
        aulasInscritas.add(className);
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-in realizado!'),
        content: Text('Você realizou o check-in para $className.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAulasInscritas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suas Inscrições'),
        content: aulasInscritas.isEmpty
            ? const Text('Você ainda não se inscreveu em nenhuma aula.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: aulasInscritas
                    .map((aula) => ListTile(
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(aula),
                        ))
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _changeDate(int days) {
    final newDate = selectedDate.add(Duration(days: days));
    if (newDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return; // impede voltar para antes de hoje
    }
    setState(() {
      selectedDate = newDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Calendário de Aulas Coletivas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'Minhas Inscrições',
            onPressed: _showAulasInscritas,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: selectedDate.isAfter(DateTime.now())
                    ? () => _changeDate(-1)
                    : null,
              ),
              Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.black),
                onPressed: () => _changeDate(1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final aula = classes[index];
                final isAulaColetiva = aula['type'] == 'Aula Coletiva';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.fitness_center,
                        size: 50,
                        color: Colors.black,
                      ),
                      title: Text(
                        aula['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        '${aula['time']} - ${aula['type']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      trailing: isAulaColetiva
                          ? ElevatedButton(
                              onPressed: () => _checkIn(aula['name']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Check-in'),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
