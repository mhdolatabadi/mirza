import 'dart:math';

import 'package:flutter/material.dart';

import '../services/format.dart';
import '../services/ledger.dart';
import '../services/report.dart';
import '../theme.dart';
import 'widgets.dart';

/// Monthly totals, change against the previous month and a donut of debits
/// per category for the month picked in [months].
class ReportView extends StatelessWidget {
  final Ledger ledger;
  final List<MonthlySummary> months;
  final int selected;
  final ValueChanged<int> onSelectMonth;
  final MoneyUnit unit;

  const ReportView({
    super.key,
    required this.ledger,
    required this.months,
    required this.selected,
    required this.onSelectMonth,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const EmptyState(icon: Icons.donut_large_rounded, message: 'تراکنش تاریخ‌دار پیدا نشد.');
    }
    final m = months[selected];
    final previous = selected + 1 < months.length ? months[selected + 1] : null;
    final cats = categorySummaries(ledger, m.year, m.month).where((c) => c.expense > 0).toList();
    final theme = Theme.of(context);
    final colors = MirzaColors.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        MonthChips(months: [for (final s in months) (s.year, s.month)], selected: selected, onSelected: onSelectMonth),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('خالص ماه', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                          if (previous != null && previous.expense > 0) _ChangePill(current: m.expense, previous: previous),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: formatMoney(m.net, unit, signed: true),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: m.net >= 0 ? colors.income : colors.expense,
                            ),
                          ),
                          TextSpan(text: '  ${unitLabel(unit)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _Stat('واریز', formatCompact(m.income, unit))),
                          const SizedBox(width: 8),
                          Expanded(child: _Stat('برداشت', formatCompact(m.expense, unit))),
                          const SizedBox(width: 8),
                          Expanded(child: _Stat('تراکنش', faDigits(m.count))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (cats.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('برداشت به تفکیک دسته', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox.square(
                              dimension: 132,
                              child: CustomPaint(
                                painter: _DonutPainter(
                                  [for (final c in cats) (c.expense.toDouble(), colors.categoryColor(c.category))],
                                  track: theme.colorScheme.outlineVariant,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(formatCompact(m.expense, unit), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      Text(unitLabel(unit), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  for (final c in cats.take(6))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: colors.categoryColor(c.category),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(c.category, style: theme.textTheme.bodySmall)),
                                          Text(
                                            '${faDigits((c.expense * 100 / m.expense).round())}٪',
                                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        for (final c in cats) _CategoryBar(c, max: cats.first.expense, unit: unit),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Debits against last month: green when spending went down.
class _ChangePill extends StatelessWidget {
  final int current;
  final MonthlySummary previous;
  const _ChangePill({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final colors = MirzaColors.of(context);
    final pct = ((current - previous.expense) * 100 / previous.expense).round();
    final less = pct <= 0;
    final color = less ? colors.income : colors.expense;
    final prevName = monthNames[previous.month - 1];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
      child: Text(
        less ? '${faDigits(-pct)}٪ کم‌خرج‌تر از $prevName' : '${faDigits(pct)}٪ پرخرج‌تر از $prevName',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final CategorySummary c;
  final int max;
  final MoneyUnit unit;
  const _CategoryBar(this.c, {required this.max, required this.unit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = MirzaColors.of(context).categoryColor(c.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              CategoryBadge(c.category, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(c.category, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
              Text(formatMoney(c.expense, unit), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: c.expense / max,
              minHeight: 6,
              color: color,
              backgroundColor: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> slices;
  final Color track;
  _DonutPainter(this.slices, {required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(arc, 0, 2 * pi, false, paint..color = track);

    final total = slices.fold(0.0, (s, e) => s + e.$1);
    if (total == 0) return;
    // Small gap between slices, unless there is only one.
    final gap = slices.length > 1 ? 0.03 : 0.0;
    var start = -pi / 2;
    for (final (value, color) in slices) {
      final sweep = value / total * 2 * pi;
      if (sweep > gap) canvas.drawArc(arc, start + gap / 2, sweep - gap, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices || old.track != track;
}
