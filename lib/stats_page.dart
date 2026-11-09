import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<dynamic> _stats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://127.0.0.1:8000/api/stats/categories'),
            headers: await authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Impossible de charger les statistiques';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Serveur injoignable. Vérifiez que l'API est lancée.";
        _isLoading = false;
      });
    }
  }

  double get _grandTotal {
    double sum = 0;
    for (final item in _stats) {
      sum += (item['total'] as num).toDouble();
    }
    return sum;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_stats.isEmpty) {
      return const Center(child: Text('Aucune dépense pour le moment'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stats.length,
      itemBuilder: (context, index) {
        final item = _stats[index];
        final total = (item['total'] as num).toDouble();
        final share = _grandTotal == 0 ? 0.0 : total / _grandTotal;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['category'], style: const TextStyle(fontSize: 16)),
                  Text(
                    '${total.toStringAsFixed(0)}  (${(share * 100).toStringAsFixed(0)} %)',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: share, minHeight: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: _buildBody(),
    );
  }
}