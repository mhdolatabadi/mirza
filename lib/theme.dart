import 'package:flutter/material.dart';

import 'services/categories.dart';

/// Colors from the design: deep ink blue as the primary, saffron as the one
/// accent (selected month), green for credits.
class MirzaColors extends ThemeExtension<MirzaColors> {
  final Color saffron;
  final Color onSaffron;
  final Color income;
  final Color expense;

  /// Category colors, in the order of [categories].
  final List<Color> categoryColors;

  const MirzaColors({
    required this.saffron,
    required this.onSaffron,
    required this.income,
    required this.expense,
    required this.categoryColors,
  });

  static const light = MirzaColors(
    saffron: Color(0xFFD9971F),
    onSaffron: Color(0xFF1D1405),
    income: Color(0xFF1B8A5F),
    expense: Color(0xFFC4412F),
    categoryColors: [
      Color(0xFF3B6FB6),
      Color(0xFF7A5BC4),
      Color(0xFFD9971F),
      Color(0xFFC4412F),
      Color(0xFF1B8A5F),
      Color(0xFF2B9BB0),
      Color(0xFF8A6D55),
      Color(0xFF8592A3),
    ],
  );

  static const dark = MirzaColors(
    saffron: Color(0xFFF0B445),
    onSaffron: Color(0xFF1D1405),
    income: Color(0xFF4CC792),
    expense: Color(0xFFF07A68),
    categoryColors: [
      Color(0xFF6F9FE0),
      Color(0xFFA68AE6),
      Color(0xFFF0B445),
      Color(0xFFF07A68),
      Color(0xFF4CC792),
      Color(0xFF5CC4D6),
      Color(0xFFC29F82),
      Color(0xFF9AA7B8),
    ],
  );

  static MirzaColors of(BuildContext context) => Theme.of(context).extension<MirzaColors>()!;

  Color categoryColor(String category) {
    final i = categories.indexOf(category);
    return categoryColors[i < 0 ? categoryColors.length - 1 : i];
  }

  @override
  MirzaColors copyWith({Color? saffron, Color? onSaffron, Color? income, Color? expense, List<Color>? categoryColors}) =>
      MirzaColors(
        saffron: saffron ?? this.saffron,
        onSaffron: onSaffron ?? this.onSaffron,
        income: income ?? this.income,
        expense: expense ?? this.expense,
        categoryColors: categoryColors ?? this.categoryColors,
      );

  @override
  MirzaColors lerp(MirzaColors? other, double t) {
    if (other == null) return this;
    return MirzaColors(
      saffron: Color.lerp(saffron, other.saffron, t)!,
      onSaffron: Color.lerp(onSaffron, other.onSaffron, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      categoryColors: [
        for (var i = 0; i < categoryColors.length; i++) Color.lerp(categoryColors[i], other.categoryColors[i], t)!,
      ],
    );
  }
}

const _categoryIcons = {
  'خرید': Icons.shopping_bag_rounded,
  'انتقال': Icons.swap_horiz_rounded,
  'قبوض': Icons.receipt_long_rounded,
  'اقساط': Icons.event_repeat_rounded,
  'حقوق': Icons.work_rounded,
  'سود': Icons.trending_up_rounded,
  'کارمزد بانکی': Icons.account_balance_rounded,
};

IconData categoryIcon(String category) => _categoryIcons[category] ?? Icons.more_horiz_rounded;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF17365C),
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF9CC0EA) : const Color(0xFF17365C),
    onPrimary: dark ? const Color(0xFF0F1823) : Colors.white,
    surface: dark ? const Color(0xFF0F1823) : const Color(0xFFF6F8FB),
    surfaceContainer: dark ? const Color(0xFF172333) : Colors.white,
    surfaceContainerHighest: dark ? const Color(0xFF1B2B40) : const Color(0xFFE3EBF5),
    onSurfaceVariant: dark ? const Color(0xFF93A2B4) : const Color(0xFF5F6F82),
    outlineVariant: dark ? const Color(0xFF223143) : const Color(0xFFDDE3EA),
  );
  final base = ThemeData(colorScheme: scheme, fontFamily: 'Vazirmatn', useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    extensions: [dark ? MirzaColors.dark : MirzaColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primary,
      labelStyle: TextStyle(fontFamily: 'Vazirmatn', color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(fontFamily: 'Vazirmatn', color: scheme.onPrimary, fontWeight: FontWeight.w700),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.surfaceContainerHighest,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
  );
}
