import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/app/theme.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
import 'package:saveup_app/features/appearance/domain/appearance_preference.dart';
import 'package:saveup_app/features/appearance/domain/appearance_repository.dart';
import 'package:saveup_app/features/appearance/data/shared_preferences_appearance_repository.dart';
import 'package:saveup_app/features/appearance/presentation/appearance_controller.dart';
import 'package:saveup_app/features/appearance/presentation/appearance_screen.dart';

class _MemoryAppearanceRepository implements AppearanceRepository {
  _MemoryAppearanceRepository(this.value);

  AppearancePreference value;
  bool failWrites = false;
  final List<AppearancePreference> written = <AppearancePreference>[];

  @override
  Future<AppearancePreference> read() async => value;

  @override
  Future<void> write(AppearancePreference preference) async {
    if (failWrites) {
      throw Exception('falló el storage de prueba');
    }
    written.add(preference);
    value = preference;
  }
}

Widget _host({
  required _MemoryAppearanceRepository repository,
  AppearancePreference initial = AppearancePreference.system,
}) {
  return ProviderScope(
    overrides: [
      appearanceRepositoryProvider.overrideWithValue(repository),
      appearanceProvider.overrideWith(() => AppearanceController(initial)),
    ],
    child: Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final AppearancePreference appearance = ref.watch(appearanceProvider);
        return MaterialApp(
          theme: AppTheme.forPreference(appearance),
          darkTheme: AppTheme.dark(),
          themeMode: AppTheme.modeForPreference(appearance),
          home: const AppearanceScreen(),
        );
      },
    ),
  );
}

void main() {
  testWidgets('muestra previews y señala el tema actualmente seleccionado', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final _MemoryAppearanceRepository repository = _MemoryAppearanceRepository(
      AppearancePreference.system,
    );

    await tester.pumpWidget(_host(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Tema'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('appearance-preview-system')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preview-light')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preview-dark')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('appearance-preview-bold')),
      findsOneWidget,
    );
    expect(find.text('Actualmente: claro'), findsOneWidget);
    expect(find.text('Seleccionado'), findsOneWidget);
  });

  testWidgets('seleccionar Bold aplica el tema y persiste la preferencia', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final _MemoryAppearanceRepository repository = _MemoryAppearanceRepository(
      AppearancePreference.system,
    );

    await tester.pumpWidget(_host(repository: repository));
    await tester.pumpAndSettle();
    final Finder boldCard = find.byKey(
      const ValueKey<String>('appearance-option-bold'),
    );
    await tester.ensureVisible(boldCard);
    await tester.tap(boldCard);
    await tester.pumpAndSettle();

    expect(repository.written, <AppearancePreference>[
      AppearancePreference.bold,
    ]);
    expect(repository.value, AppearancePreference.bold);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme
          ?.extension<SaveUpColors>()
          ?.canvas,
      SaveUpColors.bold.canvas,
    );
    expect(find.text('Seleccionado'), findsOneWidget);
  });

  testWidgets('si falla la persistencia conserva la opción activa', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final _MemoryAppearanceRepository repository = _MemoryAppearanceRepository(
      AppearancePreference.system,
    )..failWrites = true;

    await tester.pumpWidget(_host(repository: repository));
    await tester.pumpAndSettle();
    final Finder boldCard = find.byKey(
      const ValueKey<String>('appearance-option-bold'),
    );
    await tester.ensureVisible(boldCard);
    await tester.tap(boldCard);
    await tester.pumpAndSettle();

    expect(repository.value, AppearancePreference.system);
    expect(repository.written, isEmpty);
    expect(find.textContaining('No se pudo guardar el tema.'), findsOneWidget);
  });

  test('tema desconocido en storage vuelve a Sistema', () {
    expect(
      AppearancePreference.fromStorage('no-es-un-tema'),
      AppearancePreference.system,
    );
    expect(AppearancePreference.fromStorage('bold'), AppearancePreference.bold);
  });

  test(
    'el mapeo de apariencia conserva el modo de sistema y fuerza Bold claro',
    () {
      expect(
        AppTheme.modeForPreference(AppearancePreference.system),
        ThemeMode.system,
      );
      expect(
        AppTheme.modeForPreference(AppearancePreference.light),
        ThemeMode.light,
      );
      expect(
        AppTheme.modeForPreference(AppearancePreference.dark),
        ThemeMode.dark,
      );
      expect(
        AppTheme.modeForPreference(AppearancePreference.bold),
        ThemeMode.light,
      );
      expect(
        AppTheme.forPreference(AppearancePreference.bold).brightness,
        Brightness.light,
      );
    },
  );
}
