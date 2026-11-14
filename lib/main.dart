import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'services/auto_sync.dart';
import 'services/settings.dart';
import 'services/sync_settings.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HesabdarApp(settings: await AppSettings.open()));
  final sync = await SyncSettings.open();
  try {
    await scheduleBackgroundSync(sync.autoSync && sync.sheetConfigured);
  } catch (_) {
    // Background sync is a convenience; the app works without it.
  }
}

class HesabdarApp extends StatelessWidget {
  final AppSettings settings;
  const HesabdarApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'میرزا',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: settings.themeMode,
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: HomeScreen(settings: settings),
      ),
    );
  }
}
