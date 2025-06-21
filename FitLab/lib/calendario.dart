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

  @override
  void initState() {
    super.initState();
    _carregarCheckinsMes(focusedDay);
  }

  Future<void> _carregarCheckinsMes(DateTime mes) async {
    if (user == null) return;

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
    });
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

    _carregarCheckinsMes(focusedDay);

    await _atualizarTotalCheckinsMes();
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
        title: const Text('Calendário de Check-ins'),
        centerTitle: true,
      ),
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
                color: Colors.transparent, // não pintar por padrão
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => _buildDayCell(day),
              todayBuilder: (context, day, _) => _buildDayCell(day),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Check-ins do mês: ${checkins.values.where((e) => e).length}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
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
