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

  testWidgets('PatternDebuggingScreen (Level 44) Rendering, Identification and Correction Test', (WidgetTester tester) async {
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

    // 2. Access state and verify initial conditions
    final dynamic state = tester.state(find.byType(PatternDebuggingScreen));
    expect(state.dots, isNotNull);
    
    // Check initial row 0: error index is 5, isIdentified is false, showError is false
    final row0 = state.dots[0];
    expect(row0.isIdentified, isFalse);
    expect(row0.showError, isFalse);
    expect(find.text('Perbaiki eror!'), findsNothing);

    // 3. Tap the error arrow in Row 1 (index 5) to identify it
    // Find the arrows of Row 1 under the ListView.
    final arrowGestures = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(GestureDetector),
    );
    expect(arrowGestures, findsNWidgets(24)); // 4 rows * 6 columns = 24 arrows

    // Tap the 6th arrow (index 5)
    await tester.tap(arrowGestures.at(5));
    await tester.pumpAndSettle();

    // Verify it is now identified and showing the error text
    expect(row0.isIdentified, isTrue);
    expect(row0.showError, isTrue);
    expect(find.text('Perbaiki eror!'), findsWidgets);

    // 4. Simulate dropping the correct color (colPink, which is index 2 in parts bin) onto the target.
    // Master pattern index 5 is colPink.
    // Let's find the DragTarget in Row 1.
    final dragTargetFinder = find.byType(DragTarget<Color>);
    expect(dragTargetFinder, findsOneWidget);

    // Let's find the Pink color draggable in parts bin.
    // Parts bin draggables: Blue, Yellow, Pink.
    final draggableFinder = find.byType(Draggable<Color>);
    expect(draggableFinder, findsNWidgets(3)); // 3 colors in Parts Bin

    final Offset pinkDraggableOffset = tester.getCenter(draggableFinder.at(2)); // Pink
    final Offset targetOffset = tester.getCenter(dragTargetFinder.first);

    // Perform drag and drop
    final TestGesture gesture = await tester.startGesture(pinkDraggableOffset);
    await gesture.moveTo(targetOffset);
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify Row 0 is now corrected, showError is false, and "Perbaiki eror!" is hidden for Row 0
    expect(row0.isCorrected, isTrue);
    expect(row0.showError, isFalse);
  });
}
