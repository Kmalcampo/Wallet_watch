import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import 'add_goal_screen.dart';

/// Whole pesos show without decimals (₱500), otherwise two decimals.
String _peso(double v) {
  return v == v.roundToDouble()
      ? '₱${v.toStringAsFixed(0)}'
      : '₱${v.toStringAsFixed(2)}';
}

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  void _openNewGoal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<BudgetProvider>().goals;

    final totalSaved = goals.fold(0.0, (sum, g) => sum + g.savedAmount);
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final completed = goals.where((g) => g.isComplete).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Savings Goals'),
      ),
      body: goals.isEmpty
          ? _EmptyState(onAddGoal: () => _openNewGoal(context))
          : ListView(
              // Extra bottom padding so the last card isn't hidden
              // behind the floating "New Goal" button.
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                _SummaryCard(
                  totalSaved: totalSaved,
                  totalTarget: totalTarget,
                  completed: completed,
                  goalCount: goals.length,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Goals',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${goals.length} ${goals.length == 1 ? 'goal' : 'goals'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final goal in goals) _GoalCard(goal: goal),
              ],
            ),
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openNewGoal(context),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Goal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalSaved;
  final double totalTarget;
  final int completed;
  final int goalCount;

  const _SummaryCard({
    required this.totalSaved,
    required this.totalTarget,
    required this.completed,
    required this.goalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTarget <= 0
        ? 0.0
        : (totalSaved / totalTarget).clamp(0.0, 1.0);

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Saved',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completed of $goalCount reached',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _peso(totalSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% of ${_peso(totalTarget)} total target',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();
    final remaining = goal.targetAmount - goal.savedAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showGoalActions(context, goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      goal.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.isComplete
                              ? 'Goal reached 🎉'
                              : '${_peso(remaining)} to go',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                goal.isComplete ? FontWeight.w600 : FontWeight.w400,
                            color: goal.isComplete
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE6EEEA),
                  valueColor: AlwaysStoppedAnimation(
                    goal.isComplete ? AppTheme.primaryLight : AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _peso(goal.savedAmount),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          TextSpan(
                            text: '  of ${_peso(goal.targetAmount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!goal.isComplete)
                    TextButton.icon(
                      onPressed: () => _promptAddFunds(context, goal),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add funds'),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.10),
                        foregroundColor: AppTheme.primary,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddGoal;

  const _EmptyState({required this.onAddGoal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_rounded,
                size: 44,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No goals yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick something to save up for, like new shoes, a gadget, or a school event.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 230,
              height: 52,
              child: ElevatedButton(
                onPressed: onAddGoal,
                child: const Text('Set your first goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showGoalActions(BuildContext context, SavingsGoal goal) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
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
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      goal.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_peso(goal.savedAmount)} of ${_peso(goal.targetAmount)}',
                          style: const TextStyle(
                            fontSize: 13,
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
                  Icons.add_circle_outline_rounded,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'Add funds',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _promptAddFunds(context, goal);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.textDark,
                ),
                title: const Text(
                  'Edit goal',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddGoalScreen(existingGoal: goal),
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
                  'Delete goal',
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
                        'Delete this goal?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      content: Text(
                        '${goal.emoji} ${goal.title}\n\n'
                        'Money you already added stays counted as saved in '
                        'your history.',
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
                    context.read<BudgetProvider>().deleteGoal(goal.id);
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

Future<void> _promptAddFunds(BuildContext context, SavingsGoal goal) async {
  final amount = await showDialog<double>(
    context: context,
    builder: (_) => _AddFundsDialog(goal: goal),
  );

  if (amount == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);

  try {
    final error =
        await context.read<BudgetProvider>().addFundsToGoal(goal.id, amount);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? '${_peso(amount)} added to "${goal.title}".',
        ),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not add funds: $e')),
    );
  }
}

/// Owns its own TextEditingController so it's disposed properly when
/// the dialog closes.
class _AddFundsDialog extends StatefulWidget {
  final SavingsGoal goal;

  const _AddFundsDialog({required this.goal});

  @override
  State<_AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends State<_AddFundsDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_controller.text.trim());

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Add funds',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.goal.emoji}  ${widget.goal.title}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              prefixText: '₱ ',
              hintText: '0.00',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'This comes out of your current allowance.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Add'),
        ),
      ],
    );
  }
}