class BudgetPeriod {
  final String id;
  final double allowanceAmount;
  final DateTime startDate;
  final DateTime endDate;

  BudgetPeriod({
    required this.id,
    required this.allowanceAmount,
    required this.startDate,
    required this.endDate,
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;

  int get daysRemaining {
    final today = DateTime.now();

    final remaining = endDate.difference(today).inDays + 1;

    return remaining < 0 ? 0 : remaining;
  }

  bool get isEnded {
    final today = DateTime.now();

    final todayDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final endDateOnly = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    return todayDate.isAfter(endDateOnly);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'allowance_amount': allowanceAmount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  factory BudgetPeriod.fromMap(Map<String, dynamic> map) {
    return BudgetPeriod(
      id: map['id'] as String,
      allowanceAmount: (map['allowance_amount'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
    );
  }
}