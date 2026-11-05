import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_version_sources.dart';
import '../data/dio_app_version_repository.dart';
import '../domain/app_version_info.dart';

/// Estado de la consulta de versión mínima (`GET /app/version`).
sealed class AppVersionState {
  const AppVersionState();
}

/// Consulta en curso (arranque).
class AppVersionChecking extends AppVersionState {
  const AppVersionChecking();
}

/// Al día o más nueva: no se muestra nada.
class AppVersionUpToDate extends AppVersionState {
  const AppVersionUpToDate();
}

/// `actualizacionSugerida=true`: aviso descartable, la app sigue.
class AppVersionSuggested extends AppVersionState {
  const AppVersionSuggested(this.info);

  final AppVersionInfo info;
}

/// El aviso sugerido ya se descartó: no vuelve a mostrarse en este arranque.
class AppVersionSuggestedDismissed extends AppVersionState {
  const AppVersionSuggestedDismissed(this.info);

  final AppVersionInfo info;
}

/// `actualizacionObligatoria=true`: pantalla bloqueante con botón a la tienda.
class AppVersionBlocked extends AppVersionState {
  const AppVersionBlocked(this.info);

  final AppVersionInfo info;
}

/// No se pudo consultar (red/timeout): se degrada y se continúa.
class AppVersionDegraded extends AppVersionState {
  const AppVersionDegraded();
}

/// Versiones legales vigentes, en memoria para la tarea de legales (F2); aún
/// no hay pantalla que las muestre.
class LegalVersions {
  const LegalVersions({
    required this.versionTerminos,
    required this.versionPrivacidad,
  });

  final String versionTerminos;
  final String versionPrivacidad;
}

final NotifierProvider<LegalVersionsController, LegalVersions?>
legalVersionsProvider =
    NotifierProvider<LegalVersionsController, LegalVersions?>(
      LegalVersionsController.new,
    );

class LegalVersionsController extends Notifier<LegalVersions?> {
  @override
  LegalVersions? build() => null;

  void update(LegalVersions value) {
    state = value;
  }
}

/// Orquesta la consulta de versión al arrancar de la app.
final NotifierProvider<AppVersionController, AppVersionState>
appVersionProvider = NotifierProvider<AppVersionController, AppVersionState>(
  AppVersionController.new,
);

class AppVersionController extends Notifier<AppVersionState> {
  @override
  AppVersionState build() => const AppVersionChecking();

  /// Consulta la política de actualización.
  ///
  /// Nunca lanza: si el plugin o la red fallan, degrada ([AppVersionDegraded])
  /// para no bloquear el uso de la app.
  Future<void> check() async {
    state = const AppVersionChecking();
    try {
      final String version = await ref.read(appVersionReaderProvider)();
      final AppVersionState next = await _resolve(version);
      state = next;
    } on Object {
      state = const AppVersionDegraded();
    }
  }

  /// Descarta el aviso de actualización sugerida (no intrusivo).
  void dismissSuggestion() {
    final AppVersionState current = state;
    if (current is AppVersionSuggested) {
      state = AppVersionSuggestedDismissed(current.info);
    }
  }

  Future<AppVersionState> _resolve(String version) async {
    final AppVersionInfo info = await ref
        .read(appVersionRepositoryProvider)
        .fetch(platform: ref.read(appPlatformProvider), version: version);

    ref
        .read(legalVersionsProvider.notifier)
        .update(
          LegalVersions(
            versionTerminos: info.versionTerminos,
            versionPrivacidad: info.versionPrivacidad,
          ),
        );

    if (info.actualizacionObligatoria) {
      return AppVersionBlocked(info);
    }
    if (info.actualizacionSugerida) {
      return AppVersionSuggested(info);
    }
    return const AppVersionUpToDate();
  }
}
