import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const HesabdarApp());

class HesabdarApp extends StatelessWidget {
  const HesabdarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حسابدار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}
