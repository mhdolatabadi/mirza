import 'dart:io';

import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/excel_export.dart';
import '../services/report.dart';
import '../services/sms_reader.dart';

final _rial = NumberFormat.decimalPattern('en');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ts = await readBankTransactions();
      setState(() => _transactions = ts);
    } on SmsPermissionDenied {
      setState(() => _error = 'برای خواندن پیامک‌های بانکی اجازه‌ی دسترسی به پیامک لازم است.');
    } catch (e) {
      setState(() => _error = 'خطا در خواندن پیامک‌ها: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hesabdar.xlsx');
    await file.writeAsBytes(buildLedger(_transactions));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], title: 'گزارش مالی'));
  }

  @override
  Widget build(BuildContext context) {
    final summaries = monthlySummaries(_transactions);
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابدار'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'خواندن دوباره', onPressed: _loading ? null : _load),
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'خروجی اکسل',
            onPressed: _transactions.isEmpty ? null : _export,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _transactions.isEmpty
                  ? const Center(child: Text('پیامک بانکی پیدا نشد.'))
                  : ListView(
                      children: [
                        if (summaries.isNotEmpty) _SummaryCard(summaries.first),
                        for (final t in _transactions) _TransactionTile(t),
                      ],
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MonthlySummary s;
  const _SummaryCard(this.s);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ماه ${s.label}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('واریز: ${_rial.format(s.income)} ریال'),
            Text('برداشت: ${_rial.format(s.expense)} ریال'),
            Text('خالص: ${_rial.format(s.net)} ریال'),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction t;
  const _TransactionTile(this.t);

  @override
  Widget build(BuildContext context) {
    final credit = t.type == TransactionType.credit;
    return ListTile(
      leading: Icon(credit ? Icons.south_west : Icons.north_east, color: credit ? Colors.green : Colors.red),
      title: Text('${credit ? '+' : '-'}${_rial.format(t.amount)} ریال'),
      subtitle: Text([bankLabel(t), t.description, '${t.date ?? ''} ${t.time ?? ''}']
          .where((s) => s != null && s.trim().isNotEmpty)
          .join(' · ')),
      trailing: t.balance == null ? null : Text(_rial.format(t.balance)),
    );
  }
}
