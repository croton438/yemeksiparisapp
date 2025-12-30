import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/app.dart';
import 'src/state/cart_store.dart';
import 'src/state/app_store.dart';
import 'src/state/auth_store.dart';
import 'src/core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment (optional)
  bool envLoaded = false;
  try {
    // Explicit filename prevents some NotInitializedError edge cases
    await dotenv.load(fileName: '.env');
    envLoaded = true;
  } catch (_) {
    envLoaded = false;
  }

  final supabaseUrl =
      (envLoaded && dotenv.isInitialized) ? dotenv.env['SUPABASE_URL'] : null;
  final supabaseAnonKey =
      (envLoaded && dotenv.isInitialized) ? dotenv.env['SUPABASE_ANON_KEY'] : null;

  await Supabase.initialize(
    url: supabaseUrl ?? SupabaseConfig.url,
    anonKey: supabaseAnonKey ?? SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartStore()),
        ChangeNotifierProvider(create: (_) => AppStore()),
        ChangeNotifierProvider(create: (_) => AuthStore()),
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
