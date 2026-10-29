import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/config.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() {
  // Falla de inmediato si el build no definió API_BASE_URL.
  AppConfig.ensureConfigured();

  runApp(const ProviderScope(child: SaveUpApp()));
}

/// Raíz de la aplicación.
class SaveUpApp extends ConsumerWidget {
  const SaveUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
