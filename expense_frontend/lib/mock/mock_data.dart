import 'dart:math';

/// Simple in-memory mock database for demo mode.
/// Contains seed data and helper aggregations used by mock_client.dart.
class MockDB {
  MockDB._();
  static final MockDB instance = MockDB._();

  // Users are optional in mock mode
  Map<String, dynamic> currentUser = {
    'id': 'u_1',
    'name': 'Alex Johnson',
    'email': 'alex@example.com',
  };

  // Accounts (not fully used yet but could be referenced by transactions)
  final List<Map<String, dynamic>> accounts = [
    {'id': 'acc_checking', 'name': 'Checking', 'type': 'checking', 'balance': 2450.12},
    {'id': 'acc_savings', 'name': 'Savings', 'type': 'savings', 'balance': 8040.55},
    {'id': 'acc_cc', 'name': 'Credit Card', 'type': 'credit', 'balance': -320.18},
  ];

  // Categories
  final List<String> categories = [
    'Groceries',
    'Rent',
    'Utilities',
    'Dining',
    'Transport',
    'Health',
    'Entertainment',
    'Income',
    'Other',
  ];

  // Transactions: varied amounts and dates
  final List<Map<String, dynamic>> transactions = [];

  // Budgets (current month)
  final List<Map<String, dynamic>> budgets = [
    {'id': 'b1', 'category': 'Groceries', 'limit': 400, 'spent': 0},
    {'id': 'b2', 'category': 'Dining', 'limit': 200, 'spent': 0},
    {'id': 'b3', 'category': 'Transport', 'limit': 150, 'spent': 0},
    {'id': 'b4', 'category': 'Entertainment', 'limit': 120, 'spent': 0},
  ];

  // Goals
  final List<Map<String, dynamic>> goals = [
    {
      'id': 'g1',
      'name': 'Emergency Fund',
      'target': 5000,
      'saved': 2200,
      'target_date': DateTime.now().add(const Duration(days: 200)).toIso8601String(),
    },
    {
      'id': 'g2',
      'name': 'Vacation',
      'target': 2000,
      'saved': 800,
      'target_date': DateTime.now().add(const Duration(days: 120)).toIso8601String(),
    },
  ];

  // Alerts
  final List<Map<String, dynamic>> alerts = [
    {
      'id': 'a1',
      'title': 'Budget nearing limit',
      'message': 'You have spent 85% of your Dining budget this month.',
      'read': false,
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'a2',
      'title': 'Large transaction',
      'message': 'A large expense of \$350.00 was recorded in Utilities.',
      'read': false,
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
  ];

  bool _seeded = false;

  /// PUBLIC_INTERFACE
  void seedIfNeeded() {
    /** Seeds mock transactions and recomputes budget spent values. */
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();
    final rnd = Random(42);

    // Create 90 days of random income/expenses
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: rnd.nextInt(75)));
      // 1-3 transactions per day
      for (int j = 0; j < rnd.nextInt(3) + 1; j++) {
        final isIncome = rnd.nextDouble() < 0.25; // 25% income
        final category = isIncome ? 'Income' : categories[rnd.nextInt(categories.length - 1)];
        final amount = (isIncome ? 1000 + rnd.nextInt(2000) : rnd.nextInt(120) + 5).toDouble();
        final signed = isIncome ? amount : -amount;
        transactions.add({
          'id': 't_${transactions.length + 1}',
          'description': isIncome ? 'Paycheck' : 'Purchase - $category',
          'amount': double.parse(signed.toStringAsFixed(2)),
          'category': category,
          'account_id': accounts[rnd.nextInt(accounts.length)]['id'],
          'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        });
      }
    }

    _recomputeBudgetsForMonth(now.year, now.month);
  }

  /// PUBLIC_INTERFACE
  Map<String, num> monthlyTotals(int year, int month) {
    /** Computes total income, expense and net for the given month. */
    num income = 0;
    num expense = 0;
    for (final t in transactions) {
      final dt = DateTime.tryParse('${t['date']}');
      if (dt == null) continue;
      if (dt.year == year && dt.month == month) {
        final amt = (t['amount'] as num?) ?? 0;
        if (amt >= 0) {
          income += amt;
        } else {
          expense += -amt;
        }
      }
    }
    return {
      'income': double.parse(income.toStringAsFixed(2)),
      'expense': double.parse(expense.toStringAsFixed(2)),
      'net': double.parse((income - expense).toStringAsFixed(2)),
    };
  }

