import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/metas/data/dio_metas_repository.dart';
import 'package:saveup_app/features/metas/domain/meta_ahorro.dart';
import 'package:saveup_app/features/metas/presentation/controllers/meta_form_controller.dart';

import 'metas_fixtures.dart';

void main() {
  late FakeMetasRepository repo;
  late ProviderContainer container;

  void montar(FakeMetasRepository fake) {
    repo = fake;
    container = ProviderContainer(
      overrides: [metasRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  }

  MetaFormController controller() => container.read(metaFormProvider.notifier);
  MetaFormUiState estado() => container.read(metaFormProvider);

  test('crear envía los datos y queda en éxito', () async {
    montar(FakeMetasRepository());
    await controller().submit(
      datos: MetaAhorroDatos(
        nombre: 'Notebook',
        montoObjetivo: Decimal.fromInt(800000),
        fechaLimite: CalendarDate(2027, 3, 1),
      ),
    );

    expect(repo.creado!.nombre, 'Notebook');
    expect(repo.creado!.montoObjetivo!.toString(), '800000');
    expect(repo.creado!.fechaLimite, CalendarDate(2027, 3, 1));
    expect(estado(), isA<MetaFormSuccess>());
  });

  test('editar usa el id y conserva el ahorro', () async {
    montar(FakeMetasRepository());
    await controller().submit(
      datos: MetaAhorroDatos(
        nombre: 'Viaje',
        montoObjetivo: Decimal.fromInt(900000),
      ),
      id: 3,
    );

    expect(repo.editadoId, 3);
    expect(repo.editado!.nombre, 'Viaje');
    final MetaFormSuccess success = estado() as MetaFormSuccess;
    expect(success.meta.montoActual.toString(), '250000');
  });

  test('VALIDACION_FALLIDA se mapea por campo', () async {
    montar(
      FakeMetasRepository(
        errorCrear: const ValidationFailure(<FieldError>[
          FieldError(
            field: 'montoObjetivo',
            message: 'El monto objetivo debe ser positivo',
          ),
          FieldError(field: 'otro', message: 'Mensaje general'),
        ]),
      ),
    );
    await controller().submit(
      datos: MetaAhorroDatos(
        nombre: 'X',
        montoObjetivo: Decimal.fromInt(1),
      ),
    );

    final MetaFormFieldErrors ui = estado() as MetaFormFieldErrors;
    expect(ui.errors['montoObjetivo'], 'El monto objetivo debe ser positivo');
    expect(ui.global, 'Mensaje general');
  });

  test('un 409 queda como error con su detail', () async {
    montar(
      FakeMetasRepository(
        errorEditar: const ConflictFailure(
          codigo: 'CONFLICTO_REGLA_NEGOCIO',
          detail: 'La meta por defecto no se puede modificar así.',
        ),
      ),
    );
    await controller().submit(
      datos: MetaAhorroDatos(nombre: 'Ahorros'),
      id: 1,
    );

    final MetaFormError ui = estado() as MetaFormError;
    expect(ui.message, 'La meta por defecto no se puede modificar así.');
  });
}
