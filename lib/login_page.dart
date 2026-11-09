import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'token_storage.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final Widget nextPage;

  const LoginPage({super.key, required this.nextPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}



class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

 @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': _emailController.text,
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await TokenStorage.save(data['token']);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.nextPage),
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = 'E-mail ou mot de passe incorrect';
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
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
              onPressed: _isLoading ? null : _login,
              child: Text(_isLoading ? 'Connexion...' : 'Se connecter'),
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
