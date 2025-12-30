import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/cart_store.dart';
import 'ui/shell/app_shell.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartStore(),
      child: const AppShell(),
    );
  }
}
