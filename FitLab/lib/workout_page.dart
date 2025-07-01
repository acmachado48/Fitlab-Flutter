import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'workout_timer_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class ExerciseSearch extends SearchDelegate<Map<String, String>?> {
  @override
  String get searchFieldLabel => 'Buscar exercício...';

  Future<List<Map<String, String>>> fetchExercises(String query) async {
    const headers = {
      'x-rapidapi-host': 'exercisedb.p.rapidapi.com',
      'x-rapidapi-key': '53f6945e8emshde297b41f425b3dp1f2a91jsn919d691f472e',
    };

    final url = 'https://exercisedb.p.rapidapi.com/exercises/name/$query';

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<Map<String, String>>((e) {
          return {
            'name': e['name'] ?? '',
            'weight': '',
            'series': '3x10',
            'image': e['gifUrl'] ?? '',
          };
        }).toList();
      } else {
        debugPrint('Erro na resposta da API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Erro ao buscar exercícios: $e');
      return [];
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) return const Center(child: Text('Digite para buscar'));

    return FutureBuilder<List<Map<String, String>>>(
      future: fetchExercises(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum exercício encontrado'));
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final exercise = results[index];
            return ListTile(
              leading:
                  (exercise['image'] != null && exercise['image']!.isNotEmpty)
                      ? Image.network(
                          exercise['image']!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, ___) {
                            debugPrint('Erro ao carregar imagem: $error');
                            return const Icon(Icons.fitness_center);
                          },
                        )
                      : const Icon(Icons.fitness_center),
              title: Text(exercise['name'] ?? ''),
              onTap: () => close(context, exercise),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
}

class _WorkoutPageState extends State<WorkoutPage> {
  final Map<String, List<Map<String, String>>> fichas = {};
  String fichaSelecionada = '';

  final nomeController = TextEditingController();
  final pesoController = TextEditingController();
  final seriesController = TextEditingController();
  final novaFichaController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    carregarFichasFirestore();
  }

  Future<void> salvarFichasFirestore() async {
    if (user == null) return;
    final uid = user!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final fichasRef = userDoc.collection('fichas');

    // Apaga fichas antigas
    final oldFichas = await fichasRef.get();
    for (final doc in oldFichas.docs) {
      await doc.reference.delete();
    }

    // Cria fichas novas
    for (var entry in fichas.entries) {
      await fichasRef.doc(entry.key).set({
        'name': entry.key,
        'exercicios': entry.value,
      });
    }
  }

  Future<void> carregarFichasFirestore() async {
    if (user == null) return;
    final uid = user!.uid;
    final fichasSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fichas')
        .get();

    Map<String, List<Map<String, String>>> fichasTemporarias = {};

    for (final doc in fichasSnapshot.docs) {
      final nome = doc['name'];
      final exercicios =
          (doc['exercicios'] as List).map<Map<String, String>>((e) {
        final map = Map<String, String>.from(e);
        return map;
      }).toList();

      fichasTemporarias[nome] = exercicios;
    }

    // Agora atualizar URLs expiradas/invalidas
    bool precisaSalvar = false;
    for (final entry in fichasTemporarias.entries) {
      final listaExercicios = entry.value;
      for (var i = 0; i < listaExercicios.length; i++) {
        final exercicio = listaExercicios[i];
        final imageUrl = exercicio['image'] ?? '';

        if (!_urlValida(imageUrl)) {
          final resultados =
              await ExerciseSearch().fetchExercises(exercicio['name'] ?? '');
          if (resultados.isNotEmpty) {
            exercicio['image'] = resultados.first['image'] ?? '';
            precisaSalvar = true;
          } else {
            exercicio['image'] = 'https://via.placeholder.com/60';
          }
        }
      }
    }

    setState(() {
      fichas.clear();
      fichas.addAll(fichasTemporarias);
      fichaSelecionada = fichas.keys.isNotEmpty ? fichas.keys.first : 'Ficha A';
    });

    if (precisaSalvar) {
      await salvarFichasFirestore();
    }
  }

  bool _urlValida(String url) {
    if (url.isEmpty) return false;
    if (url.contains('not_found') || url.contains('expired')) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!uri.hasAbsolutePath) return false;

    return true;
  }

  void _adicionarFicha() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova ficha'),
        content: TextField(
          controller: novaFichaController,
          decoration: const InputDecoration(labelText: 'Nome da ficha'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final nomeFicha = novaFichaController.text.trim();
              if (nomeFicha.isNotEmpty && !fichas.containsKey(nomeFicha)) {
                setState(() {
                  fichas[nomeFicha] = [];
                  fichaSelecionada = nomeFicha;
                  novaFichaController.clear();
                });
                salvarFichasFirestore();
              }
              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          )
        ],
      ),
    );
  }

  void _editarExercicio(int index) {
    final currentList = fichas[fichaSelecionada]!;
    nomeController.text = currentList[index]['name'] ?? '';
    pesoController.text = currentList[index]['weight'] ?? '';
    seriesController.text = currentList[index]['series'] ?? '';

    _mostrarDialogo(index: index);
  }

  void _mostrarDialogo({int? index}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Adicionar Exercício' : 'Editar Exercício'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome')),
              TextField(
                  controller: pesoController,
                  decoration: const InputDecoration(labelText: 'Peso')),
              TextField(
                  controller: seriesController,
                  decoration: const InputDecoration(labelText: 'Séries')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final exercicio = {
                'name': nomeController.text,
                'weight': pesoController.text,
                'series': seriesController.text,
                'image': index != null
                    ? fichas[fichaSelecionada]![index]['image'] ?? ''
                    : nomeController.text.isNotEmpty
                        ? 'https://via.placeholder.com/60'
                        : '',
              };
              setState(() {
                if (index == null) {
                  fichas[fichaSelecionada]!.add(exercicio);
                } else {
                  fichas[fichaSelecionada]![index] = exercicio;
                }
              });
              salvarFichasFirestore();
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _adicionarExercicio() async {
    final result = await showSearch<Map<String, String>?>(
      context: context,
      delegate: ExerciseSearch(),
    );

    if (result != null) {
      setState(() {
        fichas[fichaSelecionada]?.add(result);
      });
      salvarFichasFirestore();
    }
  }

  void _excluirExercicio(int index) {
    setState(() => fichas[fichaSelecionada]?.removeAt(index));
    salvarFichasFirestore();
  }

  void _editarFicha() {
    novaFichaController.text = fichaSelecionada;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nome da ficha'),
        content: TextField(
          controller: novaFichaController,
          decoration: const InputDecoration(labelText: 'Novo nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final novoNome = novaFichaController.text.trim();
              if (novoNome.isNotEmpty &&
                  novoNome != fichaSelecionada &&
                  !fichas.containsKey(novoNome)) {
                setState(() {
                  final exercicios = fichas.remove(fichaSelecionada)!;
                  fichas[novoNome] = exercicios;
                  fichaSelecionada = novoNome;
                  novaFichaController.clear();
                });
                salvarFichasFirestore();
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _excluirFicha() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ficha'),
        content: Text('Tem certeza que deseja excluir "$fichaSelecionada"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                fichas.remove(fichaSelecionada);
                fichaSelecionada =
                    fichas.isNotEmpty ? fichas.keys.first : 'Ficha A';
                if (!fichas.containsKey(fichaSelecionada)) {
                  fichas[fichaSelecionada] = [];
                }
              });
              salvarFichasFirestore();
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    pesoController.dispose();
    seriesController.dispose();
    novaFichaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listaExercicios = fichas[fichaSelecionada] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitLab'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(onPressed: _adicionarFicha, icon: const Icon(Icons.add))
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: fichaSelecionada,
                onChanged: (nova) {
                  if (nova != null) setState(() => fichaSelecionada = nova);
                },
                items: fichas.keys
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'editar') _editarFicha();
                  if (value == 'excluir') _excluirFicha();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar Ficha')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir Ficha')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: listaExercicios.length,
              itemBuilder: (context, index) {
                final e = listaExercicios[index];
                return ListTile(
                  leading: (e['image'] != null && e['image']!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            e['image']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fitness_center),
                          ),
                        )
                      : const Icon(Icons.fitness_center),
                  title: Text(e['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${e['series']} ${e['weight']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'Editar') _editarExercicio(index);
                      if (val == 'Excluir') _excluirExercicio(index);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'Editar', child: Text('Editar')),
                      PopupMenuItem(value: 'Excluir', child: Text('Excluir')),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WorkoutTimerPage()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Iniciar',
              style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarExercicio,
        backgroundColor: Colors.black,
        child: const Text('+',
            style: TextStyle(fontSize: 30, color: Colors.white)),
      ),
    );
  }
}
