import 'dart:convert';

import 'package:fitlab/perfil_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'workout_page.dart';
import 'calendario.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const CalendarioPage(),
    const WorkoutPage(),
    PerfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
        selectedItemColor: Color.fromARGB(255, 221, 64, 52),
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

class NewsArticle {
  final String title;
  final String url;
  final String urlToImage;

  NewsArticle({
    required this.title,
    required this.url,
    required this.urlToImage,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
    );
  }

  // Computa dinamicamente a categoria com base no título
  String get categoria {
    final lower = title.toLowerCase();
    if (lower.contains('academia') ||
        lower.contains('treino') ||
        lower.contains('musculação')) {
      return 'Treino';
    } else if (lower.contains('fitness') || lower.contains('dieta')) {
      return 'Fitness';
    } else {
      return 'Saúde';
    }
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final List<String> inscricoes = [];
  List<NewsArticle> _news = [];
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    _carregarInscricoes();
    _buscarNoticias();
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

    await FirebaseFirestore.instance
        .collection('inscricoes')
        .doc(uid)
        .set({'aulas': inscricoes});
  }

  void _inscrever(String aula) {
    if (!inscricoes.contains(aula)) {
      setState(() {
        inscricoes.add(aula);
      });
      _salvarInscricoes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Você se inscreveu na aula "$aula".')),
      );
    }
  }

  void _desinscrever(String aula) {
    if (inscricoes.contains(aula)) {
      setState(() {
        inscricoes.remove(aula);
      });
      _salvarInscricoes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Você se desinscreveu da aula "$aula".')),
      );
    }
  }

  void _mostrarInscricoes() {
    if (!mounted) return; // <-- verificar antes de chamar o diálogo
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Minhas Inscrições'),
        content: SizedBox(
          width: double.maxFinite,
          child: inscricoes.isEmpty
              ? const Text('Você não está inscrito em nenhuma aula.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: inscricoes.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(inscricoes[index]),
                    leading: const Icon(Icons.check_circle,
                        color: Color.fromARGB(255, 221, 64, 52)),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'), // Só o child aqui, sem if
          ),
        ],
      ),
    );
  }

  Future<void> _buscarNoticias() async {
    const apiKey = '70a301e794134e829d1dea59ab09bf71';
    const url =
        'https://newsapi.org/v2/everything?q=(fitness OR gym OR academia OR treino OR musculação)&language=pt&sortBy=publishedAt&pageSize=10&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> articles = jsonData['articles'] ?? [];

        setState(() {
          _news = articles.map((json) => NewsArticle.fromJson(json)).toList();
          _loadingNews = false;
        });
      } else {
        setState(() => _loadingNews = false);
        debugPrint('Erro ao buscar notícias: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadingNews = false);
      debugPrint('Erro na requisição: $e');
    }
  }

  Future<void> _refreshNews() async {
    setState(() => _loadingNews = true);
    await _buscarNoticias();
  }

  void _abrirNoticia(String url) async {
    try {
      final cleanedUrl = url.trim(); // Remove espaços no início/fim
      final uri = Uri.parse(cleanedUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    } catch (e) {
      // Se a URL for inválida, evita o crash e mostra erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL inválida: $e')),
      );
    }
  }

  Widget _newsCard(NewsArticle article) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(left: 16, bottom: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirNoticia(article.url),
        splashColor: Colors.red.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: article.urlToImage.isNotEmpty
                      ? Image.network(
                          article.urlToImage,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey),
                        ),
                ),

                // Badge de categoria dinâmica
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 221, 64, 52),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.categoria,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 20, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 221, 64, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                onPressed: () => _abrirNoticia(article.url),
                child: const Text(
                  'Leia mais',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classCard(String hour, String title, String imagePath) {
    final isSubscribed = inscricoes.contains(title);
    return Container(
      width: 180,
      height: 300,
      margin: const EdgeInsets.only(left: 16, bottom: 16, top: 8),
      decoration: BoxDecoration(
        color: isSubscribed ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isSubscribed) _inscrever(title);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(hour, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubscribed
                        ? Color.fromARGB(255, 221, 64, 52)
                        : Color.fromARGB(255, 221, 64, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size.fromHeight(40),
                    elevation: 5,
                  ),
                  onPressed: () {
                    if (isSubscribed) {
                      _desinscrever(title);
                    } else {
                      _inscrever(title);
                    }
                  },
                  child: Text(
                    isSubscribed ? 'Desinscrever' : 'Inscreva-se',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshNews,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho com título e botão
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FitLab',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.black,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _mostrarInscricoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 221, 64, 52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Minhas aulas',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Notícias sobre Saúde e Academia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              // Conteúdo notícias
              if (_loadingNews)
                const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 221, 64, 52),
                        strokeWidth: 4),
                  ),
                )
              else if (_news.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Text(
                    'Nenhuma notícia disponível no momento.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              else
                SizedBox(
                  height: 330,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _news.length,
                    itemBuilder: (context, index) => _newsCard(_news[index]),
                  ),
                ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Aulas Coletivas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              // Lista de Aulas Coletivas
              SizedBox(
                height: 230,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _classCard('10h30', 'FitDance', 'assets/img1.png'),
                    _classCard('11h00', 'Spinning', 'assets/img2.png'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
