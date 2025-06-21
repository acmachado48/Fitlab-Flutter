import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'login.dart';

class PerfilPage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  PerfilPage({super.key});

  Future<void> _editarNome(
      BuildContext context, Map<String, dynamic> userData) async {
    final controller = TextEditingController(text: userData['nome'] ?? '');
    String? errorText;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> salvar() async {
              final novoNome = controller.text.trim();

              // Validação
              if (novoNome.isEmpty) {
                setState(() => errorText = 'Informe um nome válido');
                return;
              }
              if (novoNome.length < 3) {
                setState(
                    () => errorText = 'Nome muito curto (mínimo 3 caracteres)');
                return;
              }
              if (novoNome.length > 30) {
                setState(() =>
                    errorText = 'Nome muito longo (máximo 30 caracteres)');
                return;
              }
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário não está logado')),
                );
                return;
              }

              setState(() {
                errorText = null;
                isLoading = true;
              });

              try {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user!.uid)
                    .update({'nome': novoNome});
                Navigator.pop(context);
              } catch (e) {
                setState(() {
                  isLoading = false;
                  errorText = 'Erro ao salvar nome: $e';
                });
              }
            }

            return AlertDialog(
              title: const Text('Editar nome'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Novo nome',
                  errorText: errorText,
                ),
                enabled: !isLoading,
                autofocus: true,
                onChanged: (_) {
                  if (errorText != null) {
                    setState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : salvar,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editarMetaMensal(
      BuildContext context, Map<String, dynamic> userData) async {
    final controller = TextEditingController(
      text: userData['metaMensal']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar meta mensal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nova meta (dias)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novaMeta = int.tryParse(controller.text.trim());
              if (novaMeta == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe um número válido')),
                );
                return;
              }
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário não está logado')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user!.uid)
                    .update({'metaMensal': novaMeta});
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao salvar meta: $e')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Login()),
                (route) => false,
              );
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getCheckinsPorMes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final Map<String, int> dados = {};

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('checkins')
        .orderBy('date')
        .get();

    for (var doc in snapshot.docs) {
      if ((doc['checked'] ?? false) == true) {
        try {
          final date = DateTime.parse(doc['date']);
          final key = DateFormat('yyyy-MM').format(date); // ex: "2025-06"
          dados[key] = (dados[key] ?? 0) + 1;
        } catch (e) {
          print('Erro ao converter data: ${doc['date']}');
        }
      }
    }

    return dados;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('Nenhum usuário logado.')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil')),
            body:
                const Center(child: Text('Dados do usuário não encontrados.')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        final totalCheckins = userData['totalCheckinsMes'] ?? 0;
        final meta = userData['metaMensal'] ?? 30;
        final progresso =
            meta == 0 ? 0.0 : (totalCheckins / meta).clamp(0.0, 1.0);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Perfil'),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            actions: [
              IconButton(
                onPressed: () => _confirmarLogout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'Sair',
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    userData['nome']?[0].toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 32, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 16),

                // Nome com botão de editar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userData['nome'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Editar nome',
                      onPressed: () => _editarNome(context, userData),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Text(userData['email'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const Divider(height: 32),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.cake, color: Colors.pink),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nascimento',
                                style: TextStyle(color: Colors.grey)),
                            Text(userData['nascimento'] ?? 'Não informado',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Meta mensal',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _editarMetaMensal(context, userData),
                              tooltip: 'Editar meta',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Meta: $meta dias'),
                        Text('Check‑ins: $totalCheckins dias'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progresso,
                          backgroundColor: Colors.grey[300],
                          color: Colors.green,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Progresso: ${(progresso * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // GRÁFICO DE BARRAS
                FutureBuilder<Map<String, int>>(
                  future: _getCheckinsPorMes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('Nenhum check-in registrado.'),
                        ),
                      );
                    }

                    final meses = data.keys.toList()..sort();
                    final valores = data.values.toList();

                    final metaMensal =
                        (userData['metaMensal'] ?? 30).toDouble();

                    return Container(
                      height: 280,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (metaMensal > 0 ? metaMensal : 30) + 5,
                          barGroups: List.generate(meses.length, (i) {
                            final progressoMes = valores[i].toDouble();
                            return BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: progressoMes,
                                color: progressoMes >= metaMensal
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: (metaMensal > 0 ? metaMensal : 30) + 5,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ]);
                          }),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= meses.length)
                                    return const SizedBox.shrink();
                                  final mes = meses[index];
                                  try {
                                    final date =
                                        DateFormat('yyyy-MM').parse(mes);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        DateFormat.MMM('pt_BR').format(date),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87),
                                      ),
                                    );
                                  } catch (e) {
                                    return const Text('?');
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 5,
                                getTitlesWidget: (value, meta) {
                                  if (value % 5 != 0)
                                    return const SizedBox.shrink();
                                  return Text(
                                    value.toInt().toString(),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                          ),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.blueGrey.shade700,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final mes = meses[group.x.toInt()];
                                final valor = rod.toY.toInt();
                                return BarTooltipItem(
                                  '$mes\n',
                                  const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: '$valor dias',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarLogout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair da conta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
