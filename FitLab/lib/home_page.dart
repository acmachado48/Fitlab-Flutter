import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_page.dart';
import 'calendario.dart';
import 'login.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const Calendario(),
    const WorkoutPage(),
    const Login(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendário'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

ButtonStyle customButtonStyle() {
  return ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.hovered)) {
        return Colors.purple.shade400;
      }
      return const Color(0xff190017);
    }),
    foregroundColor: MaterialStateProperty.all(Colors.white),
    shadowColor: MaterialStateProperty.all(Colors.purple),
    elevation: MaterialStateProperty.all(10),
    padding:
        MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final List<String> inscricoes = [];

  @override
  void initState() {
    super.initState();
    _carregarInscricoes();
  }

  Future<void> _carregarInscricoes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('inscricoes')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['aulas'] != null) {
        setState(() {
          inscricoes.clear();
          inscricoes.addAll(List<String>.from(data['aulas']));
        });
      }
    }
  }

  Future<void> _salvarInscricoes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('inscricoes').doc(uid).set({
      'aulas': inscricoes,
    });
  }

  void _inscrever(String aula) {
    if (!inscricoes.contains(aula)) {
      setState(() {
        inscricoes.add(aula);
      });

      _salvarInscricoes(); // ✅ Agora está salvando no Firestore corretamente

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Inscrição confirmada'),
            content: Text('Você se inscreveu na aula "$aula".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _mostrarInscricoes() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Minhas Inscrições'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: inscricoes
                  .map((aula) => ListTile(title: Text(aula)))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FitLab',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  ElevatedButton(
                    onPressed: _mostrarInscricoes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Minhas aulas',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Notícias',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _newsCard('Suplementação com Whey Protein na saúde',
                      'assets/img3.png'),
                  _newsCard('Mundo Fitness: alimentos que proporcionam...',
                      'assets/img4.png'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Aulas Coletivas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _classCard(
                      '10h30', 'FitDance', 'assets/img1.png', _inscrever),
                  _classCard(
                      '11h00', 'Spinning', 'assets/img2.png', _inscrever),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _newsCard(String title, String imagePath) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(imagePath,
                height: 100, width: 160, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: customButtonStyle(),
              onPressed: () {},
              child: const Text('Leia mais'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _classCard(String hour, String title, String imagePath,
      void Function(String) onSubscribe) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(imagePath,
                height: 100, width: 160, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(hour, style: const TextStyle(color: Colors.grey)),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: customButtonStyle(),
              onPressed: () => onSubscribe(title),
              child: const Text('Inscreva-se'),
            ),
          ),
        ],
      ),
    );
  }
}
