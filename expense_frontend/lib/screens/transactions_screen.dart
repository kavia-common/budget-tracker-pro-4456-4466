import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/client.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool loading = true;
  String? error;
  List<dynamic> txs = [];

  final descCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient().getJson('/transactions');
      if (!mounted) return;
      setState(() => txs = (res as List?) ?? []);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final amount = num.tryParse(amountCtrl.text);
    if ((descCtrl.text).isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter description and valid amount')),
      );
      return;
    }
    try {
      await ApiClient().postJson('/transactions', {
        'description': descCtrl.text.trim(),
        'amount': amount,
        'category': categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
      });
      descCtrl.clear();
      amountCtrl.clear();
      categoryCtrl.clear();
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
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
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Category (optional)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _create, child: const Text('Add')),
                ]),
              ],
            ),
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
                        itemCount: txs.length,
                        itemBuilder: (ctx, i) {
                          final t = txs[i] as Map? ?? {};
                          final amt = t['amount'] as num?;
                          final isExpense = (amt ?? 0) < 0;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isExpense ? Colors.red.withOpacity(.15) : Colors.green.withOpacity(.15),
                                child: Icon(isExpense ? Icons.south_west : Icons.north_east,
                                    color: isExpense ? Colors.red : Colors.green),
                              ),
                              title: Text('${t['description'] ?? 'Transaction'}'),
                              subtitle: Text('${t['category'] ?? 'Uncategorized'}'),
                              trailing: Text(
                                _money(amt),
                                style: TextStyle(
                                  color: isExpense ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
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
