import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/spatial/multi_step_conditional_drawing_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('MultiStepConditionalDrawingScreen (Level 7) Drag and Drop game logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const MultiStepConditionalDrawingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header and legend elements are rendered cleanly
    expect(find.text('KUNCI PETUNJUK'), findsOneWidget);
    expect(find.text('Datar'), findsOneWidget);
    expect(find.text('Tegak'), findsOneWidget);
    expect(find.text('Tambah'), findsOneWidget);
    expect(find.text('Perhatikan warnanya dan buat garis yang tepat!'), findsOneWidget);

    // Verify equal/line/plus character symbols are NOT in the legend text
    expect(find.text('='), findsNothing);
    expect(find.text('|'), findsNothing);
    expect(find.text('—'), findsNothing);
    expect(find.text('+'), findsNothing);

    // Verify grid circles are rendered
    final targetCircle00 = find.byKey(const ValueKey('target_circle_0_0'));
    final targetCircle01 = find.byKey(const ValueKey('target_circle_0_1'));

    expect(targetCircle00, findsOneWidget);
    expect(targetCircle01, findsOneWidget);

    // Find the draggables
    final horizontalLineDraggable = find.byKey(const ValueKey('draggable_line_horizontal'));
    final verticalLineDraggable = find.byKey(const ValueKey('draggable_line_vertical'));
    final plusLineDraggable = find.byKey(const ValueKey('draggable_line_plus'));

    expect(horizontalLineDraggable, findsOneWidget);
    expect(verticalLineDraggable, findsOneWidget);
    expect(plusLineDraggable, findsOneWidget);

    // 2. Drag INCORRECT line: Horizontal to Blue target (row 0, col 1 is 'B')
    final TestGesture incorrectDrag = await tester.startGesture(tester.getCenter(horizontalLineDraggable));
    await incorrectDrag.moveTo(tester.getCenter(targetCircle01));
    await incorrectDrag.up();
    await tester.pumpAndSettle();

    // Verification of state (should NOT be completed yet)
    final dynamic state = tester.state(find.byType(MultiStepConditionalDrawingScreen));
    expect(state.completionStatus['0-1'], isFalse);

    // 3. Drag CORRECT line: Vertical to Blue target (row 0, col 1 is 'B')
    final TestGesture correctDrag = await tester.startGesture(tester.getCenter(verticalLineDraggable));
    await correctDrag.moveTo(tester.getCenter(targetCircle01));
    await correctDrag.up();
    await tester.pumpAndSettle();

    expect(state.completionStatus['0-1'], isTrue);

    // 4. Test reset button "Ulangi"
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    expect(state.completionStatus['0-1'], isFalse);

    // 5. Solve all 15 cells to trigger victory
    // Grid values:
    // row 0: R, B, Y
    // row 1: R, B, Y
    // row 2: Y, R, B
    // row 3: B, Y, R
    // row 4: Y, R, B
    final List<List<String>> localGrid = [
      ['R', 'B', 'Y'],
      ['R', 'B', 'Y'],
      ['Y', 'R', 'B'],
      ['B', 'Y', 'R'],
      ['Y', 'R', 'B'],
    ];

    for (int r = 0; r < localGrid.length; r++) {
      for (int c = 0; c < localGrid[r].length; c++) {
        final circleFinder = find.byKey(ValueKey('target_circle_${r}_${c}'));
        final type = localGrid[r][c];
        
        Finder lineDraggable;
        if (type == 'R') {
          lineDraggable = horizontalLineDraggable;
        } else if (type == 'B') {
          lineDraggable = verticalLineDraggable;
        } else {
          lineDraggable = plusLineDraggable;
        }

        final TestGesture drag = await tester.startGesture(tester.getCenter(lineDraggable));
        await drag.moveTo(tester.getCenter(circleFinder));
        await drag.up();
        
        if (r == localGrid.length - 1 && c == localGrid[r].length - 1) {
          await tester.pump(); // Simple pump for the final item to avoid celebration timeout
        } else {
          await tester.pumpAndSettle();
        }
      }
    }

    // Wait for victory overlay transition (500ms + 2.5s)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    // Verify victory dialog shows
    expect(find.text('HEBAT! 🌟'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
