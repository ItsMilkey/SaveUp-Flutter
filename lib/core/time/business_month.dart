import 'package:timezone/timezone.dart' as tz;

import 'time_zones.dart';

/// Mes de negocio (año y mes) calculado en `America/Santiago`.
///
/// El mes de presupuesto no es el mes UTC ni el del dispositivo: un instante
/// de las 02:00 UTC del día 1 puede seguir siendo el mes anterior en Santiago.
class BusinessMonth implements Comparable<BusinessMonth> {
  const BusinessMonth(this.year, this.month) : assert(month >= 1 && month <= 12);

  /// Mes de negocio al que pertenece [instant], en `America/Santiago`.
  factory BusinessMonth.fromInstant(DateTime instant) {
    final tz.TZDateTime local =
        tz.TZDateTime.from(instant.toUtc(), businessTimeZone);
    return BusinessMonth(local.year, local.month);
  }

  final int year;
  final int month;

  /// Inicio del mes (inclusivo) como instante UTC.
  DateTime get startUtc =>
      tz.TZDateTime(businessTimeZone, year, month).toUtc();

  /// Fin del mes (exclusivo) como instante UTC.
  DateTime get endUtc =>
      tz.TZDateTime(businessTimeZone, year, month + 1).toUtc();

  /// Indica si [instant] cae dentro de `[startUtc, endUtc)`.
  bool contains(DateTime instant) {
    final DateTime utc = instant.toUtc();
    return !utc.isBefore(startUtc) && utc.isBefore(endUtc);
  }

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is BusinessMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  int compareTo(BusinessMonth other) {
    final int byYear = year.compareTo(other.year);
    return byYear != 0 ? byYear : month.compareTo(other.month);
  }
}
