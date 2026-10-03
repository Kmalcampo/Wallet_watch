import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'add_goal_screen.dart';
import 'budget_period_completed_screen.dart';
import 'savings_screen.dart';
import 'set_budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _shownLowBalanceWarning = false;

  String _peso(double value) {
    return '₱${value.toStringAsFixed(2)}';
  }

  String _date(DateTime date) {
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

  String _getName() {
    final user =
        SupabaseService.client.auth.currentUser;

    final metadata = user?.userMetadata;

    final name =
        metadata?['full_name']?.toString();

    if (name != null && name.trim().isNotEmpty) {
      return name.trim().split(' ').first;
    }

    final email = user?.email;

    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();

    if (budget.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
          ),
        ),
      );
    }

    final period = budget.currentPeriod;

    if (period == null) {
      return const SetBudgetScreen();
    }

    if (period.isEnded) {
      return const BudgetPeriodCompletedScreen();
    }

    final spentRatio = budget.spentRatio;

    if (spentRatio >= 0.80 &&
        !_shownLowBalanceWarning) {
      _shownLowBalanceWarning = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) {
            _showLowBalanceDialog(
              context,
              budget.remainingBalance,
              period.daysRemaining,
            );
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        // Stack lets the decorative circles sit behind everything,
        // filling the screen even when the content above is short,
        // instead of leaving flat empty space under the last card.
        child: Stack(
          children: [
            const Positioned(
              bottom: -90,
              right: -70,
              child: _BackgroundBlob(size: 220),
            ),
            const Positioned(
              bottom: 140,
              left: -60,
              child: _BackgroundBlob(size: 140),
            ),
            ListView(
              padding: EdgeInsets.zero,
              children: [
                // GREEN HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    18,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good day, ${_getName()}! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Stay on track with your goals!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    25,
                  ),
                  child: Column(
                    children: [
                      // REMAINING BALANCE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8E4),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remaining Balance',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              _peso(
                                budget.remainingBalance,
                              ),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryDark,
                              ),
                            ),

                            const SizedBox(height: 7),

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value:
                                    1 - budget.spentRatio,
                                minHeight: 9,
                                backgroundColor:
                                    const Color(0xFFDDE9E3),
                                valueColor:
                                    const AlwaysStoppedAnimation(
                                  AppTheme.primaryLight,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'of ${_peso(period.allowanceAmount)} allowance',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color:
                                        AppTheme.textMuted,
                                  ),
                                ),

                                TextButton.icon(
                                  onPressed: () =>
                                      _showAddMoneyDialog(
                                    context,
                                    budget,
                                  ),
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Add Money',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        AppTheme.primary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize
                                            .shrinkWrap,
                                    textStyle:
                                        const TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // THREE SMALL CARDS — Spent, Saved, Safe/Day
                      Row(
                        children: [
                          Expanded(
                            child: _SmallCard(
                              icon:
                                  Icons.shopping_bag_rounded,
                              iconColor:
                                  const Color(0xFFFF5961),
                              title: 'Spent',
                              value:
                                  _peso(budget.totalSpent),
                              valueColor:
                                  const Color(0xFFFF4E4E),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _SmallCard(
                              icon: Icons.savings_rounded,
                              iconColor:
                                  const Color(0xFFFFAB00),
                              title: 'Saved',
                              value:
                                  _peso(budget.totalSaved),
                              valueColor:
                                  const Color(0xFFFFAB00),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      _SmallCard(
                        icon: Icons.calendar_today_rounded,
                        iconColor: AppTheme.primary,
                        title: 'Safe to Spend / Day',
                        value: _peso(
                          budget.safeToSpendPerDay,
                        ),
                        valueColor: AppTheme.primaryDark,
                        fullWidth: true,
                      ),

                      const SizedBox(height: 10),

                      // BUDGET PERIOD
                      _InfoCard(
                        icon:
                            Icons.calendar_month_rounded,
                        iconColor: AppTheme.primary,
                        title: 'Budget Period',
                        subtitle:
                            '${_date(period.startDate)} – ${_date(period.endDate)}',
                        extra:
                            '${period.daysRemaining} ${period.daysRemaining == 1 ? 'day' : 'days'} left',
                      ),

                      const SizedBox(height: 10),

                      // TODAY
                      _InfoCard(
                        icon:
                            Icons.wb_sunny_rounded,
                        iconColor:
                            const Color(0xFFFFAB00),
                        title: "Today's Spending",
                        subtitle:
                            _peso(budget.todaySpent),
                        extra:
                            'Remaining ${_peso(budget.remainingBalance)}',
                        // No onTap — Home is view-only now. Adding an
                        // expense happens from its own dedicated tab.
                      ),

                      const SizedBox(height: 12),

                      // TIP
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5EE),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_rounded,
                              color: Color(0xFFFFB400),
                              size: 25,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Keep going!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w900,
                                      color:
                                          AppTheme.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "You're on track with your goals.",
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // YOUR GOALS PREVIEW — fills remaining space
                      // with something useful instead of blank padding.
                      _GoalsPreview(goals: budget.goals),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMoneyDialog(
    BuildContext context,
    BudgetProvider budget,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Add Money',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  prefixText: '₱ ',
                  hintText: '0.00',
                  labelText: 'Amount',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final amount =
                              double.tryParse(
                            controller.text
                                .trim(),
                          );

                          if (amount == null ||
                              amount <= 0) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a valid amount.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await budget
                                .addMoneyToAllowance(
                              amount,
                            );

                            if (dialogContext
                                .mounted) {
                              Navigator.pop(
                                dialogContext,
                              );
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_peso(amount)} added to your allowance.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not add money: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  void _showLowBalanceDialog(
    BuildContext context,
    double remaining,
    int daysLeft,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5A5F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Low Balance',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  'You only have ${_peso(remaining)} remaining with $daysLeft ${daysLeft == 1 ? 'day' : 'days'} left in this budget period.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 17),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A soft, non-interactive circle used purely to give the page some
/// visual depth so short content doesn't look like something is
/// missing. Matches the circles used on WelcomeScreen.
class _BackgroundBlob extends StatelessWidget {
  final double size;
  const _BackgroundBlob({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Fills the space below the tip banner with something useful: a
/// preview of the student's top 1-2 savings goals, or a prompt to
/// create one if they haven't yet.
class _GoalsPreview extends StatelessWidget {
  final List goals;
  const _GoalsPreview({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Goals',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            if (goals.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavingsScreen()),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (goals.isEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddGoalScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFE2E8E4),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Set your first savings goal",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Something to save up for, like headphones or shoes.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          for (final goal in goals.take(2))
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(goal.emoji, style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8E4),
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(goal.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _SmallCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color valueColor;
  final bool fullWidth;

  const _SmallCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.valueColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!fullWidth) {
      // Stacked layout (icon above text) for the two-up row.
      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFE2E8E4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8E4),
        ),
      ),
      child: content,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String extra;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.extra,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFE2E8E4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    extra,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}