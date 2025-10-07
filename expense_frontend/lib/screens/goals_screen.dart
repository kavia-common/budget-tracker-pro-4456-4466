import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/client.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool loading = true;
  String? error;
  List<dynamic> goals = [];

  final nameCtrl = TextEditingController();
  final targetCtrl = TextEditingController();

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient().getJson('/goals');
      if (!mounted) return;
      setState(() => goals = (res as List?) ?? []);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final target = num.tryParse(targetCtrl.text);
    if ((nameCtrl.text).isEmpty || target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter name and valid target')),
      );
      return;
    }
    try {
      await ApiClient().postJson('/goals', {
        'name': nameCtrl.text.trim(),
        'target': target,
      });
      nameCtrl.clear();
      targetCtrl.clear();
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
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Goal name'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target amount'),
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
                        itemCount: goals.length,
                        itemBuilder: (ctx, i) {
                          final g = goals[i] as Map? ?? {};
                          final target = g['target'] as num? ?? 0;
                          final saved = g['saved'] as num? ?? 0;
                          return Card(
                            child: ListTile(
                              title: Text('${g['name'] ?? 'Goal'}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: target == 0
                                        ? 0
                                        : (saved / target).clamp(0, 1).toDouble(),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Saved: ${_money(saved)} / ${_money(target)}'),
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
