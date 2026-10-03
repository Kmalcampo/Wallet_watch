import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';
import 'spending_breakdown_screen.dart';

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
                for (final expense in expenses)
                  _ExpenseTile(
                    expense: expense,
                    label: _label(expense.category),
                    onTap: () => _showExpenseActions(context, expense),
                  ),
                const SizedBox(height: 16),
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
                      const Text(
                        'Total Spent',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      Text(
                        '₱${budget.totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SpendingBreakdownScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Spending Breakdown',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
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