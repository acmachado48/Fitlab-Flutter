import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  Map<String, bool> checkins = {};
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  User? user = FirebaseAuth.instance.currentUser;

  int sequenciaAtual = 0;
  int maiorSequencia = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _inicializarCheckinInicial().then((_) {
      _carregarCheckinsMes(focusedDay);
    });
  }

  Future<void> _inicializarCheckinInicial() async {
    if (user == null) return;

    final uid = user!.uid;
    final hojeStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('checkins')
        .doc(hojeStr);

    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'date': hojeStr,
        'checked': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _carregarCheckinsMes(DateTime mes) async {
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final uid = user!.uid;
    final inicio = DateTime(mes.year, mes.month, 1);
    final fim = DateTime(mes.year, mes.month + 1, 0);
    final inicioStr = DateFormat('yyyy-MM-dd').format(inicio);
    final fimStr = DateFormat('yyyy-MM-dd').format(fim);

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('checkins')
        .where('date', isGreaterThanOrEqualTo: inicioStr)
        .where('date', isLessThanOrEqualTo: fimStr)
        .get();

    final Map<String, bool> dados = {};
    for (var doc in snapshot.docs) {
      final date = doc['date'] as String;
      final checked = doc['checked'] as bool? ?? false;
      dados[date] = checked;
    }

    setState(() {
      checkins = dados;
      _isLoading = false;
    });

    _calcularSequencias();
  }

  void _calcularSequencias() {
    if (checkins.isEmpty) {
      setState(() {
        sequenciaAtual = 0;
        maiorSequencia = 0;
      });
      return;
    }

    // Datas ordenadas dos check-ins marcados
    List<DateTime> diasCheckin = checkins.entries
        .where((e) => e.value == true)
        .map((e) => DateTime.parse(e.key))
        .toList();
    diasCheckin.sort();

    // Calcular maior sequência normalmente
    int maior = 0;
    int contador = 1;
    for (int i = 1; i < diasCheckin.length; i++) {
      final anterior = diasCheckin[i - 1];
      final atual = diasCheckin[i];
      if (atual.difference(anterior).inDays == 1) {
        contador++;
      } else {
        if (contador > maior) maior = contador;
        contador = 1;
      }
    }
    if (contador > maior) maior = contador;

    final hoje = DateTime.now();
    final hojeStr = DateFormat('yyyy-MM-dd')
        .format(DateTime(hoje.year, hoje.month, hoje.day));
    final ontem = hoje.subtract(const Duration(days: 1));
    final ontemStr = DateFormat('yyyy-MM-dd').format(ontem);

    // Se usuário fez check-in hoje, começa sequência a partir de hoje
    // Caso contrário, só continua se fez check-in ontem
    if (checkins[hojeStr] == true) {
      // Conta sequência para trás a partir de hoje
      int atualStreak = 0;
      DateTime diaAtual = hoje;

      while (true) {
        final diaStr = DateFormat('yyyy-MM-dd').format(diaAtual);
        if (checkins[diaStr] == true) {
          atualStreak++;
          diaAtual = diaAtual.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      setState(() {
        maiorSequencia = maior;
        sequenciaAtual = atualStreak;
      });
    } else if (checkins[ontemStr] == true) {
      // Usuário não marcou hoje, mas marcou ontem, sequência vale até ontem
      int atualStreak = 0;
      DateTime diaAtual = ontem;

      while (true) {
        final diaStr = DateFormat('yyyy-MM-dd').format(diaAtual);
        if (checkins[diaStr] == true) {
          atualStreak++;
          diaAtual = diaAtual.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      setState(() {
        maiorSequencia = maior;
        sequenciaAtual = atualStreak;
      });
    } else {
      // Usuário não marcou hoje nem ontem, sequência atual reseta
      setState(() {
        maiorSequencia = maior;
        sequenciaAtual = 0;
      });
    }
  }

  Future<void> _toggleCheckin(DateTime day) async {
    if (user == null) return;

    final uid = user!.uid;
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('checkins')
        .doc(dayStr);

    final atual = checkins[dayStr] ?? false;
    final novoStatus = !atual;

    await docRef.set({
      'date': dayStr,
      'checked': novoStatus,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      checkins[dayStr] = novoStatus;
    });

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Check-in ${novoStatus ? "marcado" : "removido"} em $dayStr',
      ),
    ));

    await _atualizarTotalCheckinsMes();
    await _carregarCheckinsMes(focusedDay);
  }

  Future<void> _atualizarTotalCheckinsMes() async {
    if (user == null) return;

    final uid = user!.uid;
    final mes = focusedDay.month.toString().padLeft(2, '0');
    final ano = focusedDay.year;
    final inicio = '$ano-$mes-01';
    final fim = '$ano-$mes-31';

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('checkins')
        .where('date', isGreaterThanOrEqualTo: inicio)
        .where('date', isLessThanOrEqualTo: fim)
        .where('checked', isEqualTo: true)
        .get();

    final totalCheckinsMes = snapshot.docs.length;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({'totalCheckinsMes': totalCheckinsMes});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: const Text('Calendário de Check-ins'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => false,
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
              _toggleCheckin(selected);
            },
            onPageChanged: (focusedMonth) {
              focusedDay = focusedMonth;
              _carregarCheckinsMes(focusedMonth);
            },
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mês',
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              defaultDecoration: BoxDecoration(shape: BoxShape.circle),
              weekendDecoration: BoxDecoration(shape: BoxShape.circle),
              outsideDecoration: BoxDecoration(shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => _buildDayCell(day),
              todayBuilder: (context, day, _) => _buildDayCell(day),
            ),
          ),

          const SizedBox(height: 24),

          // Mostrar loading enquanto carrega ou streak / mensagem
          _isLoading ? const CircularProgressIndicator() : _buildStreakCard(),

          const SizedBox(height: 24),

          Text(
            'Check-ins do mês: ${checkins.values.where((e) => e).length}',
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    const int maxStreakVisual = 30;

    double progress = (sequenciaAtual / maxStreakVisual);
    if (progress > 1.0) progress = 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(
                  'Sequência atual: ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800]),
                ),
                sequenciaAtual > 0
                    ? Text(
                        '$sequenciaAtual dia${sequenciaAtual == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      )
                    : Flexible(
                        child: Text(
                          '0',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                    sequenciaAtual > 0 ? Colors.green : Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏅',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(
                  'Maior sequência: ',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800]),
                ),
                Text(
                  '$maiorSequencia dia${maiorSequencia == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    final isCheckin = checkins[dayStr] ?? false;
    final today = DateTime.now();
    final isHoje = isSameDay(day, DateTime(today.year, today.month, today.day));

    Color? backgroundColor;
    if (isCheckin && isHoje) {
      backgroundColor = Colors.green.shade800;
    } else if (isCheckin) {
      backgroundColor = const Color.fromARGB(255, 59, 184, 95);
    } else if (isHoje) {
      backgroundColor = Colors.redAccent;
    }

    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: (isCheckin || isHoje) ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
