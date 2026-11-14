import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/excel_export.dart';
import '../services/format.dart';
import '../services/ledger.dart';
import '../services/report.dart';
import '../theme.dart';

/// Pick a period, see what the workbook holds, then build and share it.
class ExportScreen extends StatefulWidget {
  final Ledger ledger;

  /// The month to offer first, usually the one open in the report.
  final MonthlySummary? month;

  const ExportScreen({super.key, required this.ledger, this.month});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late bool _monthOnly = widget.month != null;
  bool _busy = false;

  Ledger get _selected {
    final m = widget.month;
    if (!_monthOnly || m == null) return widget.ledger;
    return Ledger(
      [
        for (final t in widget.ledger.transactions)
          if (t.date?.year == m.year && t.date?.month == m.month) t,
      ],
      categoryOverrides: widget.ledger.categoryOverrides,
      accountNames: widget.ledger.accountNames,
    );
  }

  String get _fileName {
    final m = widget.month;
    if (!_monthOnly || m == null) return 'mirza.xlsx';
    return 'mirza-${m.year}-${m.month.toString().padLeft(2, '0')}.xlsx';
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(buildLedger(_selected));
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], title: 'گزارش مالی'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.month;
    final all = monthlySummaries(widget.ledger.transactions);
    return Scaffold(
      appBar: AppBar(title: const Text('خروجی اکسل')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: RadioGroup<bool>(
                groupValue: _monthOnly,
                onChanged: (v) => setState(() => _monthOnly = v ?? false),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('بازه', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (m != null)
                      RadioListTile<bool>(
                        value: true,
                        secondary: const Icon(Icons.calendar_month_rounded),
                        title: Text(monthTitle(m.year, m.month)),
                        subtitle: Text('${faDigits(m.count)} تراکنش'),
                      ),
                    RadioListTile<bool>(
                      value: false,
                      secondary: const Icon(Icons.date_range_rounded),
                      title: const Text('همه‌ی ماه‌ها'),
                      subtitle: Text(
                        all.isEmpty
                            ? '${faDigits(widget.ledger.transactions.length)} تراکنش'
                            : '${faDigits(widget.ledger.transactions.length)} تراکنش از ${monthNames[all.last.month - 1]} ${faDigits(all.last.year)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('داخل فایل', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: MirzaColors.of(context).income.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.table_view_rounded, color: MirzaColors.of(context).income),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_fileName, textDirection: TextDirection.ltr, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final s in [transactionsSheet, summarySheet, categorySheet])
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
                                    child: Text(s, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'مبلغ‌ها به ریال و علامت‌دارند (برداشت منفی)، پس ستون مبلغ مستقیم جمع می‌خورد.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _busy || _selected.transactions.isEmpty ? null : _share,
          icon: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.ios_share_rounded),
          label: const Text('ساخت و اشتراک فایل'),
        ),
      ),
    );
  }
}
