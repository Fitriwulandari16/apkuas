import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/matching/shape_color_matching_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('ShapeColorMatchingScreen (Level 15) Drag and Drop logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const ShapeColorMatchingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify instructions
    expect(find.text('Tarik dan tempelkan pada bentuk yang tepat!'), findsOneWidget);

    final dynamic state = tester.state(find.byType(ShapeColorMatchingScreen));
    expect(state.matchedIds.isEmpty, isTrue);

    // Verify all 6 solid shapes are rendered as draggables at the bottom
    final expectedDraggables = [
      'rhombus_green',
      'circle_green',
      'trapezoid_yellow',
      'circle_blue',
      'triangle_blue',
      'triangle_yellow',
    ];
    for (var key in expectedDraggables) {
      final shapeDraggable = find.byWidgetPredicate((w) => w is Draggable<String> && w.data == key);
      expect(shapeDraggable, findsOneWidget);
    }

    // Solve the first target to test drag validation and resetting
    final firstTarget = state.targets[0];
    final firstTargetCardFinder = find.byType(DragTarget<String>).at(0);
    final firstShapeName = firstTarget.shape.toString().split('.').last;
    final correctDraggableKey = "${firstShapeName}_${firstTarget.colorName}";
    final correctDraggableFinder = find.byWidgetPredicate((w) => w is Draggable<String> && w.data == correctDraggableKey);

    // Test drop correct shape
    TestGesture dragGesture = await tester.startGesture(tester.getCenter(correctDraggableFinder));
    await dragGesture.moveTo(tester.getCenter(firstTargetCardFinder));
    await dragGesture.up();
    await tester.pumpAndSettle();

    expect(state.matchedIds.contains(firstTarget.id), isTrue);

    // Test Reset Button
    final resetBtn = find.text('Ulangi');
    expect(resetBtn, findsOneWidget);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    // Verify reset cleared progress
    expect(state.matchedIds.isEmpty, isTrue);

    // Now solve all targets correctly
    for (int i = 0; i < state.targets.length; i++) {
      final target = state.targets[i];
      final targetCardFinder = find.byType(DragTarget<String>).at(i);
      final shapeName = target.shape.toString().split('.').last;
      final key = "${shapeName}_${target.colorName}";
      final shapeDraggable = find.byWidgetPredicate((w) => w is Draggable<String> && w.data == key);

      TestGesture gesture = await tester.startGesture(tester.getCenter(shapeDraggable));
      await gesture.moveTo(tester.getCenter(targetCardFinder));
      await gesture.up();

      if (i == state.targets.length - 1) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      } else {
        await tester.pumpAndSettle();
      }
    }

    // Verify victory/celebration overlay
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));
    expect(find.text('Hebat Sekali!'), findsOneWidget);

    // Let victory overlays fade or timers clear
    await tester.pump(const Duration(seconds: 5));
  });
}
