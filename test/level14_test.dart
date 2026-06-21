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
    addTearDown(tester.view.resetPhysicalSize);

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

    final List<dynamic> allItems = [...state.topGridItems, ...state.bottomGridItems];
    // Tap and solve all correct items directly through state triggering or tapping
    // For simplicity, let's test tapping on correct grid shapes
    // To identify each item in the grid, we can look at the grid lists
    // Let's solve them step by step:
    for (var item in allItems) {
      if (item.isCorrect) {
        // Select its color first
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

        // Tap the shape
        // We find the shape gesture detector by checking the container's background color
        final shapeGesture = find.byWidgetPredicate((w) => w is GestureDetector && w.child is Container && (w.child as Container).decoration is BoxDecoration && ((w.child as Container).decoration as BoxDecoration).color == const Color(0xFFF8F9FA));
        // Let's tap the matching shape item by iterating gesture detectors
        int itemIndex = 0;
        if (state.topGridItems.any((e) => e.id == item.id)) {
          itemIndex = state.topGridItems.indexWhere((e) => e.id == item.id);
        } else {
          itemIndex = state.topGridItems.length + state.bottomGridItems.indexWhere((e) => e.id == item.id);
        }
        await tester.tap(shapeGesture.at(itemIndex), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }

    expect(state.isAllSolved, isTrue);

    // Click "Selesai" button
    final selesaiFinder = find.text('Selesai');
    expect(selesaiFinder, findsOneWidget);
    await tester.tap(selesaiFinder);

    // Verify celebration overlay
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    expect(find.text('Luar Biasa!'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
