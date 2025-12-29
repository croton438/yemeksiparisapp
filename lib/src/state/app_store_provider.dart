// lib/src/state/app_store_provider.dart
import 'package:flutter/widgets.dart';
import 'app_store.dart';

class AppStoreProvider extends InheritedNotifier<AppStore> {
  const AppStoreProvider({
    super.key,
    required AppStore notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppStore of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<AppStoreProvider>();
    assert(p != null, 'AppStoreProvider not found in widget tree');
    return p!.notifier!;
  }
}
