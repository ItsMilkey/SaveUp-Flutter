import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/config.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/time/time_zones.dart';
import 'features/appearance/data/shared_preferences_appearance_repository.dart';
import 'features/appearance/domain/appearance_preference.dart';
import 'features/appearance/presentation/appearance_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Falla de inmediato si el build no definió API_BASE_URL.
  AppConfig.ensureConfigured();

  // Zona del negocio disponible antes de cualquier cálculo de fechas.
  initializeTimeZones();

  final SharedPreferencesAppearanceRepository appearanceRepository =
      SharedPreferencesAppearanceRepository();
  AppearancePreference initialAppearance;
  try {
    initialAppearance = await appearanceRepository.read();
  } on Exception {
    // La apariencia no debe impedir iniciar la aplicación si falla el storage.
    initialAppearance = AppearancePreference.system;
  }

  runApp(
    ProviderScope(
      overrides: [
        appearanceRepositoryProvider.overrideWithValue(appearanceRepository),
        appearanceProvider.overrideWith(
          () => AppearanceController(initialAppearance),
        ),
      ],
      child: const SaveUpApp(),
    ),
  );
}

/// Raíz de la aplicación.
class SaveUpApp extends ConsumerWidget {
  const SaveUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppearancePreference appearance = ref.watch(appearanceProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.forPreference(appearance),
      darkTheme: AppTheme.dark(),
      themeMode: AppTheme.modeForPreference(appearance),
      locale: const Locale('es'),
      supportedLocales: const <Locale>[Locale('es')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
