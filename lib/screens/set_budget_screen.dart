import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({
    super.key,
  });

  @override
  State<SetBudgetScreen> createState() =>
      _SetBudgetScreenState();
}

class _SetBudgetScreenState
    extends State<SetBudgetScreen> {
  final TextEditingController _amountController =
      TextEditingController();

  DateTime _startDate = DateTime.now();

  DateTime _endDate =
      DateTime.now().add(const Duration(days: 6));

  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      _startDate = selected;

      if (_endDate.isBefore(selected)) {
        _endDate = selected;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate)
          ? _startDate
          : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _next() async {
    final amount = double.tryParse(
      _amountController.text
          .replaceAll(',', '')
          .trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid allowance amount.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context
          .read<BudgetProvider>()
          .startNewPeriod(
            allowanceAmount: amount,
            startDate: _startDate,
            endDate: _endDate,
          );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save your allowance: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            30,
          ),
          children: [
            IconButton(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Set Your Allowance',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'How much allowance do you have and for how long will it last?',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textMuted,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Allowance Amount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: '₱  ',
                hintText: '1,000',
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Start Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _selectStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.calendar_month_outlined,
                  ),
                ),
                child: Text(
                  _formatDate(_startDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'End Date',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _selectEndDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.calendar_month_outlined,
                  ),
                ),
                child: Text(
                  _formatDate(_endDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 84),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _next,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Next',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}