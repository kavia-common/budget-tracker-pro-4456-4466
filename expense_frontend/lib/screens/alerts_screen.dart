import 'package:flutter/material.dart';
import '../api/client.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool loading = true;
  String? error;
  List<dynamic> alerts = [];

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiClient().getJson('/alerts');
      if (!mounted) return;
      setState(() => alerts = (res as List?) ?? []);
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: alerts.length,
        itemBuilder: (ctx, i) {
          final a = alerts[i] as Map? ?? {};
          return ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text('${a['title'] ?? 'Alert'}'),
            subtitle: Text('${a['message'] ?? ''}'),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
      ),
    );
  }
}
