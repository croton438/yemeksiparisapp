import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellfud/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // ✅ Widget test ortamında plugin kanalı yok; shared_preferences mock gerekir
    SharedPreferences.setMockInitialValues({});

    // ✅ Supabase.instance.client erişimleri patlamasın diye initialize
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'anon',
    );
  });

  tearDownAll(() async {
    // ✅ Test runner kapanırken açık kaynak kalmasın
    Supabase.instance.client.dispose();
  });

  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
