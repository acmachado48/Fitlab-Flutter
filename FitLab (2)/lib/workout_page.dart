import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  bool isFichaASelected = true;

  List<Map<String, String>> fichaA = [
    {
      'name': 'LegPress 45°',
      'weight': '25kg',
      'series': '3×15',
      'image': 'assets/LegPress.jpg',
    },
    {
      'name': 'Banco Adutor',
      'weight': '34kg',
      'series': '3×15',
      'image': 'assets/abdutora.jpg',
    },
    {
      'name': 'Abdominal Oblíquo',
      'weight': '',
      'series': '3×22',
      'image': 'assets/abdominal.jpg',
    },
  ];

  List<Map<String, String>> fichaB = [
    {
      'name': 'Crucifixo',
      'weight': '4kg',
      'series': '3×15',
      'image': 'assets/crucifixo.jpg',
    },
    {
      'name': 'Tríceps Testa',
      'weight': '8kg',
      'series': '3×15',
      'image': 'assets/triceps.jpg',
    },
    {
      'name': 'Elíptico',
      'weight': '',
      'series': '30min',
      'image': 'assets/Eliptico.jpg',
    },
  ];

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController seriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarExercicios();
  }

  Future<void> _carregarExercicios() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('treinos').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        fichaA = List<Map<String, String>>.from(data['fichaA'] ?? fichaA);
        fichaB = List<Map<String, String>>.from(data['fichaB'] ?? fichaB);
      });
    }
  }

  Future<void> _salvarExercicios() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('treinos').doc(uid).set({
      'fichaA': fichaA,
      'fichaB': fichaB,
    });
  }

  void _mostrarDialogoAdicionarOuEditar({int? editIndex}) {
    final currentList = isFichaASelected ? fichaA : fichaB;

    if (editIndex != null) {
      nomeController.text = currentList[editIndex]['name'] ?? '';
      pesoController.text = currentList[editIndex]['weight'] ?? '';
      seriesController.text = currentList[editIndex]['series'] ?? '';
    } else {
      nomeController.clear();
      pesoController.clear();
      seriesController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            editIndex == null ? 'Adicionar Exercício' : 'Editar Exercício'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                decoration:
                    const InputDecoration(labelText: 'Nome do exercício'),
              ),
              TextField(
                controller: pesoController,
                decoration: const InputDecoration(labelText: 'Peso (opcional)'),
              ),
              TextField(
                controller: seriesController,
                decoration:
                    const InputDecoration(labelText: 'Séries e repetições'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty || seriesController.text.isEmpty)
                return;
              setState(() {
                final novoExercicio = {
                  'name': nomeController.text,
                  'weight': pesoController.text,
                  'series': seriesController.text,
                  'image': editIndex != null
                      ? currentList[editIndex]['image'] ?? 'assets/default.jpg'
                      : 'assets/default.jpg',
                };
                if (editIndex == null) {
                  currentList.add(novoExercicio);
                } else {
                  currentList[editIndex] = novoExercicio;
                }
              });
              _salvarExercicios();
              Navigator.of(context).pop();
            },
            child: Text(editIndex == null ? 'Adicionar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  void _adicionarExercicio() => _mostrarDialogoAdicionarOuEditar();
  void _editarExercicio(int index) =>
      _mostrarDialogoAdicionarOuEditar(editIndex: index);

  void _excluirExercicio(int index) {
    setState(() {
      if (isFichaASelected) {
        fichaA.removeAt(index);
      } else {
        fichaB.removeAt(index);
      }
    });
    _salvarExercicios();
  }

  @override
  void dispose() {
    nomeController.dispose();
    pesoController.dispose();
    seriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentList = isFichaASelected ? fichaA : fichaB;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitLab'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => isFichaASelected = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFichaASelected ? Colors.black : Colors.white,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Ficha A',
                  style: TextStyle(
                    color: isFichaASelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => setState(() => isFichaASelected = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !isFichaASelected ? Colors.black : Colors.white,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Ficha B',
                  style: TextStyle(
                    color: !isFichaASelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                final exercise = currentList[index];
                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            exercise['image'] ?? 'assets/default.jpg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: Text(exercise['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${exercise['series'] ?? ''} ${exercise['weight'] ?? ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Editar') {
                        _editarExercicio(index);
                      } else if (value == 'Excluir') {
                        _excluirExercicio(index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'Editar', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'Excluir', child: Text('Excluir')),
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
          onPressed: () {},
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
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30)),
      ),
    );
  }
}
