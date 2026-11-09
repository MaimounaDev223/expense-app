import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'token_storage.dart';

class RegisterPage extends StatefulWidget {
  final Widget nextPage;

  const RegisterPage({super.key, required this.nextPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

Future<void> _register() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await TokenStorage.save(data['token']);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => widget.nextPage),
        (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        _error =
            'Vérifiez vos informations : mot de passe de 8 caractères minimum, e-mail non utilisé';
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = "Serveur injoignable. Vérifiez que l'API est lancée.";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: Text(_isLoading ? 'Inscription...' : 'S\'inscrire'),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RegisterPage(nextPage: widget.nextPage),
                  ),
                );
              },
              child: const Text('Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}
