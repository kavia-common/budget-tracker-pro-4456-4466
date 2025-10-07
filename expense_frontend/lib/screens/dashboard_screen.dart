import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient().getJson('/dashboard');
      if (!mounted) return;
      setState(() => data = (res is Map<String, dynamic>) ? res : {});
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _money(num? n) {
    final f = NumberFormat.currency(symbol: '\$');
    return f.format(n ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Retry'))
          ],
        ),
      );
    }
    final totalIncome = data?['totalIncome'] as num?;
    final totalExpense = data?['totalExpense'] as num?;
    final budgets = (data?['budgets'] as List?) ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricCard('Income (Mtd)', _money(totalIncome), Icons.trending_up, Colors.green),
              _metricCard('Expense (Mtd)', _money(totalExpense), Icons.trending_down, Colors.red),
              _metricCard('Net', _money((totalIncome ?? 0) - (totalExpense ?? 0)), Icons.paid, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Text('Budgets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final b in budgets)
            Card(
              child: ListTile(
                title: Text('${b['category'] ?? 'Category'}'),
                subtitle: Text('Limit: ${_money(b['limit'])} • Spent: ${_money(b['spent'])}'),
                trailing: Text(
                  _money((b['limit'] ?? 0) - (b['spent'] ?? 0)),
                  style: TextStyle(
                    color: ((b['spent'] ?? 0) > (b['limit'] ?? 0)) ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(.15), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
