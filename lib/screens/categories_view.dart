import 'package:flutter/material.dart';

import '../services/categories.dart';
import '../services/format.dart';
import '../services/ledger.dart';
import '../services/report.dart';
import '../theme.dart';
import 'widgets.dart';

/// One card per category with the month's total and transaction count.
class CategoriesView extends StatelessWidget {
  final Ledger ledger;
  final List<MonthlySummary> months;
  final int selected;
  final ValueChanged<int> onSelectMonth;
  final MoneyUnit unit;
  final void Function(String category, int year, int month) onOpen;

  const CategoriesView({
    super.key,
    required this.ledger,
    required this.months,
    required this.selected,
    required this.onSelectMonth,
    required this.unit,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const EmptyState(icon: Icons.category_rounded, message: 'تراکنش تاریخ‌دار پیدا نشد.');
    }
    final m = months[selected];
    final counts = <String, (int, int)>{};
    for (final t in ledger.transactions) {
      if (t.date?.year != m.year || t.date?.month != m.month) continue;
      final c = ledger.categoryOf(t);
      final (n, credits) = counts[c] ?? (0, 0);
      counts[c] = (n + 1, credits + (t.signedAmount > 0 ? 1 : 0));
    }
    final totals = {for (final s in categorySummaries(ledger, m.year, m.month)) s.category: s};

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        MonthChips(months: [for (final s in months) (s.year, s.month)], selected: selected, onSelected: onSelectMonth),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 140,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final c in categories)
                _CategoryCard(
                  category: c,
                  summary: totals[c],
                  count: counts[c]?.$1 ?? 0,
                  credits: counts[c]?.$2 ?? 0,
                  unit: unit,
                  onTap: counts.containsKey(c) ? () => onOpen(c, m.year, m.month) : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final CategorySummary? summary;
  final int count;
  final int credits;
  final MoneyUnit unit;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.category,
    required this.summary,
    required this.count,
    required this.credits,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    // Mostly-income categories (salary, interest) show the credit total.
    final incomeSide = s != null && s.income > s.expense;
    final amount = s == null ? '—' : incomeSide ? formatMoney(s.income, unit, signed: true) : formatMoney(s.expense, unit);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryBadge(category, size: 36),
              const Spacer(),
              Text(category, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                amount,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: incomeSide ? MirzaColors.of(context).income : null,
                ),
              ),
              Text(
                count == 0
                    ? 'بدون تراکنش'
                    : credits > 0 && credits < count
                        ? '${faDigits(count)} تراکنش · ${faDigits(credits)} واریز'
                        : '${faDigits(count)} تراکنش',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
