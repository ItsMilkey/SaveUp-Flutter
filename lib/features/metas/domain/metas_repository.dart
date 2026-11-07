import 'package:decimal/decimal.dart';

import 'meta_ahorro.dart';

/// Contrato de datos de metas de ahorro (F7).
abstract interface class MetasRepository {
  /// `GET /metas/me`.
  Future<List<MetaAhorro>> listar();

  /// `POST /metas` (201).
  Future<MetaAhorro> crear(MetaAhorroDatos datos);

  /// `PUT /metas/{id}`.
  Future<MetaAhorro> editar(int id, MetaAhorroDatos datos);

  /// `DELETE /metas/{id}` (204; devuelve el ahorro al saldo).
  Future<void> eliminar(int id);

  /// `POST /metas/{id}/abonar` (crea un `ABONO_META` negativo).
  Future<MetaAhorro> abonar(
    int id, {
    required Decimal monto,
    required String descripcion,
  });

  /// `POST /metas/{id}/retirar` (crea un `RETIRO_META` positivo).
  Future<MetaAhorro> retirar(
    int id, {
    required Decimal monto,
    required String descripcion,
  });
}
