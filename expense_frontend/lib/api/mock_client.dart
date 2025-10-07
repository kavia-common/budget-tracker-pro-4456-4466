import 'dart:async';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../mock/mock_data.dart';

/// MockApiClient mimics the real ApiClient but serves data from MockDB.
/// Small artificial delays emulate network latency.
class MockApiClient {
  MockApiClient._internal() {
    MockDB.instance.seedIfNeeded();
  }
  static final MockApiClient _instance = MockApiClient._internal();
  factory MockApiClient() => _instance;

  String get baseUrl {
    final envBase = dotenv.env['API_BASE_URL']?.trim();
    if (envBase != null && envBase.isNotEmpty) return envBase;
    return 'http://mock.local';
  }

  Future<T> _delay<T>(T value, {int minMs = 120, int maxMs = 280}) async {
    final rnd = Random();
    final ms = minMs + rnd.nextInt((maxMs - minMs).clamp(0, 1000));
    await Future<void>.delayed(Duration(milliseconds: ms));
    return value;
  }

  // PUBLIC_INTERFACE
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    /** Handles GET routes for mock data. */
    final now = DateTime.now();
    final db = MockDB.instance;

    switch (path) {
      case '/auth/me':
        return _delay(db.currentUser);
      case '/dashboard':
        return _delay(db.dashboard(now.year, now.month));
      case '/transactions':
        return _delay(List<Map<String, dynamic>>.from(db.transactions));
      case '/budgets':
        return _delay(List<Map<String, dynamic>>.from(db.budgets));
      case '/goals':
        return _delay(List<Map<String, dynamic>>.from(db.goals));
      case '/alerts':
        return _delay(List<Map<String, dynamic>>.from(db.alerts));
      case '/reports/monthly':
        final year = int.tryParse('${query?['year'] ?? now.year}') ?? now.year;
        final month = int.tryParse('${query?['month'] ?? now.month}') ?? now.month;
        final totals = db.monthlyTotals(year, month);
        return _delay({
          'year': year,
          'month': month,
          'income': totals['income'],
          'expense': totals['expense'],
          'net': totals['net'],
        });
      case '/reports/categories':
        final year = int.tryParse('${query?['year'] ?? now.year}') ?? now.year;
        final month = int.tryParse('${query?['month'] ?? now.month}') ?? now.month;
        return _delay(db.categoryBreakdown(year, month));
      default:
        return _delay({'message': 'Not implemented in mock: $path'});
    }
  }

  // PUBLIC_INTERFACE
  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    /** Handles POST routes for mock data (create operations). */
    final db = MockDB.instance;
    switch (path) {
      case '/auth/login':
        // No-op: return pseudo token
        return _delay({'token': 'mock-token'});
      case '/auth/register':
        db.currentUser = {
          'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
          'name': body['name'] ?? 'User',
          'email': body['email'] ?? 'user@example.com',
        };
        return _delay({'status': 'ok'});
      case '/transactions':
        final t = db.createTransaction(
          description: '${body['description'] ?? 'Transaction'}',
          amount: (body['amount'] as num?) ?? 0,
          category: (body['category'] as String?)?.isNotEmpty == true ? body['category'] as String : null,
        );
        return _delay(t);
      case '/budgets':
        final b = db.createBudget('${body['category']}', (body['limit'] as num?) ?? 0);
        return _delay(b);
      case '/goals':
        final g = db.createGoal('${body['name']}', (body['target'] as num?) ?? 0);
        return _delay(g);
      case '/alerts/mark-read':
        final id = '${body['id'] ?? ''}';
        final a = db.markAlertRead(id);
        return _delay(a ?? {'message': 'Not found'});
      default:
        // support /alerts/{id}/read -> but our screens call GET /alerts only, added convenience here
        if (path.endsWith('/read')) {
          final id = path.split('/').reversed.skip(1).firstOrNull ?? '';
          final a = db.markAlertRead(id);
          return _delay(a ?? {'message': 'Not found'});
        }
        return _delay({'message': 'Not implemented in mock: $path'});
    }
  }

  // PUBLIC_INTERFACE
  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    /** Handles PUT routes for mock data (update operations). */
    final db = MockDB.instance;
    if (path.startsWith('/transactions/')) {
      final id = path.split('/').last;
      final t = db.updateTransaction(id, body);
      return _delay(t ?? {'message': 'Not found'});
    } else if (path.startsWith('/budgets/')) {
      final id = path.split('/').last;
      final b = db.updateBudget(id, body);
      return _delay(b ?? {'message': 'Not found'});
    } else if (path.startsWith('/goals/')) {
      final id = path.split('/').last;
      final g = db.updateGoal(id, body);
      return _delay(g ?? {'message': 'Not found'});
    }
    return _delay({'message': 'Not implemented in mock: $path'});
  }

  // PUBLIC_INTERFACE
  Future<dynamic> delete(String path) async {
    /** Handles DELETE routes for mock data. */
    final db = MockDB.instance;
    if (path.startsWith('/transactions/')) {
      final id = path.split('/').last;
      final ok = db.deleteTransaction(id);
      return _delay({'deleted': ok});
    }
    return _delay({'message': 'Not implemented in mock: $path'});
  }
}

extension _IterableExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
