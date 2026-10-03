class SavingsGoal {
  final String id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    required this.createdAt,
  });

  /// 0.0–1.0, clamped so an overfunded goal still shows a full bar
  /// instead of overflowing it.
  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isComplete => savedAmount >= targetAmount;

  // --- Supabase (de)serialization ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      emoji: map['emoji'] as String? ?? '🎯',
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}