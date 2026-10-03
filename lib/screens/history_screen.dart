import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ExpenseCategory? _filter; // null = "All"

  String _label(ExpenseCategory category) {
    if (category == ExpenseCategory.supplies) return 'Projects';
    return category.label;
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final allExpenses = budget.expenses;
    final expenses = _filter == null
        ? allExpenses
        : allExpenses.where((e) => e.category == _filter).toList();
    final period = budget.currentPeriod;

    // Everything that counts as real spending for the chart — this
    // now includes Load/Data (it was being silently dropped before).
    // Savings Goal contributions are excluded since those are
    // tracked as "Saved", not "Spent".
    final chartEntries = budget.totalsByCategory.entries
        .where((e) => e.key != ExpenseCategory.savings && e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chartTotal = chartEntries.fold(0.0, (sum, e) => sum + e.value);

    final filteredTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('History')),
      body: allExpenses.isEmpty
          ? const Center(child: Text('No expenses logged yet.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _CategoryFilterRow(
                  selected: _filter,
                  onSelected: (c) => setState(() => _filter = c),
                  labelOf: _label,
                ),
                if (period != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_fmt(period.startDate)} – ${_fmt(period.endDate)}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _filter == null ? 'Total Spent' : '${_label(_filter!)} Total',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      Text(
                        '₱${filteredTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),

                // Only show the breakdown chart on "All" — it doesn't
                // make sense once you've already filtered to one
                // category.
                if (_filter == null && chartEntries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InlineBreakdown(
                    entries: chartEntries,
                    total: chartTotal,
                    labelOf: _label,
                  ),
                ],

                const SizedBox(height: 16),
                for (final expense in expenses)
                  _ExpenseTile(
                    expense: expense,
                    label: _label(expense.category),
                    onTap: () => _showExpenseActions(context, expense),
                  ),
              ],
            ),
    );
  }

  String _fmt(DateTime d) => '${_month(d.month)} ${d.day}';
  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  void _showExpenseActions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
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
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete this expense?'),
                      content: Text(
                        '${expense.category.emoji} ₱${expense.amount.toStringAsFixed(2)} '
                        '— this can\'t be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        );
      },
    );
  }
}

/// Feature: pie chart shown directly on History when viewing "All" —
/// no extra tap needed.
class _InlineBreakdown extends StatelessWidget {
  final List<MapEntry<ExpenseCategory, double>> entries;
  final double total;
  final String Function(ExpenseCategory) labelOf;

  const _InlineBreakdown({
    required this.entries,
    required this.total,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 46,
                    sectionsSpace: 2,
                    sections: [
                      for (final entry in entries)
                        PieChartSectionData(
                          value: entry.value,
                          color: categoryColors[entry.key],
                          showTitle: false,
                          radius: 36,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    Text(
                      '₱${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: categoryColors[entry.key],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      labelOf(entry.key),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '₱${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 34,
                    child: Text(
                      total == 0 ? '0%' : '${(entry.value / total * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
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

class _CategoryFilterRow extends StatelessWidget {
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelected;
  final String Function(ExpenseCategory) labelOf;

  const _CategoryFilterRow({
    required this.selected,
    required this.onSelected,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(label: 'All', selected: selected == null, onTap: () => onSelected(null)),
          for (final category in ExpenseCategory.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: labelOf(category),
                selected: selected == category,
                onTap: () => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryDark,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textDark,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selected ? Colors.transparent : AppTheme.border),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String label;
  final VoidCallback onTap;

  const _ExpenseTile({required this.expense, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasNote = expense.note != null && expense.note!.trim().isNotEmpty;
    final color = categoryColors[expense.category] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(expense.category.emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        subtitle: Text(
          hasNote
              ? '${expense.note} • ${expense.date.month}/${expense.date.day}'
              : '${expense.date.month}/${expense.date.day}/${expense.date.year}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '₱${expense.amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark),
        ),
      ),
    );
  }
}