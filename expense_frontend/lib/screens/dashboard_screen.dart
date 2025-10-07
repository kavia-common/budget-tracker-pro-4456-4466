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

  String _money(num? n) => NumberFormat.currency(symbol: '\$').format(n ?? 0);

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final totalIncome = data?['totalIncome'] as num? ?? data?['income'] as num? ?? 0;
    final totalExpense = data?['totalExpense'] as num? ?? data?['expense'] as num? ?? 0;
    final budgets = (data?['budgets'] as List?) ?? [];
    final topCats = (data?['topCategories'] as List?) ?? [];
    final last6 = (data?['last6Months'] as List?) ?? [];

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
              _metricCard('Net', _money((totalIncome) - (totalExpense)), Icons.paid, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Text('Top Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final c in topCats)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text('${c['category']}')),
                          Text(_money(c['amount'] as num?)),
                        ],
                      ),
                    ),
                  if (topCats.isEmpty) const Text('No category expenses yet'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Last 6 Months', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _BarChart(series: last6.map<Map<String, num>>((e) {
            return {
              'income': (e['income'] as num?) ?? 0,
              'expense': (e['expense'] as num?) ?? 0,
              'net': (e['net'] as num?) ?? 0,
              'month': (e['month'] as num?) ?? 0,
              'year': (e['year'] as num?) ?? 0,
            };
          }).toList()),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<Map<String, num>> series;
  const _BarChart({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return Card(
        child: SizedBox(
          height: 160,
          child: Center(child: Text('No data', style: Theme.of(context).textTheme.bodyMedium)),
        ),
      );
    }
    final maxVal = series
        .map((e) => (e['income'] ?? 0) > (e['expense'] ?? 0) ? (e['income'] ?? 0) : (e['expense'] ?? 0))
        .fold<num>(0, (p, e) => e > p ? e : p);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final e in series)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // income bar
                      _bar(heightFrac: _safeDiv(e['income'] ?? 0, maxVal), color: Colors.green),
                      const SizedBox(height: 6),
                      // expense bar
                      _bar(heightFrac: _safeDiv(e['expense'] ?? 0, maxVal), color: Colors.red),
                      const SizedBox(height: 6),
                      Text(_monthLabel(e['month']?.toInt() ?? 0),
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthLabel(int m) {
    const labels = ['', 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    if (m < 1 || m > 12) return '?';
    return labels[m];
  }

  double _safeDiv(num a, num b) {
    if (b == 0) return 0;
    final v = (a / b).clamp(0, 1).toDouble();
    return v.isFinite ? v : 0;
  }

  Widget _bar({required double heightFrac, required Color color}) {
    return Expanded(
      flex: (heightFrac * 1000).round().clamp(1, 1000),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(.7),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
