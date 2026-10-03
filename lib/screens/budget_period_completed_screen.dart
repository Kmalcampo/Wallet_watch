import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class BudgetPeriodCompletedScreen
    extends StatelessWidget {
  const BudgetPeriodCompletedScreen({
    super.key,
  });

  String _peso(double value) {
    return '₱${value.toStringAsFixed(0)}';
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

  @override
  Widget build(BuildContext context) {
    final budget =
        context.watch<BudgetProvider>();

    final period = budget.currentPeriod;

    if (period == null) {
      return const SizedBox.shrink();
    }

    final difference =
        budget.totalSpent -
            period.allowanceAmount;

    final isOverBudget = difference > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            24,
            16,
            30,
          ),
          children: [
            const Center(
              child: _ConfettiCheck(),
            ),

            const SizedBox(height: 15),

            const Text(
              'Budget Period Completed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              '${_date(period.startDate)} – ${_date(period.endDate)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color:
                      const Color(0xFFE2E8E4),
                ),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    title: 'Allowance',
                    value: _peso(
                      period.allowanceAmount,
                    ),
                  ),

                  const Divider(
                    height: 1,
                  ),

                  _SummaryRow(
                    title: 'Total Spent',
                    value: _peso(
                      budget.totalSpent,
                    ),
                  ),

                  const Divider(
                    height: 1,
                  ),

                  _SummaryRow(
                    title: isOverBudget
                        ? 'Over Budget'
                        : 'Remaining',
                    value: isOverBudget
                        ? _peso(difference)
                        : _peso(
                            period.allowanceAmount -
                                budget.totalSpent,
                          ),
                    danger: isOverBudget,
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding:
                        const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFF4DD),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .lightbulb_outline_rounded,
                          color:
                              Color(0xFFFFB400),
                          size: 26,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            isOverBudget
                                ? 'You went ${_peso(difference)} over your allowance. Keep tracking your expenses!'
                                : 'Great job! You stayed within your allowance. Keep building those good habits!',
                            style:
                                const TextStyle(
                              fontSize: 10,
                              color:
                                  AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context
                      .read<BudgetProvider>()
                      .clearPeriodLocally();
                },
                child: const Text(
                  'Start New Allowance',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'View History',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow
    extends StatelessWidget {
  final String title;
  final String value;
  final bool danger;

  const _SummaryRow({
    required this.title,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: danger
                  ? const Color(0xFFFF5961)
                  : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiCheck
    extends StatelessWidget {
  const _ConfettiCheck();

  @override
  Widget build(BuildContext context) {
    const positions = [
      Offset(8, 15),
      Offset(72, 9),
      Offset(17, 67),
      Offset(73, 61),
      Offset(29, 1),
      Offset(57, 3),
      Offset(3, 43),
      Offset(84, 38),
      Offset(16, 29),
      Offset(67, 30),
    ];

    const colors = [
      Color(0xFF36A64F),
      Color(0xFFFFB400),
      Color(0xFF4285F4),
      Color(0xFF9C4DFF),
    ];

    return SizedBox(
      width: 95,
      height: 95,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0;
              i < positions.length;
              i++)
            Positioned(
              left: positions[i].dx,
              top: positions[i].dy,
              child: Icon(
                i.isEven
                    ? Icons.circle
                    : Icons.auto_awesome,
                color: colors[
                    i % colors.length],
                size: 7,
              ),
            ),

          Container(
            width: 65,
            height: 65,
            decoration:
                const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 43,
            ),
          ),
        ],
      ),
    );
  }
}