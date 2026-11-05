import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/token_store.dart';

import 'support/fake_http_adapter.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('la app arranca, consulta la versión y llega al login', (
    WidgetTester tester,
  ) async {
    final FakeHttpAdapter adapter = FakeHttpAdapter();
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(
      testApp(adapter: adapter, tokenStore: InMemoryTokenStore()),
    );
    await tester.pumpAndSettle();

    // La consulta de versión y el chequeo de sesión llevaron al login.
    expect(find.text('Inicia sesión'), findsWidgets);
  });
}
