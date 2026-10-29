import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/main.dart';

void main() {
  testWidgets('la app arranca y muestra el placeholder con el nombre de la app',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SaveUpApp()));
    await tester.pumpAndSettle();

    expect(find.text('SaveUp'), findsWidgets);
    expect(find.text('Proyecto base listo.'), findsOneWidget);
  });
}
