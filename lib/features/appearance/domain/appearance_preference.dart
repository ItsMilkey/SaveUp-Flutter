/// Apariencia elegida localmente para la aplicación.
enum AppearancePreference {
  system,
  light,
  dark,
  bold;

  /// Lee la preferencia persistida; valores desconocidos vuelven al sistema.
  static AppearancePreference fromStorage(String? value) =>
      AppearancePreference.values.firstWhere(
        (AppearancePreference preference) => preference.name == value,
        orElse: () => AppearancePreference.system,
      );

  String get label => switch (this) {
    AppearancePreference.system => 'Sistema',
    AppearancePreference.light => 'Claro',
    AppearancePreference.dark => 'Oscuro',
    AppearancePreference.bold => 'Bold',
  };

  String get description => switch (this) {
    AppearancePreference.system => 'Se adapta al tema de tu dispositivo.',
    AppearancePreference.light => 'Papel claro y acentos SaveUp.',
    AppearancePreference.dark => 'Tinta oscura y superficies profundas.',
    AppearancePreference.bold => 'Color por bloques y acentos más intensos.',
  };
}
