import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class PerfilPage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  PerfilPage({super.key});

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
            body: const Center(child: Text('Dados do usuário não encontrados.')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        final totalCheckins = userData['totalCheckinsMes'] ?? 0;
        final meta = userData['metaMensal'] ?? 0;
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
          body: Padding(
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
                Text(userData['nome'] ?? '',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
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
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _confirmarLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
