import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_gaode_map_example/main.dart';

void main() {
  testWidgets('Demo app renders tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const GaodeMapExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Gaode Location Demo'), findsOneWidget);
    expect(find.text('Init'), findsOneWidget);
  });
}
