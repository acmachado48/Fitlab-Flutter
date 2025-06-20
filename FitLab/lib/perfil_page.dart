import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userData = doc.data();
        loading = false;
      });
    } else {
      setState(() {
        userData = null;
        loading = false;
      });
    }
  }

  Future<int> _contarCheckInsDoMes() async {
    final uid = user?.uid;
    if (uid == null) return 0;

    final now = DateTime.now();
    final mes = now.month.toString().padLeft(2, '0');
    final ano = now.year;
    final inicio = '$ano-$mes-01';
    final fim = '$ano-$mes-31';

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('checkins')
        .where('date', isGreaterThanOrEqualTo: inicio)
        .where('date', isLessThanOrEqualTo: fim)
        .get();

    return snapshot.docs.length;
  }

  Future<void> _editarMetaMensal() async {
    final controller = TextEditingController(
      text: userData?['metaMensal']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar meta mensal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nova meta (número de dias)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novaMeta = int.tryParse(controller.text.trim());
              if (novaMeta != null && user != null) {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user!.uid)
                    .update({'metaMensal': novaMeta});
                await _carregarDadosUsuario();
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null || userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(
          child: Text('Nenhum usuário logado.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sair',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(userData!['nome'] ?? 'Não informado',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Email:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(userData!['email'] ?? user!.email ?? 'Não informado',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Data de nascimento:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(userData!['nascimento'] ?? 'Não informado',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Meta mensal + check-ins
            FutureBuilder<int>(
              future: _contarCheckInsDoMes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final totalCheckins = snapshot.data!;
                final meta = userData?['metaMensal'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Meta do mês: $meta dias',
                              style: Theme.of(context).textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Editar meta',
                            onPressed: _editarMetaMensal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Check-ins realizados: $totalCheckins dias',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sair', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
