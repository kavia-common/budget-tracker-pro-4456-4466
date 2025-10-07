import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'state/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/alerts_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env'); // Load .env early
  // Pre-warm shared preferences to avoid first-use latency
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root with Provider and theme
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // In mock mode AuthProvider will not require a real token
      create: (_) => AuthProvider()..initialize(),
      child: MaterialApp(
        title: 'Budget Tracker Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Home(),
      ),
    );
  }
}

// Home with tabbed navigation
class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _idx = 0;

  final _pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    GoalsScreen(),
    AlertsScreen(),
    _SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMock = (dotenv.env['USE_MOCK_DATA'] ?? 'true').toLowerCase() != 'false';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Tracker Pro'),
        actions: [
          if (isMock)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: const Text('Mock', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.orange.shade700,
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Budgets'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?['email'] ?? 'guest@example.com';
    final name = auth.user?['name'] ?? 'Guest';
    final isMock = (dotenv.env['USE_MOCK_DATA'] ?? 'true').toLowerCase() != 'false';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(name),
            subtitle: Text(email),
          ),
        ),
        const SizedBox(height: 8),
        if (!isMock)
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => context.read<AuthProvider>().logout(),
            ),
          ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Environment'),
            subtitle: Text(isMock
                ? 'Mock mode: using seeded local data'
                : 'Real mode: ${dotenv.env['API_BASE_URL'] ?? ''}'),
          ),
        ),
      ],
    );
  }
}
