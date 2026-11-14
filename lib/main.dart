import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/settings.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HesabdarApp(settings: await AppSettings.open()));
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
