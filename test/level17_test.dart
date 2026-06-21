import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/matching/sequence_completion_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('SequenceCompletionScreen (Level 17) Picker and Tap logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const SequenceCompletionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify instruction and title
    expect(find.text('Pilih warna di bawah, lalu pasang bingkai permen yang sesuai!'), findsOneWidget);

    final dynamic state = tester.state(find.byType(SequenceCompletionScreen));
    expect(state.cells.every((c) => !c.isMatched), isTrue);

    // Pickers (colTriangle, colCircle, colSquare)
    final trianglePicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).boxShadow != null && (widget.decoration as BoxDecoration).boxShadow![0].color == const Color(0xFF4CAF50).withOpacity(0.2));
    final circlePicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).boxShadow != null && (widget.decoration as BoxDecoration).boxShadow![0].color == const Color(0xFF2196F3).withOpacity(0.2));
    final squarePicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).boxShadow != null && (widget.decoration as BoxDecoration).boxShadow![0].color == const Color(0xFFF44336).withOpacity(0.2));

    expect(trianglePicker, findsOneWidget);
    expect(circlePicker, findsOneWidget);
    expect(squarePicker, findsOneWidget);

    // Tapping a grid cell:
    final gridCellFinder = find.byWidgetPredicate((w) => w is GestureDetector && w.child is AnimatedBuilder);
    
    // Tap without color: nothing
    await tester.tap(gridCellFinder.at(0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.cells[0].isMatched, isFalse);

    // Solve all required target cells
    for (int i = 0; i < state.cells.length; i++) {
      final cell = state.cells[i];
      if (cell.requiredShape != null) {
        // Select correct color
        if (cell.requiredShape == ShapeType.triangle) {
          await tester.tap(trianglePicker, warnIfMissed: false);
        } else if (cell.requiredShape == ShapeType.circle) {
          await tester.tap(circlePicker, warnIfMissed: false);
        } else {
          await tester.tap(squarePicker, warnIfMissed: false);
        }
        await tester.pumpAndSettle();

        // Tap cell
        await tester.tap(gridCellFinder.at(i), warnIfMissed: false);
        
        // Check if we are at the last target cell
        final remaining = state.cells.where((c) => c.requiredShape != null && !c.isMatched);
        if (remaining.isEmpty) {
          await tester.pump();
        } else {
          await tester.pumpAndSettle();
        }
      }
    }

    // Verify celebration overlay
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    expect(find.text('Hore! Kamu Pintar!'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
