import 'dart:io';

import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/excel_export.dart';
import '../services/ledger.dart';
import '../services/ledger_store.dart';
import '../services/sms_reader.dart';
import 'report_view.dart';
import 'transaction_sheet.dart';

final rialFormat = NumberFormat.decimalPattern('en');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  LedgerStore? _store;
  bool _loading = false;
  String? _error;

  Ledger get _ledger => Ledger(
        _transactions,
        categoryOverrides: _store?.categoryOverrides ?? const {},
        accountNames: _store?.accountNames ?? const {},
      );

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
      _store ??= await LedgerStore.open();
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
    await file.writeAsBytes(buildLedger(_ledger));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], title: 'گزارش مالی'));
  }

  Future<void> _edit(Transaction t) async {
    final ledger = _ledger;
    final result = await showModalBottomSheet<TransactionEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionSheet(
        transaction: t,
        category: ledger.categoryOf(t),
        accountName: t.account == null ? null : ledger.accountNames[t.account],
      ),
    );
    final store = _store;
    if (result == null || store == null) return;
    await store.setCategory(t.raw, result.category);
    if (t.account != null && result.accountName != null) {
      await store.setAccountName(t.account!, result.accountName!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(tabs: [Tab(text: 'تراکنش‌ها'), Tab(text: 'گزارش')]),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
                : _transactions.isEmpty
                    ? const Center(child: Text('پیامک بانکی پیدا نشد.'))
                    : TabBarView(
                        children: [
                          ListView(
                            children: [
                              for (final t in _transactions)
                                _TransactionTile(t, ledger, onTap: () => _edit(t)),
                            ],
                          ),
                          ReportView(ledger: ledger),
                        ],
                      ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction t;
  final Ledger ledger;
  final VoidCallback onTap;
  const _TransactionTile(this.t, this.ledger, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final credit = t.type == TransactionType.credit;
    return ListTile(
      onTap: onTap,
      leading: Icon(credit ? Icons.south_west : Icons.north_east, color: credit ? Colors.green : Colors.red),
      title: Text('${credit ? '+' : '-'}${rialFormat.format(t.amount)} ریال'),
      subtitle: Text([ledger.categoryOf(t), ledger.bankLabel(t), t.description, '${t.date ?? ''} ${t.time ?? ''}']
          .where((s) => s != null && s.trim().isNotEmpty)
          .join(' · ')),
      trailing: t.balance == null ? null : Text(rialFormat.format(t.balance)),
    );
  }
}
