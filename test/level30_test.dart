import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/features/matching/circle_conditional_patterns_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('CircleConditionalPatternsScreen Drag and Drop Game Logic Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const CircleConditionalPatternsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header and instructions render correctly
    expect(find.text('Level 30'), findsOneWidget);
    expect(find.text('PALET PILIHAN'), findsOneWidget);
    expect(
      find.text('Seret pola dari palet bawah ke kotak warna yang cocok!'),
      findsOneWidget,
    );

    final dynamic state = tester.state(find.byType(CircleConditionalPatternsScreen));
    expect(state.circles.length, equals(16));
    expect(state.circles.every((c) => !c.isCorrect), isTrue);

    // 2. Drag correct pattern 'x' to yellow circle target (index 0)
    final draggableFinder = find.byKey(const ValueKey('draggable_pattern_x'));
    final targetFinder = find.byKey(const ValueKey('circle_target_0'));

    expect(draggableFinder, findsOneWidget);
    expect(targetFinder, findsOneWidget);

    final Offset dragSource = tester.getCenter(draggableFinder);
    final Offset dragTarget = tester.getCenter(targetFinder);

    final TestGesture gestureCorrect = await tester.startGesture(dragSource);
    await gestureCorrect.moveTo(dragTarget);
    await gestureCorrect.up();
    await tester.pumpAndSettle();

    // Verify Yellow circle index 0 is correct and has 'x' pattern
    expect(state.circles[0].isCorrect, isTrue);
    expect(state.circles[0].placedPattern, equals('x'));

    // 3. Drag incorrect pattern 'x' to Green circle (index 1) which expects '+'
    final greenTarget = find.byKey(const ValueKey('circle_target_1'));

    final TestGesture gestureWrong = await tester.startGesture(dragSource);
    await gestureWrong.moveTo(tester.getCenter(greenTarget));
    await gestureWrong.up();
    await tester.pumpAndSettle();

    // Verify Green circle is NOT correct
    expect(state.circles[1].isCorrect, isFalse);

    // 4. Reset Level and verify it clears progress
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    expect(state.circles.every((c) => !c.isCorrect), isTrue);
  });
}
