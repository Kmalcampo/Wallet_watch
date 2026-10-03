import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import 'add_goal_screen.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<BudgetProvider>().goals;
    final featured = goals.isNotEmpty ? goals.first : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Savings Goal')),
      body: goals.isEmpty
          ? _EmptyState(
              onAddGoal: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddGoalScreen()),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _FeaturedGoalCard(goal: featured!),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
                    ),
                    child: const Text('Set a Goal'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Goals',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                for (final goal in goals) _GoalListCard(goal: goal),
              ],
            ),
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddGoalScreen()),
              ),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No goals yet.',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              "Set something you're saving up for.",
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: onAddGoal,
                child: const Text('Set a Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  const _FeaturedGoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showGoalActions(context, goal),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(goal.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '₱${goal.savedAmount.toStringAsFixed(0)} / ₱${goal.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8E4),
                      color: goal.isComplete ? AppTheme.primary : AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalListCard extends StatelessWidget {
  final SavingsGoal goal;
  const _GoalListCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showGoalActions(context, goal),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(goal.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    Text(
                      '₱${goal.savedAmount.toStringAsFixed(0)} / ₱${goal.targetAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8E4),
                        color: goal.isComplete ? AppTheme.primary : AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showGoalActions(BuildContext context, SavingsGoal goal) {
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add Funds'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showAddFundsDialog(context, goal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Goal'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddGoalScreen(existingGoal: goal)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Goal', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete this goal?'),
                    content: Text('${goal.emoji} ${goal.title} — this can\'t be undone.'),
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
                  context.read<BudgetProvider>().deleteGoal(goal.id);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showAddFundsDialog(BuildContext context, SavingsGoal goal) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Add funds to ${goal.title}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₱ ', hintText: '0.00'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                Navigator.pop(dialogContext);
                return;
              }
              Navigator.pop(dialogContext);

              final error =
                  await context.read<BudgetProvider>().addFundsToGoal(goal.id, amount);

              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}