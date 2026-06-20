import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/features/matching/tangled_lines_maze_level47_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('FishShapeMatchingScreen (Level 47) Line Drawing Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FishShapeMatchingScreen(levelId: 47),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header and instructions render correctly
    expect(find.text('Level 47'), findsOneWidget);
    expect(
      find.text('Tarik garis dari titik ikan ke bentuk geometri yang sesuai!'),
      findsOneWidget,
    );

    // 2. Find the GestureDetector
    final gestureDetectorFinder = find.byKey(const ValueKey('drawing_gesture_detector'));
    expect(gestureDetectorFinder, findsOneWidget);

    final dynamic state = tester.state(find.byType(FishShapeMatchingScreen));
    expect(state.completedLines, isEmpty);

    final Size size = tester.getSize(gestureDetectorFinder);
    final Offset globalOrigin = tester.getTopLeft(gestureDetectorFinder);

    final double width = size.width;
    final double height = size.height;

    final leftAnchorX = globalOrigin.dx + 125.0;
    final rightAnchorX = globalOrigin.dx + width - 125.0;

    final y0 = globalOrigin.dy + height * 0.08;
    final rowHeight = height * 0.13;

    // Test a correct pair: Puffer (index 0) -> Persegi/Square (index 4)
    final Offset pufferAnchor = Offset(leftAnchorX, y0 + 0 * rowHeight);
    final Offset squareAnchor = Offset(rightAnchorX, y0 + 4 * rowHeight);

    final TestGesture gestureCorrect = await tester.startGesture(pufferAnchor);
    await gestureCorrect.moveTo(squareAnchor);
    await gestureCorrect.up();
    await tester.pumpAndSettle();

    expect(state.completedLines[0], equals(4));

    // Test an incorrect pair: Striped (index 1) -> Segitiga/Triangle (index 0)
    final Offset stripedAnchor = Offset(leftAnchorX, y0 + 1 * rowHeight);
    final Offset triangleAnchor = Offset(rightAnchorX, y0 + 0 * rowHeight);

    final TestGesture gestureIncorrect = await tester.startGesture(stripedAnchor);
    await gestureIncorrect.moveTo(triangleAnchor);
    await gestureIncorrect.up();
    await tester.pumpAndSettle();

    expect(state.completedLines.containsKey(1), isFalse);

    // Test reset using "Ulangi"
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    expect(state.completedLines, isEmpty);
  });
}
