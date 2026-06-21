import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/features/spatial/bee_home_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('BeeHomeScreen Tap-to-Color Game Logic Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const BeeHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header and instructions render correctly
    expect(find.text('LEVEL 12'), findsOneWidget);
    expect(find.text('Algoritma Pola'), findsOneWidget);
    expect(
      find.text('Warnai pola Biru ➔ Hijau untuk pulang!'),
      findsOneWidget,
    );

    final dynamic state = tester.state(find.byType(BeeHomeScreen));
    expect(state.beeIndex, equals(0));
    expect(state.hexagonColors[0], equals(Colors.blue));
    expect(state.hexagonColors[1], equals(Colors.white));

    // 2. Try tapping index 1 without selecting a color
    final firstInteractiveHexagonFinder = find.byKey(const ValueKey('hexagon_tap_1'));
    await tester.tap(firstInteractiveHexagonFinder);
    await tester.pumpAndSettle();

    // Verify color did not change
    expect(state.hexagonColors[1], equals(Colors.white));
    expect(state.beeIndex, equals(0));

    // 3. Select "Hijau" from the bottom palette
    final hijauPaletteFinder = find.text('Hijau');
    expect(hijauPaletteFinder, findsOneWidget);
    await tester.tap(hijauPaletteFinder);
    await tester.pumpAndSettle();

    expect(state.selectedColor, equals(Colors.green));

    // 4. Tap index 1 with "Hijau" (correct color for index 1)
    await tester.tap(firstInteractiveHexagonFinder);
    await tester.pumpAndSettle();

    // Verify it is now green and the bee moved to index 1
    expect(state.hexagonColors[1], equals(Colors.green));
    expect(state.beeIndex, equals(1));

    // 5. Select "Biru" from the bottom palette
    final biruPaletteFinder = find.text('Biru');
    expect(biruPaletteFinder, findsOneWidget);
    await tester.tap(biruPaletteFinder);
    await tester.pumpAndSettle();

    expect(state.selectedColor, equals(Colors.blue));

    // 6. Tap index 2 with "Biru" (correct color for index 2)
    final secondInteractiveHexagonFinder = find.byKey(const ValueKey('hexagon_tap_2'));
    await tester.tap(secondInteractiveHexagonFinder);
    await tester.pumpAndSettle();

    expect(state.hexagonColors[2], equals(Colors.blue));
    expect(state.beeIndex, equals(2));

    // 7. Reset Level and verify it clears progress
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    expect(state.beeIndex, equals(0));
    expect(state.hexagonColors[0], equals(Colors.blue));
    expect(state.hexagonColors[1], equals(Colors.white));
    expect(state.selectedColor, isNull);
  });
}
