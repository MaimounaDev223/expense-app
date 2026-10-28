import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';


class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/categories'),
    );
    final List<dynamic> data = jsonDecode(response.body);
    if (!mounted) return;
    setState(() {
      _categories = data;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/expenses'),
      headers: await authHeaders(),
      body: jsonEncode({
        'category_id': _selectedCategoryId,
        'amount': _amountController.text,
        'description': _descriptionController.text,
        'spent_at': DateTime.now().toIso8601String(),
      }),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dépense enregistrée')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : vérifiez le montant')),
      );
      debugPrint('Erreur ${response.statusCode} : ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle dépense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: _categories
                  .map<DropdownMenuItem<int>>(
                    (category) => DropdownMenuItem<int>(
                      value: category['id'] as int,
                      child: Text(category['name']),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Envoi...' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}