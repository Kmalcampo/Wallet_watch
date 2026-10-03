import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseScreen({
    super.key,
    this.existingExpense,
  });

  @override
  State<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState
    extends State<AddExpenseScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late ExpenseCategory _selectedCategory;

  bool _isSubmitting = false;

  bool get _isEditing =>
      widget.existingExpense != null;

  @override
  void initState() {
    super.initState();

    final expense = widget.existingExpense;

    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : expense.amount.toStringAsFixed(2),
    );

    _noteController = TextEditingController(
      text: expense?.note ?? '',
    );

    _selectedCategory =
        expense?.category ?? ExpenseCategory.food;
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

  Future<void> _submit() async {
    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid amount.',
          ),
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

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Expense updated.'
                : '${_peso(amount)} expense added.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save expense: $e',
          ),
        ),
      );
    }
  }

  Color _categoryColor(
    ExpenseCategory category,
  ) {
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

  IconData _categoryIcon(
    ExpenseCategory category,
  ) {
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

  String _categoryLabel(
    ExpenseCategory category,
  ) {
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),
        title: Text(
          _isEditing
              ? 'Edit Expense'
              : 'Add Expense',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            30,
          ),
          children: [
            const Text(
              'Amount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                prefixText: '₱  ',
                prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
                hintText: '0.00',
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA9A3),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 9),

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: ExpenseCategory.values.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 2.9,
              ),
              itemBuilder: (
                context,
                index,
              ) {
                final category =
                    ExpenseCategory.values[index];

                final selected =
                    _selectedCategory == category;

                final color =
                    _categoryColor(category);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity(0.10)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? color.withOpacity(0.5)
                            : const Color(
                                0xFFE0E7E3,
                              ),
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          decoration:
                              BoxDecoration(
                            color:
                                color.withOpacity(0.13),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _categoryIcon(category),
                            color: color,
                            size: 15,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            _categoryLabel(category),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight:
                                  FontWeight.w800,
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

            const SizedBox(height: 23),

            const Text(
              'Note (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Lunch at school',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9AA9A3),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Save Changes'
                            : 'Add Expense',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}