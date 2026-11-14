import 'package:material_ui/material_ui.dart';

import '../services/format.dart';
import '../services/ledger.dart';
import '../services/settings.dart';

/// Account names, display unit, theme and re-reading the inbox.
class SettingsView extends StatelessWidget {
  final Ledger ledger;
  final AppSettings settings;
  final DateTime? lastLoaded;
  final VoidCallback onReload;
  final Future<void> Function(String account, String name) onRenameAccount;

  const SettingsView({
    super.key,
    required this.ledger,
    required this.settings,
    required this.lastLoaded,
    required this.onReload,
    required this.onRenameAccount,
  });

  Future<void> _rename(BuildContext context, String account) async {
    final controller = TextEditingController(text: ledger.accountNames[account]);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('نام حساب ${faDigits(account)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'مثلاً اسم بانک'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('ذخیره')),
        ],
      ),
    );
    controller.dispose();
    if (name != null) await onRenameAccount(account, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = {for (final t in ledger.transactions) ?t.account}.toList()..sort();
    final loaded = lastLoaded;

    Widget section(String title, List<Widget> children) => Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                ...children,
              ],
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        section('حساب‌ها', [
          if (accounts.isEmpty)
            const ListTile(title: Text('هنوز پیامکی با شماره‌ی حساب نیامده.')),
          for (final a in accounts)
            ListTile(
              leading: Icon(ledger.accountNames.containsKey(a) ? Icons.account_balance_rounded : Icons.help_outline_rounded),
              title: Text(ledger.accountNames[a] ?? 'بدون نام'),
              subtitle: Text(a, textDirection: TextDirection.ltr, textAlign: TextAlign.end),
              trailing: const Icon(Icons.edit_rounded),
              onTap: () => _rename(context, a),
            ),
        ]),
        const SizedBox(height: 12),
        section('نمایش', [
          ListTile(
            leading: const Icon(Icons.payments_rounded),
            title: const Text('واحد مبلغ'),
            subtitle: const Text('اکسل همیشه ریالی است'),
            trailing: SegmentedButton<MoneyUnit>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: MoneyUnit.rial, label: Text('ریال')),
                ButtonSegment(value: MoneyUnit.toman, label: Text('تومان')),
              ],
              selected: {settings.unit},
              onSelectionChanged: (s) => settings.setUnit(s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.dark_mode_rounded),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, label: Text('روشن')),
                      ButtonSegment(value: ThemeMode.system, label: Text('سیستم')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('تیره')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => settings.setThemeMode(s.first),
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sms_rounded),
            title: const Text('خواندن دوباره‌ی پیامک‌ها'),
            subtitle: loaded == null
                ? null
                : Text('آخرین بار: ${faDigits('${loaded.hour}:${loaded.minute.toString().padLeft(2, '0')}')}'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: onReload,
          ),
        ),
      ],
    );
  }
}
