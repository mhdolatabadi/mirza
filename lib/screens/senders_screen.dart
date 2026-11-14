import 'package:material_ui/material_ui.dart';

import '../services/format.dart';
import '../services/senders.dart';
import '../services/sms_reader.dart';
import '../services/sync_settings.dart';

/// Lets the user tick which SMS senders are their banks. Only those
/// senders' messages are read from then on. Pops `true` when saved.
class SendersScreen extends StatefulWidget {
  const SendersScreen({super.key});

  @override
  State<SendersScreen> createState() => _SendersScreenState();
}

class _SendersScreenState extends State<SendersScreen> {
  List<SenderSummary>? _senders;
  Set<String> _selected = {};
  SyncSettings? _settings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await SyncSettings.open();
      final senders = summarizeSenders(await readInbox());
      setState(() {
        _settings = settings;
        _senders = senders;
        _selected = settings.senders.isNotEmpty
            ? settings.senders
            : {for (final s in senders) if (s.looksLikeBank) s.sender};
      });
    } on SmsPermissionDenied {
      setState(() => _error = 'برای دیدن فرستنده‌ها اجازه‌ی دسترسی به پیامک لازم است.');
    } catch (e) {
      setState(() => _error = 'خطا در خواندن پیامک‌ها: $e');
    }
  }

  Future<void> _save() async {
    await _settings?.setSenders(_selected);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final senders = _senders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('سرشماره‌ی بانک‌ها'),
        actions: [TextButton(onPressed: senders == null ? null : _save, child: const Text('ذخیره'))],
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : senders == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'فرستنده‌های بانک‌هایت را انتخاب کن. از این به بعد فقط پیامک‌های همین‌ها خوانده می‌شود و '
                        'قالب‌های ناآشنای آن‌ها هم با دقت کمتر شناسایی می‌شود. اگر هیچ‌کدام را انتخاب نکنی، همه‌ی پیامک‌ها بررسی می‌شوند.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    for (final s in senders)
                      CheckboxListTile(
                        value: _selected.contains(s.sender),
                        onChanged: (v) => setState(() => v == true ? _selected.add(s.sender) : _selected.remove(s.sender)),
                        title: Text(s.sender, textDirection: TextDirection.ltr, textAlign: TextAlign.end),
                        subtitle: Text(
                          '${faDigits(s.messages)} پیامک'
                          '${s.transactions > 0 ? ' · ${faDigits(s.transactions)} تراکنش شناخته‌شده' : ''}\n'
                          '${s.latest.replaceAll('\n', ' ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      ),
                  ],
                ),
    );
  }
}
