import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AddExpensePage extends StatefulWidget {
  final Map<String, dynamic>? expense;

  const AddExpensePage({super.key, this.expense});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _amountController.text = expense['amount'].toString();
      _descriptionController.text = expense['description'] ?? '';
      _selectedCategoryId = expense['category_id'] as int?;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

    final expense = widget.expense;
    final body = jsonEncode({
      'category_id': _selectedCategoryId,
      'amount': _amountController.text,
      'description': _descriptionController.text,
      'spent_at': expense?['spent_at'] ?? DateTime.now().toIso8601String(),
    });
    final headers = await authHeaders();

    final http.Response response;
    if (expense != null) {
      response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/expenses/${expense['id']}'),
        headers: headers,
        body: body,
      );
    } else {
      response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/expenses'),
        headers: headers,
        body: body,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Dépense modifiée' : 'Dépense enregistrée',
          ),
        ),
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la dépense' : 'Nouvelle dépense'),
      ),
      body: SingleChildScrollView(
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
              initialValue: _selectedCategoryId,
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