import 'package:material_ui/material_ui.dart';

ThemeData roommateTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D9488),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
        onPrimary: dark ? const Color(0xFF0F172A) : Colors.white,
        surface: dark ? const Color(0xFF1E293B) : Colors.white,
        onSurface: dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        outlineVariant: dark
            ? const Color(0xFF334155)
            : const Color(0xFFE2E8F0),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
