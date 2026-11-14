import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/auto_sync.dart';
import '../services/format.dart';
import '../services/sync_settings.dart';

/// Google Sheet address, automatic sending and a manual "send now".
class SheetsScreen extends StatefulWidget {
  const SheetsScreen({super.key});

  @override
  State<SheetsScreen> createState() => _SheetsScreenState();
}

class _SheetsScreenState extends State<SheetsScreen> {
  SyncSettings? _settings;
  final _url = TextEditingController();
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    SyncSettings.open().then((s) => setState(() {
          _settings = s;
          _url.text = s.sheetUrl;
        }));
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _copyScript() async {
    await Clipboard.setData(ClipboardData(text: await rootBundle.loadString('assets/google_apps_script.gs')));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد اسکریپت کپی شد.')));
  }

  Future<void> _saveUrl() async {
    final s = _settings!;
    await s.setSheetUrl(_url.text);
    await scheduleBackgroundSync(s.autoSync && s.sheetConfigured);
    setState(() {});
  }

  Future<void> _setAuto(bool v) async {
    final s = _settings!;
    await s.setAutoSync(v);
    await scheduleBackgroundSync(v && s.sheetConfigured);
    setState(() {});
  }

  Future<void> _syncNow({bool all = false}) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _saveUrl();
      if (all) await _settings!.clearSent();
      final r = await runSync(askPermission: true);
      _status = r == null
          ? 'اول آدرس اسکریپت را وارد کن.'
          : r.changed
              ? '${faDigits(r.added)} ردیف اضافه و ${faDigits(r.updated)} ردیف به‌روز شد.'
              : 'شیت به‌روز است.';
    } catch (e) {
      _status = '$e';
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    final theme = Theme.of(context);
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final last = s.lastSync;

    return Scaffold(
      appBar: AppBar(title: const Text('گوگل شیت')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('راه‌اندازی (یک بار، روی کامپیوتر راحت‌تر است)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          const Text('۱. گوگل شیتت را باز کن و از منوی Extensions گزینه‌ی Apps Script را بزن.\n'
              '۲. کد اسکریپت را (با دکمه‌ی پایین) کپی کن و جای کد قبلی بگذار و ذخیره کن.\n'
              '۳. Deploy → New deployment → نوع Web app، با Execute as: Me و Who has access: Anyone.\n'
              '۴. آدرس Web app را اینجا وارد کن و «ارسال الان» را بزن.'),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: _copyScript,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('کپی کد اسکریپت'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'آدرس Web app',
              hintText: 'https://script.google.com/macros/s/.../exec',
            ),
            onSubmitted: (_) => _saveUrl(),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.autoSync,
            onChanged: _setAuto,
            title: const Text('ارسال خودکار'),
            subtitle: const Text('هر بار که اپ پیامک‌ها را می‌خواند، و حدود هر ۱۵ دقیقه در پس‌زمینه'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _syncNow,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_rounded),
            label: const Text('ارسال الان'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _syncNow(all: true),
            child: const Text('ارسال دوباره‌ی همه‌ی تراکنش‌ها'),
          ),
          if (_status != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status!)),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'آخرین ارسال: ${faDigits('${last.hour}:${last.minute.toString().padLeft(2, '0')}')}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
