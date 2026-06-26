import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xue_hua_gaode_map_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo app launches', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Gaode Location Demo'), findsOneWidget);
    expect(find.text('Init'), findsOneWidget);
  });
}
