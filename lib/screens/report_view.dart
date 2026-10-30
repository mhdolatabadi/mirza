import 'package:flutter/material.dart';

import '../services/ledger.dart';
import '../services/report.dart';
import 'home_screen.dart';

/// Monthly totals and per-category breakdown for a selectable month.
class ReportView extends StatefulWidget {
  final Ledger ledger;
  const ReportView({super.key, required this.ledger});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final months = monthlySummaries(widget.ledger.transactions);
    if (months.isEmpty) return const Center(child: Text('تراکنش تاریخ‌دار پیدا نشد.'));
    final m = months[_selected.clamp(0, months.length - 1)];
    final cats = categorySummaries(widget.ledger, m.year, m.month);
    final maxExpense = cats.fold(1, (a, c) => c.expense > a ? c.expense : a);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButton<int>(
          value: months.indexOf(m),
          isExpanded: true,
          items: [
            for (var i = 0; i < months.length; i++) DropdownMenuItem(value: i, child: Text('ماه ${months[i].label}')),
          ],
          onChanged: (i) => setState(() => _selected = i ?? 0),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('واریز: ${rialFormat.format(m.income)} ریال'),
                Text('برداشت: ${rialFormat.format(m.expense)} ریال'),
                Text('خالص: ${rialFormat.format(m.net)} ریال', style: theme.textTheme.titleMedium),
                Text('${m.count} تراکنش', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('برداشت بر اساس دسته', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final c in cats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.category)),
                    Text(rialFormat.format(c.expense)),
                    if (c.income > 0) Text('  (+${rialFormat.format(c.income)})', style: const TextStyle(color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: c.expense / maxExpense),
              ],
            ),
          ),
      ],
    );
  }
}
