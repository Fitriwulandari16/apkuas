import 'package:flutter_test/flutter_test.dart';
import 'package:apkuas/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('CilikCode App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CilikCodeApp(),
      ),
    );

    // Verify that the title is present.
    expect(find.text('CilikCode'), findsOneWidget);
    
    // Verify that the 'Mulai Belajar' button is present.
    expect(find.text('Mulai Belajar'), findsOneWidget);
  });
}
