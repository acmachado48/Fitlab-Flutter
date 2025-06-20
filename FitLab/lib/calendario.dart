import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, bool> checkins =
      {}; // mapa data 'yyyy-MM-dd' -> check-in (true/false)
  User? user = FirebaseAuth.instance.currentUser;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarCheckinsMes();
  }

  Future<void> _carregarCheckinsMes() async {
    if (user == null) return;

    setState(() => loading = true);

    final uid = user!.uid;
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    // Datas formatadas para consulta
    final inicioStr = DateFormat('yyyy-MM-dd').format(monthStart);
    final fimStr = DateFormat('yyyy-MM-dd').format(monthEnd);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('checkins')
        .where('date', isGreaterThanOrEqualTo: inicioStr)
        .where('date', isLessThanOrEqualTo: fimStr)
        .get();

    final Map<String, bool> dados = {};
    for (var doc in snapshot.docs) {
      final date = doc['date'] as String;
      final checkin = doc['checked'] as bool? ?? false;
      dados[date] = checkin;
    }

    setState(() {
      checkins = dados;
      loading = false;
    });
  }

  Future<void> _toggleCheckin(DateTime dia) async {
    if (user == null) return;

    final uid = user!.uid;
    final diaStr = DateFormat('yyyy-MM-dd').format(dia);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('checkins')
        .doc(diaStr);

    final estaCheckin = checkins[diaStr] ?? false;
    final novoStatus = !estaCheckin;

    await docRef.set({
      'date': diaStr,
      'checked': novoStatus,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      checkins[diaStr] = novoStatus;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta);
    });
    _carregarCheckinsMes();
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Check-ins'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => _changeMonth(-1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    DateFormat.yMMMM().format(selectedMonth),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, // 7 dias da semana
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, index) {
                      final dia = index + 1;
                      final date = DateTime(
                          selectedMonth.year, selectedMonth.month, dia);
                      final dateStr = DateFormat('yyyy-MM-dd').format(date);
                      final checkinFeito = checkins[dateStr] ?? false;

                      return GestureDetector(
                        onTap: () => _toggleCheckin(date),
                        child: Container(
                          decoration: BoxDecoration(
                            color: checkinFeito
                                ? Colors.green
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dia.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: checkinFeito
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              if (checkinFeito)
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Toque em um dia para marcar/desmarcar check-in.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
    );
  }
}
