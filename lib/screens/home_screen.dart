import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:material_ui/material_ui.dart';

import '../services/format.dart';
import '../services/ledger.dart';
import '../services/ledger_store.dart';
import '../services/report.dart';
import '../services/settings.dart';
import '../services/sheets_sync.dart';
import '../services/sms_reader.dart';
import '../services/sync_settings.dart';
import 'categories_view.dart';
import 'export_screen.dart';
import 'report_view.dart';
import 'settings_view.dart';
import 'transaction_sheet.dart';
import 'transactions_view.dart';
import 'widgets.dart';

/// App shell: reads the inbox, keeps the user's edits and switches between
/// the four tabs.
class HomeScreen extends StatefulWidget {
  final AppSettings settings;
  const HomeScreen({super.key, required this.settings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  LedgerStore? _store;
  bool _loading = false;
  String? _error;
  DateTime? _lastLoaded;
  int _tab = 0;

  /// Index into the monthly summaries, shared by the report and categories tabs.
  int _month = 0;

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
      setState(() {
        _transactions = ts;
        _lastLoaded = DateTime.now();
        _month = 0;
      });
      _syncSheet();
    } on SmsPermissionDenied {
      setState(() => _error = 'برای خواندن پیامک‌های بانکی اجازه‌ی دسترسی به پیامک لازم است.');
    } catch (e) {
      setState(() => _error = 'خطا در خواندن پیامک‌ها: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Sends new transactions to the Google Sheet when automatic sending is on.
  /// Runs after the list is on screen and only reports what changed.
  Future<void> _syncSheet() async {
    final settings = await SyncSettings.open();
    if (!settings.sheetConfigured || !settings.autoSync) return;
    String? message;
    try {
      final r = await syncToSheet(_ledger, settings);
      if (r.added > 0) message = '${faDigits(r.added)} تراکنش جدید در گوگل شیت ثبت شد.';
    } catch (e) {
      message = 'ارسال به گوگل شیت انجام نشد: $e';
    }
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _edit(Transaction t) async {
    final ledger = _ledger;
    final result = await showModalBottomSheet<TransactionEdit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
    _syncSheet();
  }

  Future<void> _renameAccount(String account, String name) async {
    await _store?.setAccountName(account, name);
    setState(() {});
  }

  void _openExport(MonthlySummary? month) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExportScreen(ledger: _ledger, month: month)),
      );

  void _openCategory(String category, int year, int month) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryTransactionsScreen(
            category: category,
            year: year,
            month: month,
            ledger: () => _ledger,
            unit: widget.settings.unit,
            onEdit: _edit,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    final unit = widget.settings.unit;
    final months = monthlySummaries(ledger.transactions);
    final month = months.isEmpty ? 0 : _month.clamp(0, months.length - 1);
    final selectedMonth = months.isEmpty ? null : months[month];
    void selectMonth(int i) => setState(() => _month = i);

    final exportAction = IconButton(
      icon: const Icon(Icons.ios_share_rounded),
      tooltip: 'خروجی اکسل',
      onPressed: _transactions.isEmpty ? null : () => _openExport(selectedMonth),
    );
    final (title, actions) = switch (_tab) {
      0 => (
          'میرزا',
          [
            IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'خواندن دوباره', onPressed: _loading ? null : _load),
            exportAction,
          ]
        ),
      1 => ('گزارش ماهانه', [exportAction]),
      2 => ('دسته‌ها', <Widget>[]),
      _ => ('تنظیمات', <Widget>[]),
    };

    Widget body;
    if (_tab == 3) {
      body = SettingsView(
        ledger: ledger,
        settings: widget.settings,
        lastLoaded: _lastLoaded,
        onReload: _load,
        onRenameAccount: _renameAccount,
      );
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = EmptyState(
        icon: Icons.sms_failed_rounded,
        message: _error!,
        action: FilledButton.tonal(onPressed: _load, child: const Text('دوباره امتحان کن')),
      );
    } else if (_transactions.isEmpty) {
      body = EmptyState(
        icon: Icons.mark_email_unread_rounded,
        message: 'پیامک بانکی پیدا نشد.',
        action: FilledButton.tonal(onPressed: _load, child: const Text('خواندن دوباره')),
      );
    } else {
      body = switch (_tab) {
        0 => TransactionsView(ledger: ledger, unit: unit, onEdit: _edit),
        1 => ReportView(ledger: ledger, months: months, selected: month, onSelectMonth: selectMonth, unit: unit),
        _ => CategoriesView(
            ledger: ledger,
            months: months,
            selected: month,
            onSelectMonth: selectMonth,
            unit: unit,
            onOpen: _openCategory,
          ),
      };
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'تراکنش‌ها'),
          NavigationDestination(icon: Icon(Icons.donut_large_outlined), selectedIcon: Icon(Icons.donut_large_rounded), label: 'گزارش'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category_rounded), label: 'دسته‌ها'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'تنظیمات'),
        ],
      ),
    );
  }
}
