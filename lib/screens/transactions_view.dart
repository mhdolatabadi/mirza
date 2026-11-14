import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:material_ui/material_ui.dart';

import '../services/day_groups.dart';
import '../services/format.dart';
import '../services/ledger.dart';
import '../services/report.dart';
import '../services/sms_reader.dart';
import 'widgets.dart';

enum _TypeFilter { all, credit, debit }

/// Balance card, filter chips and the transaction list grouped by day.
class TransactionsView extends StatefulWidget {
  final Ledger ledger;
  final MoneyUnit unit;
  final ValueChanged<Transaction> onEdit;

  const TransactionsView({super.key, required this.ledger, required this.unit, required this.onEdit});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  _TypeFilter _type = _TypeFilter.all;
  String? _account;

  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger;
    final accounts = {for (final t in ledger.transactions) ledger.bankLabel(t)}..remove('');
    if (_account != null && !accounts.contains(_account)) _account = null;

    final shown = ledger.transactions.where((t) {
      if (_type == _TypeFilter.credit && t.type != TransactionType.credit) return false;
      if (_type == _TypeFilter.debit && t.type != TransactionType.debit) return false;
      return _account == null || ledger.bankLabel(t) == _account;
    });
    final groups = groupByDay(shown);
    final now = DateTime.now();
    final today = toJalaliDate(now);
    final yesterday = toJalaliDate(now.subtract(const Duration(days: 1)));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(child: _BalanceCard(ledger: ledger, unit: widget.unit)),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (f, label) in [
                  (_TypeFilter.all, 'همه'),
                  (_TypeFilter.credit, 'واریز'),
                  (_TypeFilter.debit, 'برداشت'),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(label: Text(label), selected: _type == f, onSelected: (_) => setState(() => _type = f)),
                  ),
                if (accounts.length > 1)
                  for (final a in accounts)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(a),
                        selected: _account == a,
                        onSelected: (on) => setState(() => _account = on ? a : null),
                      ),
                    ),
              ],
            ),
          ),
        ),
        if (groups.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.filter_alt_off_rounded, message: 'تراکنشی با این فیلتر نیست.'),
          ),
        for (final g in groups) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: _DayHeader(group: g, title: g.date == null ? 'بدون تاریخ' : dayTitle(g.date!, today, yesterday), unit: widget.unit),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Column(
                    children: [
                      for (var i = 0; i < g.transactions.length; i++) ...[
                        if (i > 0) const Divider(),
                        TransactionTile(
                          transaction: g.transactions[i],
                          ledger: ledger,
                          unit: widget.unit,
                          onTap: () => widget.onEdit(g.transactions[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DayGroup group;
  final String title;
  final MoneyUnit unit;
  const _DayHeader({required this.group, required this.title, required this.unit});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        );
    return Row(
      children: [
        Expanded(child: Text(title, style: style)),
        Text(formatMoney(group.net, unit, signed: true), textDirection: TextDirection.ltr, style: style),
      ],
    );
  }
}

/// Ink card: balance from the newest SMS that reports one, and this month's
/// credits and debits.
class _BalanceCard extends StatelessWidget {
  final Ledger ledger;
  final MoneyUnit unit;
  const _BalanceCard({required this.ledger, required this.unit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = scheme.onPrimary;
    final withBalance = ledger.transactions.where((t) => t.balance != null).firstOrNull;
    final month = monthlySummaries(ledger.transactions).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            withBalance == null ? 'مانده' : 'مانده‌ی آخرین پیامک · ${ledger.bankLabel(withBalance)}',
            style: text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                withBalance == null ? '—' : formatMoney(withBalance.balance!, unit),
                style: text.headlineMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(unitLabel(unit), style: text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8))),
            ],
          ),
          if (month != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Split('واریز ${monthNames[month.month - 1]}', formatMoney(month.income, unit, signed: true), fg)),
                const SizedBox(width: 8),
                Expanded(child: _Split('برداشت ${monthNames[month.month - 1]}', formatMoney(-month.expense, unit, signed: true), fg)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Split extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  const _Split(this.label, this.value, this.fg);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: fg.withValues(alpha: 0.85))),
          Text(value, textDirection: TextDirection.ltr, style: text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Transactions of one category in one month, opened from the categories tab.
class CategoryTransactionsScreen extends StatefulWidget {
  final String category;
  final int year;
  final int month;
  final Ledger Function() ledger;
  final MoneyUnit unit;
  final Future<void> Function(Transaction) onEdit;

  const CategoryTransactionsScreen({
    super.key,
    required this.category,
    required this.year,
    required this.month,
    required this.ledger,
    required this.unit,
    required this.onEdit,
  });

  @override
  State<CategoryTransactionsScreen> createState() => _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState extends State<CategoryTransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger();
    final ts = [
      for (final t in ledger.transactions)
        if (t.date?.year == widget.year && t.date?.month == widget.month && ledger.categoryOf(t) == widget.category) t,
    ];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category} · ${monthTitle(widget.year, widget.month)}')),
      body: ts.isEmpty
          ? const EmptyState(icon: Icons.inbox_rounded, message: 'تراکنشی در این دسته نمانده.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Column(
                      children: [
                        for (var i = 0; i < ts.length; i++) ...[
                          if (i > 0) const Divider(),
                          TransactionTile(
                            transaction: ts[i],
                            ledger: ledger,
                            unit: widget.unit,
                            onTap: () async {
                              await widget.onEdit(ts[i]);
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
