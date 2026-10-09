import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

const _sectionLabelStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppTheme.textDark,
);

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  /// When this screen is used as its own bottom-nav tab (rather than
  /// pushed as a route to edit an expense), pass a callback here.
  /// After a successful save it clears the form and calls this
  /// instead of Navigator.pop — there's nothing to "go back" to when
  /// this screen is a tab root.
  final VoidCallback? onSaved;

  const AddExpenseScreen({
    super.key,
    this.existingExpense,
    this.onSaved,
  });

  bool get isTab => onSaved != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late ExpenseCategory _selectedCategory;

  bool _isSubmitting = false;

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();

    final expense = widget.existingExpense;

    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );

    _noteController = TextEditingController(
      text: expense?.note ?? '',
    );

    _selectedCategory = expense?.category ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _peso(double value) {
    return '₱${value.toStringAsFixed(2)}';
  }

  /// Quick-amount chips add to whatever is already typed, so tapping
  /// +₱50 twice gives ₱100.
  void _addQuick(double value) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0;
    final next = current + value;

    _amountController.text = next == next.roundToDouble()
        ? next.toStringAsFixed(0)
        : next.toStringAsFixed(2);
    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
    setState(() {});
  }

  Future<void> _submit() async {
    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final budget = context.read<BudgetProvider>();

    try {
      if (_isEditing) {
        await budget.updateExpense(
          id: widget.existingExpense!.id,
          amount: amount,
          category: _selectedCategory,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      } else {
        await budget.addExpense(
          amount: amount,
          category: _selectedCategory,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Expense updated.'
                : '${_peso(amount)} expense added.',
          ),
        ),
      );

      if (widget.isTab) {
        // Tab mode: nothing to pop back to — clear the form so it's
        // ready for the next entry, and let the parent (RootScreen)
        // decide what happens next (e.g. switch back to Home).
        _amountController.clear();
        _noteController.clear();
        setState(() {
          _selectedCategory = ExpenseCategory.food;
          _isSubmitting = false;
        });
        widget.onSaved!();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save expense: $e'),
        ),
      );
    }
  }

  Color _categoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFFF5961);

      case ExpenseCategory.transportation:
        return const Color(0xFF4285F4);

      case ExpenseCategory.load:
        return const Color(0xFF9C4DFF);

      case ExpenseCategory.supplies:
        return const Color(0xFF9C4DFF);

      case ExpenseCategory.savings:
        return const Color(0xFFFFAB00);

      case ExpenseCategory.misc:
        return const Color(0xFFFFA900);
    }
  }

  IconData _categoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;

      case ExpenseCategory.transportation:
        return Icons.directions_bus_rounded;

      case ExpenseCategory.load:
        return Icons.wifi_rounded;

      case ExpenseCategory.supplies:
        return Icons.school_rounded;

      case ExpenseCategory.savings:
        return Icons.savings_rounded;

      case ExpenseCategory.misc:
        return Icons.shopping_bag_rounded;
    }
  }

  String _categoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';

      case ExpenseCategory.transportation:
        return 'Transportation';

      case ExpenseCategory.load:
        return 'Load/Data';

      case ExpenseCategory.supplies:
        return 'Projects';

      case ExpenseCategory.savings:
        return 'Savings';

      case ExpenseCategory.misc:
        return 'Miscellaneous';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            // AMOUNT
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How much did you spend?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '₱',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          cursorColor: AppTheme.primary,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFCBD6D2),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in const [20, 50, 100, 200])
                        _QuickChip(
                          label: '+₱$value',
                          onTap: () => _addQuick(value.toDouble()),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CATEGORY
            const Text('Category', style: _sectionLabelStyle),

            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ExpenseCategory.values.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final category = ExpenseCategory.values[index];
                final selected = _selectedCategory == category;
                final color = _categoryColor(category);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? color : AppTheme.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _categoryIcon(category),
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _categoryLabel(category),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // NOTE
            const Text('Note (optional)', style: _sectionLabelStyle),

            const SizedBox(height: 10),

            TextField(
              controller: _noteController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textDark,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. Lunch at school',
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Save Changes' : 'Add Expense',
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary.withValues(alpha: 0.10),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}