import 'package:flutter/foundation.dart';

import '../models/budget_period.dart';
import '../models/expense.dart';
import '../models/savings_goal.dart';
import '../services/supabase_service.dart';

/// Holds the current user's budget period, expenses, and savings goals,
/// all backed by Supabase. Notifies listeners whenever data changes so
/// the UI updates automatically.
class BudgetProvider extends ChangeNotifier {
  BudgetPeriod? _currentPeriod;
  List<Expense> _expenses = [];
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;

  BudgetPeriod? get currentPeriod => _currentPeriod;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  // ---- Derived values used across Home & History screens ----

  /// Pure spending only (Food, Transportation, etc.) — excludes money
  /// moved into savings goals, so Home can show "Spent" and "Saved"
  /// as two separate, honest figures instead of one blended number.
  double get totalSpent => _expenses
      .where((e) => e.category != ExpenseCategory.savings)
      .fold(0.0, (sum, e) => sum + e.amount);

  /// Money moved into savings goals this period. Still comes out of
  /// the allowance (see remainingBalance below) — it's just tracked
  /// separately from everyday spending.
  double get totalSaved => _expenses
      .where((e) => e.category == ExpenseCategory.savings)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get remainingBalance {
    if (_currentPeriod == null) return 0;
    // Money put toward a goal reduces what's left to spend, same as
    // any other expense — it just isn't counted as "spending".
    return _currentPeriod!.allowanceAmount - totalSpent - totalSaved;
  }

  double get safeToSpendPerDay {
    if (_currentPeriod == null) return 0;
    final daysLeft = _currentPeriod!.daysRemaining;
    if (daysLeft <= 0) return remainingBalance;
    return remainingBalance / daysLeft;
  }

  /// How much of the allowance has been used up, spending + saving
  /// combined — used for Home's progress bar.
  double get spentRatio {
    if (_currentPeriod == null || _currentPeriod!.allowanceAmount == 0) {
      return 0;
    }
    final used = totalSpent + totalSaved;
    return (used / _currentPeriod!.allowanceAmount).clamp(0.0, 1.0);
  }

