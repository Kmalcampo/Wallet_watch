import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Whole pesos show without decimals (₱120), otherwise two decimals.
String _peso(double v) {
  return v == v.roundToDouble()
      ? '₱${v.toStringAsFixed(0)}'
      : '₱${v.toStringAsFixed(2)}';
}

String _categoryName(ExpenseCategory category) {
  if (category == ExpenseCategory.supplies) return 'Projects';
  return category.label;
}

class _DayGroup {
  final DateTime day;
  final List<Expense> items;
  _DayGroup(this.day, this.items);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ExpenseCategory? _filter; // null = "All"

  String _dayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${_months[day.month - 1]} ${day.day}, ${day.year}';
  }

  List<_DayGroup> _group(List<Expense> sorted) {
    final groups = <_DayGroup>[];
    for (final e in sorted) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      if (groups.isNotEmpty && groups.last.day == key) {
        groups.last.items.add(e);
      } else {
        groups.add(_DayGroup(key, [e]));
      }
    }
    return groups;
  }

  /// Savings goal contributions aren't "spending", so they're left out
  /// of the day totals unless the Savings filter is selected.
  double _dayTotal(List<Expense> items) {
    return items
        .where((e) =>
            _filter == ExpenseCategory.savings ||
            e.category != ExpenseCategory.savings)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final all = budget.expenses;
    final filtered = _filter == null
        ? all
        : all.where((e) => e.category == _filter).toList();
    final sorted = [...filtered]..sort((a, b) => b.date.compareTo(a.date));
    final groups = _group(sorted);
    final period = budget.currentPeriod;

    final chartEntries = budget.totalsByCategory.entries
        .where((e) => e.key != ExpenseCategory.savings && e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chartTotal = chartEntries.fold(0.0, (sum, e) => sum + e.value);

    final heroTitle =
        _filter == null ? 'Total Spent' : '${_categoryName(_filter!)} Total';
    final heroAmount = _filter == null
        ? budget.totalSpent
        : filtered.fold(0.0, (sum, e) => sum + e.amount);

    String? periodText;
    if (period != null) {
      periodText =
          '${_months[period.startDate.month - 1]} ${period.startDate.day} – '
          '${_months[period.endDate.month - 1]} ${period.endDate.day}';
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('History'),
      ),
      body: all.isEmpty
          ? const _EmptyHistory()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                _SummaryCard(
                  title: heroTitle,
                  amount: heroAmount,
                  periodText: periodText,
                  count: filtered.length,
                  saved: _filter == null && budget.totalSaved > 0
                      ? budget.totalSaved
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: _CategoryFilterRow(
                    selected: _filter,
                    onSelected: (c) => setState(() => _filter = c),
                  ),
                ),

                // The breakdown chart only makes sense across all
                // categories, so it's hidden once you filter to one.
                if (_filter == null && chartEntries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InlineBreakdown(
                    entries: chartEntries,
                    total: chartTotal,
                  ),
                ],

                const SizedBox(height: 20),

                if (groups.isEmpty)
                  _NoResults(label: _categoryName(_filter!))
                else
                  for (final group in groups) ...[
                    _DayHeader(
                      title: _dayHeader(group.day),
                      total: _dayTotal(group.items),
                    ),
                    for (final expense in group.items)
                      _ExpenseTile(
                        expense: expense,
                        onTap: () => _showExpenseActions(context, expense),
                      ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
    );
  }

  void _showExpenseActions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final color = categoryColors[expense.category] ?? Colors.grey;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        expense.category.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _categoryName(expense.category),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _peso(expense.amount),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppTheme.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textDark,
                  ),
                  title: const Text(
                    'Edit expense',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(existingExpense: expense),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.danger,
                  ),
                  title: const Text(
                    'Delete expense',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.danger,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          'Delete this expense?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        content: Text(
                          '${expense.category.emoji} ${_peso(expense.amount)} '
                          '— this can\'t be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<BudgetProvider>().deleteExpense(expense.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final String? periodText;
  final int count;
  final double? saved;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.periodText,
    required this.count,
    required this.saved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, Color(0xFF0B5A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _peso(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (periodText != null) _Pill(icon: Icons.event_rounded, text: periodText!),
              _Pill(
                icon: Icons.receipt_long_rounded,
                text: '$count ${count == 1 ? 'transaction' : 'transactions'}',
              ),
              if (saved != null)
                _Pill(
                  icon: Icons.savings_rounded,
                  text: '${_peso(saved!)} saved',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelected;

  const _CategoryFilterRow({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _FilterPill(
          label: 'All',
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final category in ExpenseCategory.values)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _FilterPill(
              label: '${category.emoji}  ${_categoryName(category)}',
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primaryDark : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppTheme.primaryDark : AppTheme.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineBreakdown extends StatelessWidget {
  final List<MapEntry<ExpenseCategory, double>> entries;
  final double total;

  const _InlineBreakdown({required this.entries, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Where your money went',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 58,
                    sectionsSpace: 3,
                    sections: [
                      for (final entry in entries)
                        PieChartSectionData(
                          value: entry.value,
                          color: categoryColors[entry.key],
                          showTitle: false,
                          radius: 30,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    Text(
                      _peso(total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: categoryColors[entry.key],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _categoryName(entry.key),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Text(
                    _peso(entry.value),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: (categoryColors[entry.key] ?? Colors.grey)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      total == 0
                          ? '0%'
                          : '${(entry.value / total * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String title;
  final double total;

  const _DayHeader({required this.title, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Text(
            _peso(total),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const _ExpenseTile({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final note = expense.note?.trim() ?? '';
    final color = categoryColors[expense.category] ?? Colors.grey;
    final isSavings = expense.category == ExpenseCategory.savings;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  expense.category.emoji,
                  style: const TextStyle(fontSize: 21),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryName(expense.category),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.isEmpty ? 'No note' : note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: note.isEmpty
                            ? const Color(0xFF9AA9A3)
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isSavings ? '+${_peso(expense.amount)}' : _peso(expense.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSavings ? AppTheme.primary : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No expenses yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log your first expense from the Add tab and it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String label;

  const _NoResults({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          'No $label expenses yet.',
          style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}