  /// PUBLIC_INTERFACE
  List<Map<String, dynamic>> categoryBreakdown(int year, int month) {
    /** Returns expenses grouped by category for the given month, descending. */
    final Map<String, num> totals = {};
    for (final t in transactions) {
      final dt = DateTime.tryParse('${t['date']}');
      if (dt == null) continue;
      if (dt.year == year && dt.month == month) {
        final amt = (t['amount'] as num?) ?? 0;
        if (amt < 0) {
          final cat = (t['category'] as String?) ?? 'Other';
          totals[cat] = (totals[cat] ?? 0) + (-amt);
        }
      }
    }
    final list = totals.entries
        .map((e) => {'category': e.key, 'amount': double.parse(e.value.toStringAsFixed(2))})
        .toList();
    list.sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
    return list;
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic> dashboard(int year, int month) {
    /** Dashboard payload with KPIs and current budgets view. */
    final totals = monthlyTotals(year, month);
    // include budgets as is (with spent recomputed at seed/mutation)
    return {
      'totalIncome': totals['income'],
      'totalExpense': totals['expense'],
      'net': totals['net'],
      'budgets': budgets,
      'topCategories': categoryBreakdown(year, month).take(5).toList(),
      'last6Months': _lastNMonthsSeries(6),
    };
  }

  List<Map<String, dynamic>> _lastNMonthsSeries(int n) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> out = [];
    for (int i = n - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      final m = monthlyTotals(d.year, d.month);
      out.add({
        'year': d.year,
        'month': d.month,
        'income': m['income'],
        'expense': m['expense'],
        'net': m['net'],
      });
    }
    return out;
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic> createTransaction({
    required String description,
    required num amount,
    String? category,
    DateTime? date,
  }) {
    /** Creates a transaction and updates budgets. */
    final t = {
      'id': 't_${transactions.length + 1}',
      'description': description,
      'amount': double.parse(amount.toStringAsFixed(2)),
      'category': category ?? 'Other',
      'account_id': 'acc_checking',
      'date': (date ?? DateTime.now()).toIso8601String(),
    };
    transactions.insert(0, t);
    final dt = date ?? DateTime.now();
    _recomputeBudgetsForMonth(dt.year, dt.month);
    return t;
  }

  /// PUBLIC_INTERFACE
  bool deleteTransaction(String id) {
    /** Deletes a transaction and updates budgets. */
    final idx = transactions.indexWhere((e) => e['id'] == id);
    if (idx == -1) return false;
    final dt = DateTime.tryParse('${transactions[idx]['date']}') ?? DateTime.now();
    transactions.removeAt(idx);
    _recomputeBudgetsForMonth(dt.year, dt.month);
    return true;
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic>? updateTransaction(String id, Map<String, dynamic> patch) {
    /** Updates a transaction and recalculates budgets. */
    final idx = transactions.indexWhere((e) => e['id'] == id);
    if (idx == -1) return null;
    final original = Map<String, dynamic>.from(transactions[idx]);
    final merged = {...original, ...patch};
    transactions[idx] = merged;
    final dt = DateTime.tryParse('${merged['date']}') ?? DateTime.now();
    _recomputeBudgetsForMonth(dt.year, dt.month);
    return merged;
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic> createBudget(String category, num limit) {
    /** Creates a budget for current month. */
    final b = {
      'id': 'b_${budgets.length + 1}',
      'category': category,
      'limit': limit,
      'spent': 0,
    };
    budgets.add(b);
    final now = DateTime.now();
    _recomputeBudgetsForMonth(now.year, now.month);
    return b;
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic>? updateBudget(String id, Map<String, dynamic> patch) {
    /** Updates a budget entity. */
    final idx = budgets.indexWhere((e) => e['id'] == id);
    if (idx == -1) return null;
    budgets[idx] = {...budgets[idx], ...patch};
    final now = DateTime.now();
    _recomputeBudgetsForMonth(now.year, now.month);
    return budgets[idx];
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic> createGoal(String name, num target) {
    /** Creates a savings goal. */
    final g = {
      'id': 'g_${goals.length + 1}',
      'name': name,
      'target': target,
      'saved': 0,
      'target_date': DateTime.now().add(const Duration(days: 180)).toIso8601String(),
    };
    goals.add(g);
    return g;
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic>? updateGoal(String id, Map<String, dynamic> patch) {
    /** Updates a goal entity. */
    final idx = goals.indexWhere((e) => e['id'] == id);
    if (idx == -1) return null;
    goals[idx] = {...goals[idx], ...patch};
    return goals[idx];
  }

  /// PUBLIC_INTERFACE
  List<Map<String, dynamic>> listAlerts() {
    /** Returns current alerts. */
    return alerts;
  }

  /// PUBLIC_INTERFACE
  Map<String, dynamic>? markAlertRead(String id) {
    /** Marks an alert as read. */
    final idx = alerts.indexWhere((e) => e['id'] == id);
    if (idx == -1) return null;
    alerts[idx] = {...alerts[idx], 'read': true};
    return alerts[idx];
  }

  void _recomputeBudgetsForMonth(int year, int month) {
    final Map<String, num> spentByCat = {};
    for (final t in transactions) {
      final dt = DateTime.tryParse('${t['date']}');
      if (dt == null) continue;
      if (dt.year == year && dt.month == month) {
        final amt = (t['amount'] as num?) ?? 0;
        if (amt < 0) {
          final cat = (t['category'] as String?) ?? 'Other';
          spentByCat[cat] = (spentByCat[cat] ?? 0) + (-amt);
        }
      }
    }
    for (int i = 0; i < budgets.length; i++) {
      final cat = budgets[i]['category'] as String? ?? 'Other';
      budgets[i] = {
        ...budgets[i],
        'spent': double.parse((spentByCat[cat] ?? 0).toStringAsFixed(2)),
      };
    }
  }
}
