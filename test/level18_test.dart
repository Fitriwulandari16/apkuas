import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/matching/infinite_drag_matching_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('InfiniteDragMatchingScreen (Level 18) Picker and Tap logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const InfiniteDragMatchingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify instruction and title
    expect(find.text('Pilih bingkai di bawah, lalu ketuk angka yang sesuai!'), findsOneWidget);

    final dynamic state = tester.state(find.byType(InfiniteDragMatchingScreen));
    expect(state.cells.every((c) => !c.isMatched), isTrue);

    // Pickers inside the row: Triangle, Circle, Square
    // Tapping target cell without selected shape does nothing
    final gridCellFinder = find.byWidgetPredicate((w) => w is GestureDetector && w.child is AnimatedBuilder);
    await tester.tap(gridCellFinder.at(0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.cells[0].isMatched, isFalse);

    // Solve all cells
    for (int i = 0; i < state.cells.length; i++) {
      final cell = state.cells[i];
      
      // Select corresponding picker shape
      // Tapping custom shape picker item by shape type
      final shapeButton = find.byWidgetPredicate((w) => w is GestureDetector && w.child is AnimatedScale);
      
      int buttonIndex = 0;
      if (cell.requiredShape == ShapeType.triangle) {
        buttonIndex = 0;
      } else if (cell.requiredShape == ShapeType.circle) {
        buttonIndex = 1;
      } else {
        buttonIndex = 2;
      }

      await tester.tap(shapeButton.at(buttonIndex), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap cell
      await tester.tap(gridCellFinder.at(i), warnIfMissed: false);
      
      if (i == state.cells.length - 1) {
        await tester.pump();
      } else {
        await tester.pumpAndSettle();
      }
    }

    // Verify celebration overlay
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    expect(find.text('Hebat! Kamu Pintar Mengelompokkan!'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
