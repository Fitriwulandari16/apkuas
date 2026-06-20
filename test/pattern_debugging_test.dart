import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/features/matching/pattern_debugging_screen.dart';

void main() {
  setUpAll(() {
    // Disable HTTP fetching for Google Fonts in tests to avoid AssetManifest.bin exceptions
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('PatternDebuggingScreen (Level 44) Tap to Cycle Color Game Logic Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PatternDebuggingScreen(levelId: 44),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify level title and instruction render correctly
    expect(find.text('Level 44'), findsOneWidget);
    expect(find.text('Temukan warna panah yang salah (ketuk silang), lalu perbaiki!'), findsOneWidget);

    // 2. Access state and verify initial pre-identified conditions
    final dynamic state = tester.state(find.byType(PatternDebuggingScreen));
    expect(state.dots, isNotNull);
    
    // Check initial row 0: error index is 5, isIdentified is true, showError is true on start
    final row0 = state.dots[0];
    expect(row0.isIdentified, isTrue);
    expect(row0.showError, isTrue);
    expect(find.text('Perbaiki eror!'), findsWidgets);

    // 3. Find the arrows of Row 1 under the ListView.
    final arrowGestures = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(GestureDetector),
    );
    expect(arrowGestures, findsNWidgets(24)); // 4 rows * 6 columns = 24 arrows

    // Initial color is 'blue'. Tap 1 -> cycles to 'yellow' (incorrect).
    await tester.tap(arrowGestures.at(5));
    await tester.pumpAndSettle();
    expect(row0.initialColors[5], equals('yellow'));
    expect(row0.isCorrected, isFalse);
    expect(row0.showError, isTrue);

    // Tap 2 -> cycles to 'pink' (correct color!).
    await tester.tap(arrowGestures.at(5));
    await tester.pumpAndSettle();

    // Verify Row 0 is now corrected, showError is false, and "Perbaiki eror!" is hidden
    expect(row0.initialColors[5], equals('pink'));
    expect(row0.isCorrected, isTrue);
    expect(row0.showError, isFalse);
  });
}
