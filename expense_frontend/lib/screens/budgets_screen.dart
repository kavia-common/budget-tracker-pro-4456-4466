import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/client.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  bool loading = true;
  String? error;
  List<dynamic> budgets = [];

  final categoryCtrl = TextEditingController();
  final limitCtrl = TextEditingController();

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient().getJson('/budgets');
      if (!mounted) return;
      setState(() => budgets = (res as List?) ?? []);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final limit = num.tryParse(limitCtrl.text);
    if ((categoryCtrl.text).isEmpty || limit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter category and valid limit')),
      );
      return;
    }
    try {
      await ApiClient().postJson('/budgets', {
        'category': categoryCtrl.text.trim(),
        'limit': limit,
      });
      categoryCtrl.clear();
      limitCtrl.clear();
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _money(num? n) => NumberFormat.currency(symbol: '\$').format(n ?? 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monthly Limit'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _create, child: const Text('Add')),
            ]),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          OutlinedButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: budgets.length,
                        itemBuilder: (ctx, i) {
                          final b = budgets[i] as Map? ?? {};
                          final spent = b['spent'] as num? ?? 0;
                          final limit = b['limit'] as num? ?? 0;
                          final remaining = limit - spent;
                          return Card(
                            child: ListTile(
                              title: Text('${b['category'] ?? 'Category'}'),
                              subtitle: LinearProgressIndicator(
                                value: limit == 0 ? 0 : (spent / limit).clamp(0, 1).toDouble(),
                                minHeight: 8,
                                color: remaining < 0 ? Colors.red : Colors.green,
                                backgroundColor: Colors.grey.shade200,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Limit: ${_money(limit)}'),
                                  Text('Spent: ${_money(spent)}',
                                      style: TextStyle(
                                          color: remaining < 0 ? Colors.red : Colors.black)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
