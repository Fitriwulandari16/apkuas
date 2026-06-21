import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/matching/decomposition_matching_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('DecompositionMatchingScreen (Level 14) Picker and Tap logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const DecompositionMatchingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify instruction and title
    expect(find.text('Pilih warna di bawah, lalu ketuk bentuk penyusun yang tepat!'), findsOneWidget);

    final dynamic state = tester.state(find.byType(DecompositionMatchingScreen));
    expect(state.selectedItems.values.every((v) => v == false), isTrue);

    // Get color pickers
    final greenPicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.green);
    final yellowPicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.yellow.shade700);
    final bluePicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.blue);
    final orangePicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.orange);

    // Select Green
    await tester.tap(greenPicker, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 1. Solve Tantangan A (Top Grid)
    for (int i = 0; i < state.topGridItems.length; i++) {
      final item = state.topGridItems[i];
      if (item.isCorrect) {
        // Select correct color
        Color pickerColor = item.color;
        if (pickerColor == Colors.yellow.shade700) {
          await tester.tap(yellowPicker, warnIfMissed: false);
        } else if (pickerColor == Colors.green) {
          await tester.tap(greenPicker, warnIfMissed: false);
        } else if (pickerColor == Colors.blue) {
          await tester.tap(bluePicker, warnIfMissed: false);
        } else if (pickerColor == Colors.orange) {
          await tester.tap(orangePicker, warnIfMissed: false);
        }
        await tester.pumpAndSettle();

        // Tap the shape in top GridView
        final topGrid = find.byType(GridView).first;
        final shapeGesture = find.descendant(
          of: topGrid,
          matching: find.byWidgetPredicate((w) => w is GestureDetector && w.child is Container),
        );
        await tester.tap(shapeGesture.at(i), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }

    // Scroll down to bring Tantangan B into view
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // 2. Solve Tantangan B (Bottom Grid)
    for (int i = 0; i < state.bottomGridItems.length; i++) {
      final item = state.bottomGridItems[i];
      if (item.isCorrect) {
        // Select correct color
        Color pickerColor = item.color;
        if (pickerColor == Colors.yellow.shade700) {
          await tester.tap(yellowPicker, warnIfMissed: false);
        } else if (pickerColor == Colors.green) {
          await tester.tap(greenPicker, warnIfMissed: false);
        } else if (pickerColor == Colors.blue) {
          await tester.tap(bluePicker, warnIfMissed: false);
        } else if (pickerColor == Colors.orange) {
          await tester.tap(orangePicker, warnIfMissed: false);
        }
        await tester.pumpAndSettle();

        // Tap the shape in bottom GridView
        final bottomGrid = find.byType(GridView).last;
        final shapeGesture = find.descendant(
          of: bottomGrid,
          matching: find.byWidgetPredicate((w) => w is GestureDetector && w.child is Container),
        );
        await tester.tap(shapeGesture.at(i), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }

    expect(state.isAllSolved, isTrue);

    // Verify celebration overlay (gameWin is triggered automatically with 400ms delay)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    expect(find.text('Luar Biasa!'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
