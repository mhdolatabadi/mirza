import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesabdar/screens/categories_view.dart';
import 'package:hesabdar/screens/export_screen.dart';
import 'package:hesabdar/screens/report_view.dart';
import 'package:hesabdar/screens/settings_view.dart';
import 'package:hesabdar/screens/transactions_view.dart';
import 'package:hesabdar/services/format.dart';
import 'package:hesabdar/services/ledger.dart';
import 'package:hesabdar/services/report.dart';
import 'package:hesabdar/services/settings.dart';
import 'package:hesabdar/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Transaction tx(TransactionType type, int amount, JalaliDate date, String raw,
        {String? bank, String? account, int? balance, String? time, String? description}) =>
    Transaction(
      bank: bank,
      type: type,
      amount: amount,
      date: date,
      raw: raw,
      account: account,
      balance: balance,
      time: time,
      description: description,
    );

final sample = Ledger(
  [
    tx(TransactionType.debit, 850000, const JalaliDate(1405, 8, 7), 'خرید پوز', bank: 'blu', balance: 18426000, time: '13:19'),
    tx(TransactionType.debit, 430000, const JalaliDate(1405, 8, 7), 'قبض برق', account: '10.9554759.1', time: '09:58'),
    tx(TransactionType.credit, 534600, const JalaliDate(1405, 8, 6), 'پایا', account: '75009', time: '13:19', description: 'پایا'),
    tx(TransactionType.debit, 46400, const JalaliDate(1405, 8, 6), 'کارمزد پیامک', bank: 'blu', description: 'کارمزد پیامک مرداد ماه 1405'),
    tx(TransactionType.credit, 400000000, const JalaliDate(1405, 8, 1), 'واریز حقوق', account: '10.9554759.1'),
    tx(TransactionType.debit, 5682000, const JalaliDate(1405, 8, 2), 'قسط وام', account: '10.9554759.1'),
    tx(TransactionType.debit, 9000000, const JalaliDate(1405, 7, 20), 'خرید مهر', bank: 'blu'),
  ],
  accountNames: {'10.9554759.1': 'رسالت'},
);

Widget app(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
      theme: buildTheme(brightness),
      home: Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: child)),
    );

void main() {
  final months = monthlySummaries(sample.transactions);

  // Real glyph metrics, so overflow checks match the phone.
  setUpAll(() async {
    Future<ByteData> bytes(String path) async => ByteData.sublistView(await File(path).readAsBytes());
    final vazirmatn = FontLoader('Vazirmatn');
    for (final w in ['Regular', 'Medium', 'Bold']) {
      vazirmatn.addFont(bytes('assets/fonts/Vazirmatn-$w.ttf'));
    }
    await vazirmatn.load();
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) await (FontLoader('MaterialIcons')..addFont(bytes(icons.path))).load();
  });

  // A typical phone: 360 x 780 logical pixels.
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3;
  });

  for (final brightness in Brightness.values) {
    testWidgets('screens render without overflow ($brightness)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.open();

      await tester.pumpWidget(app(TransactionsView(ledger: sample, unit: MoneyUnit.rial, onEdit: (_) {}), brightness: brightness));
      expect(find.text('امروز · ۷ آبان'), findsNothing); // dates are not today in the test
      expect(find.text('۱۸٬۴۲۶٬۰۰۰'), findsOneWidget);

      await tester.pumpWidget(app(
        ReportView(ledger: sample, months: months, selected: 0, onSelectMonth: (_) {}, unit: MoneyUnit.toman),
        brightness: brightness,
      ));
      expect(find.text('آبان ۱۴۰۵'), findsOneWidget);

      await tester.pumpWidget(app(
        CategoriesView(
          ledger: sample,
          months: months,
          selected: 0,
          onSelectMonth: (_) {},
          unit: MoneyUnit.rial,
          onOpen: (_, _, _) {},
        ),
        brightness: brightness,
      ));
      expect(find.text('خرید'), findsOneWidget);

      await tester.pumpWidget(app(
        SettingsView(
          ledger: sample,
          settings: settings,
          lastLoaded: DateTime(2026, 10, 30, 9, 40),
          onReload: () {},
          onRenameAccount: (_, _) async {},
        ),
        brightness: brightness,
      ));
      expect(find.text('رسالت'), findsOneWidget);
      expect(find.text('بدون نام'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(theme: buildTheme(brightness), home: ExportScreen(ledger: sample, month: months.first)));
      expect(find.text('mirza-1405-08.xlsx'), findsOneWidget);
      await tester.tap(find.text('همه‌ی ماه‌ها'));
      await tester.pump();
      expect(find.text('mirza.xlsx'), findsOneWidget);
    });
  }
}
