import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/features/matching/hexagon_conditional_lines_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('HexagonConditionalLinesScreen Drag and Drop Game Logic Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const HexagonConditionalLinesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header and instructions render correctly
    expect(find.text('Level 29'), findsOneWidget);
    expect(find.text('PALET GARIS'), findsOneWidget);
    expect(
      find.text('Seret garis ke segienam dengan warna yang cocok!'),
      findsOneWidget,
    );

    final dynamic state = tester.state(find.byType(HexagonConditionalLinesScreen));
    expect(state.hexagons.length, equals(16));
    expect(state.hexagons.every((h) => !h.isCorrect), isTrue);

    // 2. Drag correct line '—' to blue hexagon target
    final draggableFinder = find.byKey(const ValueKey('draggable_line_—'));
    final targetFinder = find.byKey(const ValueKey('hexagon_target_0'));

    expect(draggableFinder, findsOneWidget);
    expect(targetFinder, findsOneWidget);

    final Offset dragSource = tester.getCenter(draggableFinder);
    final Offset dragTarget = tester.getCenter(targetFinder);

    final TestGesture gestureCorrect = await tester.startGesture(dragSource);
    await gestureCorrect.moveTo(dragTarget);
    await gestureCorrect.up();
    await tester.pumpAndSettle();

    // Verify Blue Hexagon index 0 is correct and has '—' drawn line
    expect(state.hexagons[0].isCorrect, isTrue);
    expect(state.hexagons[0].drawnLine, equals('—'));

    // 3. Drag incorrect line '—' to Yellow Hexagon (index 1) which expects '|'
    final yellowTarget = find.byKey(const ValueKey('hexagon_target_1'));

    final TestGesture gestureWrong = await tester.startGesture(dragSource);
    await gestureWrong.moveTo(tester.getCenter(yellowTarget));
    await gestureWrong.up();
    await tester.pumpAndSettle();

    // Verify Yellow Hexagon is NOT correct
    expect(state.hexagons[1].isCorrect, isFalse);

    // 4. Reset Level and verify it clears progress
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    expect(state.hexagons.every((h) => !h.isCorrect), isTrue);
  });
}
