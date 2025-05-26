import 'package:flutter/material.dart';

class Cadastro extends StatelessWidget {
  const Cadastro({super.key});

  OutlineInputBorder _borda() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.purple),
    );
  }

  ButtonStyle _buttonStyle() {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.hovered)) {
          return Colors.purple.shade400;
        }
        return const Color(0xff190017);
      }),
      foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.hovered)) {
          return Colors.white;
        }
        return Colors.white;
      }),
      shadowColor: MaterialStateProperty.all(Colors.purple),
      elevation: MaterialStateProperty.all(10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'FitLab',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Cadastro',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
                const Text('Nome Completo', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Insira seu nome',
                    border: _borda(),
                    focusedBorder: _borda(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text('E-mail', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'login@gmail.com',
                    border: _borda(),
                    focusedBorder: _borda(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data de Nascimento',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'dd/mm/aa',
                    border: _borda(),
                    focusedBorder: _borda(),
                  ),
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text('Insira sua senha', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: '********',
                    border: _borda(),
                    focusedBorder: _borda(),
                  ),
                  obscureText: true,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text('Repita sua senha', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: '********',
                    border: _borda(),
                    focusedBorder: _borda(),
                  ),
                  obscureText: true,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: _buttonStyle(),
                    onPressed: () {},
                    child: const Text(
                      'Cadastrar-se',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
