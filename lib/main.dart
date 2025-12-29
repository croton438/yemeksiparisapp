import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/state/cart_store.dart';
import 'src/state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Supabase init (URL + ANON KEY senin projenden)
   await Supabase.initialize(
    url: 'https://flfdwmxegeyegblrjjya.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsZmR3bXhlZ2V5ZWdibHJqanlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0MTYwMTEsImV4cCI6MjA4MTk5MjAxMX0.-2ZBw8VPI_9YwAXnXh4Qjfj7czWRs0EHf2nKU_0Dk04',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartStore()),
        ChangeNotifierProvider(create: (_) => AppStore()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
