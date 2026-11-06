import 'package:decimal/decimal.dart';

/// Saldo actual del usuario (`GET /saldos/me`).
abstract interface class SaldosRepository {
  Future<Decimal> saldoActual();
}
