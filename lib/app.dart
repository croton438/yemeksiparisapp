import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/state/app_store.dart';
import 'src/state/cart_store.dart';
import 'src/theme/app_theme.dart';
import 'src/ui/shell/app_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStore()),
        ChangeNotifierProvider(create: (_) => CartStore()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        theme: AppTheme.dark(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark, // ✅ KİLİT: her zaman dark

        home: const AppShell(),
      ),
    );
  }
}
