import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carga las fuentes bundleadas para tests de widgets/goldens.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final FontLoader archivo = FontLoader('ArchivoBlack')
    ..addFont(rootBundle.load('assets/fonts/ArchivoBlack-Regular.ttf'));
  await archivo.load();

  final FontLoader space = FontLoader('SpaceGrotesk')
    ..addFont(rootBundle.load('assets/fonts/SpaceGrotesk-Variable.ttf'));
  await space.load();

  final FontLoader icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
