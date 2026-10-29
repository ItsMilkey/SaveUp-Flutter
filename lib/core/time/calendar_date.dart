/// Fecha de calendario (`yyyy-MM-dd`) sin zona horaria.
///
/// Se usa para `fechaLimite`, `fechaPrimeraCuota` y filtros `desde`/`hasta`.
/// No es un instante: nunca debe convertirse a UTC ni interpretarse en la zona
/// del dispositivo.
class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    _validate(year: year, month: month, day: day);
  }

  /// Parsea el formato exacto `yyyy-MM-dd`.
  factory CalendarDate.parse(String raw) {
    final RegExpMatch? match = _pattern.firstMatch(raw.trim());
    if (match == null) {
      throw FormatException(
        'La fecha de calendario debe tener el formato yyyy-MM-dd: "$raw".',
        raw,
      );
    }

    return CalendarDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// Serializa al formato que espera el backend: `yyyy-MM-dd`.
  String toJson() => toString();

  @override
  String toString() {
    final String mm = month.toString().padLeft(2, '0');
    final String dd = day.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-$mm-$dd';
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  int compareTo(CalendarDate other) {
    final int byYear = year.compareTo(other.year);
    if (byYear != 0) {
      return byYear;
    }
    final int byMonth = month.compareTo(other.month);
    if (byMonth != 0) {
      return byMonth;
    }
    return day.compareTo(other.day);
  }

  static void _validate({
    required int year,
    required int month,
    required int day,
  }) {
    final bool validMonth = month >= 1 && month <= 12;
    final bool validDay = day >= 1 && day <= 31;
    if (!validMonth || !validDay) {
      throw FormatException('Fecha de calendario inválida: $year-$month-$day.');
    }

    // Descarta días que no existen en ese mes (p. ej. 2025-02-29).
    final DateTime probe = DateTime.utc(year, month, day);
    if (probe.year != year || probe.month != month || probe.day != day) {
      throw FormatException('Fecha de calendario inválida: $year-$month-$day.');
    }
  }
}
