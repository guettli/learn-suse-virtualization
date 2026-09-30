import 'package:flutter_test/flutter_test.dart';
import 'package:handsfree_anki/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HandsFreeAnkiApp());
    expect(find.text('Hands-Free Flashcards'), findsOneWidget);
  });
}
