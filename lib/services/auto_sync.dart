import 'package:workmanager/workmanager.dart';

import 'ledger.dart';
import 'ledger_store.dart';
import 'sheets_sync.dart';
import 'sms_reader.dart';
import 'sync_settings.dart';

const _taskName = 'sheet-sync';

/// Reads the inbox, parses the bank senders' messages and sends what is new
/// to the Google Sheet. Returns null when there is nothing to do.
Future<SyncResult?> runSync({bool askPermission = false}) async {
  final settings = await SyncSettings.open();
  if (!settings.sheetConfigured) return null;
  final store = await LedgerStore.open();
  final transactions = parseInbox(await readInbox(askPermission: askPermission), senders: settings.senders);
  final ledger = Ledger(
    transactions,
    categoryOverrides: store.categoryOverrides,
    accountNames: store.accountNames,
  );
  return syncToSheet(ledger, settings);
}

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      await runSync();
      return true;
    } on SmsPermissionDenied {
      return true;
    } catch (_) {
      // Let WorkManager retry later (no network, Google hiccup, ...).
      return false;
    }
  });
}

/// Turns the periodic background sync on or off. Android runs it about
/// every 15 minutes when the phone is online, even if the app is closed.
Future<void> scheduleBackgroundSync(bool enabled) async {
  await Workmanager().initialize(backgroundDispatcher);
  if (enabled) {
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } else {
    await Workmanager().cancelByUniqueName(_taskName);
  }
}
