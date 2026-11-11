import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('NOTEShub app smoke test renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const NotesHubApp(
        firebaseInitialized: false,
        initializationError: 'Test Mode: Testing fallback shell',
      ),
    );

    expect(find.text('NOTEShub'), findsNothing); // In error shell, title is in MaterialApp
    expect(find.text('Firebase Initialization Notice'), findsOneWidget);
  });
}
