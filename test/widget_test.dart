import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:apkuas/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

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
