import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class SpendingBreakdownScreen extends StatelessWidget {
  const SpendingBreakdownScreen({super.key});

  Color _color(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFFF5961);
      case ExpenseCategory.transportation:
        return const Color(0xFF4285F4);
      case ExpenseCategory.supplies:
        return const Color(0xFF9C4DFF);
      case ExpenseCategory.misc:
        return const Color(0xFFFFAB00);
      default:
        return const Color(0xFF2FA17E);
    }
  }

  String _name(ExpenseCategory category) {
    if (category == ExpenseCategory.supplies) {
      return 'Projects';
    }
    return category.label;
  }

  String _date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final period = budget.currentPeriod;

    final used = budget.totalsByCategory.entries
        .where((entry) => entry.value > 0)
        .where((entry) => [
              ExpenseCategory.food,
              ExpenseCategory.transportation,
              ExpenseCategory.supplies,
              ExpenseCategory.misc,
            ].contains(entry.key))
        .toList();

    final total = used.fold(0.0, (sum, entry) => sum + entry.value);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Spending Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (period != null)
              Text(
                '${_date(period.startDate)} – ${_date(period.endDate)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            const SizedBox(height: 13),
            SizedBox(
              height: 205,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 53,
                      sectionsSpace: 2,
                      sections: used.isEmpty
                          ? [
                              PieChartSectionData(
                                value: 1,
                                color: const Color(0xFFDDE8E4),
                                radius: 35,
                                showTitle: false,
                              ),
                            ]
                          : used.map((entry) {
                              return PieChartSectionData(
                                value: entry.value,
                                color: _color(entry.key),
                                radius: 35,
                                showTitle: false,
                              );
                            }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Spent',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
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
            ...used.map((entry) {
              final percentage = total == 0 ? 0 : entry.value / total * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _color(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _name(entry.key),
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '₱${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 31,
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Top Spending Category',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (used.isNotEmpty)
                    Text(
                      _name(
                        used
                            .reduce((first, second) =>
                                first.value >= second.value ? first : second)
                            .key,
                      ),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  const SizedBox(width: 5),
                  const Icon(Icons.chevron_right_rounded, size: 19, color: AppTheme.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}