  double get todaySpent {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.category != ExpenseCategory.savings &&
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get todayRemaining => safeToSpendPerDay - todaySpent;

  Map<ExpenseCategory, double> get totalsByCategory {
    final Map<ExpenseCategory, double> totals = {
      for (final c in ExpenseCategory.values) c: 0.0,
    };
    for (final e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  // ---- Loading data (call after login — AuthGate does this for you) ----

  Future<void> loadCurrentPeriod() async {
    final userId = _userId;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    final periodRows = await SupabaseService.client
        .from('budget_periods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    if (periodRows.isNotEmpty) {
      _currentPeriod = BudgetPeriod.fromMap(periodRows.first);
      await _loadExpenses(_currentPeriod!.id);
    } else {
      _currentPeriod = null;
      _expenses = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadExpenses(String periodId) async {
    final rows = await SupabaseService.client
        .from('expenses')
        .select()
        .eq('budget_period_id', periodId)
        .order('date', ascending: false);

    _expenses = rows.map<Expense>((row) => Expense.fromMap(row)).toList();
  }

  /// Feature: Savings Goal — loads all goals for the logged-in user.
  /// Call this after login, same as loadCurrentPeriod (AuthGate does
  /// both).
  Future<void> loadSavingsGoals() async {
    final userId = _userId;
    if (userId == null) return;

    final rows = await SupabaseService.client
        .from('savings_goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    _goals = rows.map<SavingsGoal>((row) => SavingsGoal.fromMap(row)).toList();
    notifyListeners();
  }

  // ---- Budget/Expense actions ----

  Future<void> startNewPeriod({
    required double allowanceAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final inserted = await SupabaseService.client
        .from('budget_periods')
        .insert({
          'user_id': userId,
          'allowance_amount': allowanceAmount,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        })
        .select()
        .single();

    _currentPeriod = BudgetPeriod.fromMap(inserted);
    _expenses = [];
    notifyListeners();
  }

  /// Tops up the current period's allowance directly (e.g. extra
  /// money a student receives mid-period), rather than logging it as
  /// an expense.
  Future<void> addMoneyToAllowance(double amount) async {
    final period = _currentPeriod;

    if (period == null) {
      throw Exception('There is no active budget period.');
    }

    if (amount <= 0) {
      throw Exception('Amount must be greater than zero.');
    }

    final newAllowance = period.allowanceAmount + amount;

    final updated = await SupabaseService.client
        .from('budget_periods')
        .update({'allowance_amount': newAllowance})
        .eq('id', period.id)
        .select()
        .single();

    _currentPeriod = BudgetPeriod.fromMap(updated);
    notifyListeners();
  }

  Future<void> addExpense({
    required double amount,
    required ExpenseCategory category,
    String? note,
    DateTime? date,
  }) async {
    final userId = _userId;
    final period = _currentPeriod;
    if (userId == null || period == null) return;

    final inserted = await SupabaseService.client
        .from('expenses')
        .insert({
          'user_id': userId,
          'budget_period_id': period.id,
          'amount': amount,
          'category': category.name,
          'note': note,
          'date': (date ?? DateTime.now()).toIso8601String(),
        })
        .select()
        .single();

    _expenses.insert(0, Expense.fromMap(inserted));
    notifyListeners();
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    required ExpenseCategory category,
    String? note,
  }) async {
    final updated = await SupabaseService.client
        .from('expenses')
        .update({
          'amount': amount,
          'category': category.name,
          'note': note,
        })
        .eq('id', id)
        .select()
        .single();

    final updatedExpense = Expense.fromMap(updated);
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    await SupabaseService.client.from('expenses').delete().eq('id', id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---- Savings Goal actions ----

  Future<void> addGoal({
    required String title,
    required String emoji,
    required double targetAmount,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final inserted = await SupabaseService.client
        .from('savings_goals')
        .insert({
          'user_id': userId,
          'title': title,
          'emoji': emoji,
          'target_amount': targetAmount,
          'saved_amount': 0,
        })
        .select()
        .single();

    _goals.add(SavingsGoal.fromMap(inserted));
    notifyListeners();
  }

  Future<void> updateGoal({
    required String id,
    required String title,
    required String emoji,
    required double targetAmount,
  }) async {
    final updated = await SupabaseService.client
        .from('savings_goals')
        .update({
          'title': title,
          'emoji': emoji,
          'target_amount': targetAmount,
        })
        .eq('id', id)
        .select()
        .single();

    final updatedGoal = SavingsGoal.fromMap(updated);
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      notifyListeners();
    }
  }

  /// Adds money set aside toward a goal. This ALSO logs it as an
  /// expense under the "Savings Goal" category, so the amount comes
  /// out of the current budget period's allowance just like any other
  /// spending — putting money toward a goal is money you no longer
  /// have free to spend elsewhere.
  ///
  /// Returns an error message if it couldn't be done (e.g. no active
  /// budget period yet), or null on success.
  Future<String?> addFundsToGoal(String id, double amount) async {
    if (amount <= 0) return 'Enter an amount greater than zero.';

    if (_currentPeriod == null) {
      return 'Set up a budget on the Home tab before adding funds to a goal.';
    }

    final goal = _goals.firstWhere((g) => g.id == id);
    final newSavedAmount = goal.savedAmount + amount;

    // Log it against the allowance first...
    await addExpense(
      amount: amount,
      category: ExpenseCategory.savings,
      note: 'Added to "${goal.title}"',
    );

    // ...then update the goal's saved amount.
    final updated = await SupabaseService.client
        .from('savings_goals')
        .update({'saved_amount': newSavedAmount})
        .eq('id', id)
        .select()
        .single();

    final updatedGoal = SavingsGoal.fromMap(updated);
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      notifyListeners();
    }
    return null;
  }

  Future<void> deleteGoal(String id) async {
    await SupabaseService.client.from('savings_goals').delete().eq('id', id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  /// Feature: Budget Period Completed screen's "Start New Allowance"
  /// button. Clears just the local period reference (the finished
  /// period's row stays in Supabase for History) so Home naturally
  /// falls back to showing SetBudgetScreen, without navigating away
  /// from the tabbed shell.
  void clearPeriodLocally() {
    _currentPeriod = null;
    _expenses = [];
    notifyListeners();
  }

  /// Call this on logout so the next user who logs in on this device
  /// doesn't briefly see the previous user's data.
  void reset() {
    _currentPeriod = null;
    _expenses = [];
    _goals = [];
    notifyListeners();
  }
}