import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'add_expense_page.dart';
import 'api_client.dart';
import 'login_page.dart';
import 'stats_page.dart';
import 'token_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: TokenStorage.read(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        const home = MyHomePage(title: 'Mes dépenses');

        if (snapshot.data != null) {
          return home;
        }
        return const LoginPage(nextPage: home);
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadExpenses() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://127.0.0.1:8000/api/expenses'),
            headers: await authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 401) {
        await TokenStorage.clear();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _expenses = data;
        });
      } else {
        debugPrint('Erreur ${response.statusCode} : ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage("Serveur injoignable. Vérifiez que l'API est lancée.");
    }
  }

  Future<void> _deleteExpense(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('http://127.0.0.1:8000/api/expenses/$id'),
            headers: await authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 204) {
        _showMessage('Dépense supprimée');
        _loadExpenses();
      } else {
        _showMessage('Erreur lors de la suppression');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage("Serveur injoignable. Vérifiez que l'API est lancée.");
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette dépense ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteExpense(id);
    }
  }

  Future<void> _logout() async {
    try {
      await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/logout'),
            headers: await authHeaders(),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Déconnexion côté serveur impossible : $e');
    }
    await TokenStorage.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  double get _total {
    double sum = 0;
    for (final expense in _expenses) {
      sum += double.parse(expense['amount'].toString());
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiques',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Total : ${_total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return ListTile(
                  title: Text(expense['description'] ?? 'Sans description'),
                  subtitle: Text(
                    expense['category']?['name'] ?? 'Sans catégorie',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(expense['amount'].toString()),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(expense['id'] as int),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddExpensePage(expense: expense),
                      ),
                    );
                    _loadExpenses();
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpensePage()),
          );
          _loadExpenses();
        },
        tooltip: 'Ajouter une dépense',
        child: const Icon(Icons.add),
      ),
    );
  }
}