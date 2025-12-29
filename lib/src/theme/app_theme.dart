import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB39DDB),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      // ✅ Tüm kart border “beyazlığını” yumuşatan ana ayar
      dividerColor: const Color(0x22FFFFFF),

      scaffoldBackgroundColor: const Color(0xFF0B0B10),
      canvasColor: const Color(0xFF0B0B10),

      cardTheme: CardThemeData(
        color: const Color(0xFF141420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF141420),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF141420),
        modalBackgroundColor: Color(0xFF141420),
        showDragHandle: true,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0B10),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF10101A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),

      // ✅ Buton borderları da dividerColor ile uyumlu olsun
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0x22FFFFFF)),
        ),
      ),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB39DDB),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
  }
}
