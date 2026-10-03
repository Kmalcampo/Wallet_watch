enum ExpenseCategory { food, transportation, load, supplies, savings, misc }

extension ExpenseCategoryX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.load:
        return 'Load/Data';
      case ExpenseCategory.supplies:
        return 'School Supplies';
      case ExpenseCategory.savings:
        return 'Savings Goal';
      case ExpenseCategory.misc:
        return 'Miscellaneous';
    }
  }

  /// Small visual identifier used in History's breakdown list and
  /// expense tiles, e.g. "🍔 Food — ₱450".
  String get emoji {
    switch (this) {
      case ExpenseCategory.food:
        return '🍔';
      case ExpenseCategory.transportation:
        return '🚌';
      case ExpenseCategory.load:
        return '📶';
      case ExpenseCategory.supplies:
        return '📚';
      case ExpenseCategory.savings:
        return '💰';
      case ExpenseCategory.misc:
        return '📦';
    }
  }
}

class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  Expense copyWith({
    double? amount,
    ExpenseCategory? category,
    String? note,
    DateTime? date,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  // --- Supabase (de)serialization ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ExpenseCategory.misc,
      ),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}