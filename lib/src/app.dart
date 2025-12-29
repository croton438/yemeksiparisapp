import 'package:flutter/material.dart';
import 'ui/shell/app_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Koyu tema sabitle (beyaza kaymasın)
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6), // mor
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        brightness: Brightness.dark,

        // ✅ En kritik kısım: arka planı koyuya kilitle
        scaffoldBackgroundColor: const Color(0xFF0B0B10),
        canvasColor: const Color(0xFF0B0B10),

        // Input’ların da açık görünmesini engelle
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF151521),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.primary.withOpacity(0.55)),
          ),
        ),

        // Kartlarda “beyaz çizgi” hissi veren border’ı global yumuşat
        dividerColor: Colors.white.withOpacity(0.08),
      ),
      home: const AppShell(),
    );
  }
}
