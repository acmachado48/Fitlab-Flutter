import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CalendarioPage extends StatefulWidget {
  final void Function()? onCheckinAtualizado;

  const CalendarioPage({super.key, this.onCheckinAtualizado});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, bool> checkins = {};
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

  // intervalo do mês selecionado
  final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final monthEnd   = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  final inicioStr = DateFormat('yyyy-MM-dd').format(monthStart);
  final fimStr    = DateFormat('yyyy-MM-dd').format(monthEnd);

  // ---- consulta Firestore ----
  final snapshot = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .collection('checkins')
      .where('date', isGreaterThanOrEqualTo: inicioStr)
      .where('date', isLessThanOrEqualTo:   fimStr)
      // .where('checked', isEqualTo: true)   // ← mantenha se criar o índice
      .get();

  print('Check‑ins carregados no mês $inicioStr a $fimStr: ${snapshot.docs.length}');

  final Map<String, bool> dados = {};
  for (var doc in snapshot.docs) {
    final date    = doc['date']    as String;
    final checkin = doc['checked'] as bool? ?? false;
    dados[date]   = checkin;
  }

  setState(() {
    checkins = dados;
    loading  = false;
  });
}


  void _changeMonth(int delta) {
    setState(() {
      selectedMonth =
          DateTime(selectedMonth.year, selectedMonth.month + delta, 1);
    });
    _carregarCheckinsMes();
  }

  Future<void> _toggleCheckin(DateTime dia) async {
    if (user == null) return;

    final uid = user!.uid;
    final diaStr = DateFormat('yyyy-MM-dd').format(dia);
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
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
    print('Check‑in para $diaStr setado para $novoStatus');

    setState(() {
      checkins[diaStr] = novoStatus;
    });

    // ---------- atualiza contagem mensal ----------
    final mes = selectedMonth.month.toString().padLeft(2, '0');
    final ano = selectedMonth.year;
    final inicio = '$ano-$mes-01';
    final lastDay =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final fim = '$ano-$mes-${lastDay.toString().padLeft(2, '0')}';

    try {
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

      print('Campo totalCheckinsMes atualizado: $totalCheckinsMes');
    } catch (e) {
      print('Erro ao contar check‑ins do mês: $e');
    }

    // Recarrega o mês para garantir consistência visual
    await _carregarCheckinsMes();

    if (widget.onCheckinAtualizado != null) {
      widget.onCheckinAtualizado!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Check‑ins'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => _changeMonth(-1),
            tooltip: 'Mês anterior',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => _changeMonth(1),
            tooltip: 'Próximo mês',
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
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, index) {
                      final dia = index + 1;
                      final date = DateTime(
                          selectedMonth.year, selectedMonth.month, dia);
                      final dateStr =
                          DateFormat('yyyy-MM-dd').format(date);
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
                    'Toque em um dia para marcar/desmarcar check‑in.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
    );
  }
}
