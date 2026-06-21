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

  testWidgets('ShapeColorMatchingScreen (Level 15) Picker and Tap logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const ShapeColorMatchingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify instructions
    expect(find.text('Pilih warna di bawah, lalu lengkapi bentuk yang sesuai!'), findsOneWidget);

    final dynamic state = tester.state(find.byType(ShapeColorMatchingScreen));
    expect(state.matchedIds.isEmpty, isTrue);

    // Pickers: Light Blue, Light Green, Amber
    final bluePicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.lightBlue.shade400 && (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    final greenPicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.lightGreen.shade400 && (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    final yellowPicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.amber.shade400 && (widget.decoration as BoxDecoration).shape == BoxShape.circle);

    expect(bluePicker, findsOneWidget);
    expect(greenPicker, findsOneWidget);
    expect(yellowPicker, findsOneWidget);

    // Tap first target card (at index 0)
    final firstTarget = state.targets[0];
    final targetCardFinder = find.byWidgetPredicate((w) => w is GestureDetector && w.child is AnimatedBuilder);
    
    // Tap without color: nothing
    await tester.tap(targetCardFinder.at(0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.matchedIds.contains(firstTarget.id), isFalse);

    // Solve all targets by selecting corresponding color and tapping
    for (int i = 0; i < state.targets.length; i++) {
      final target = state.targets[i];
      
      // Select correct color
      if (target.color == Colors.lightBlue.shade400) {
        await tester.tap(bluePicker, warnIfMissed: false);
      } else if (target.color == Colors.lightGreen.shade400) {
        await tester.tap(greenPicker, warnIfMissed: false);
      } else {
        await tester.tap(yellowPicker, warnIfMissed: false);
      }
      await tester.pumpAndSettle();

      // Tap card
      await tester.tap(targetCardFinder.at(i), warnIfMissed: false);
      if (i == state.targets.length - 1) {
        await tester.pump(); // Pump once on final item to avoid celebration timeout
      } else {
        await tester.pumpAndSettle();
      }
    }

    // Verify celebration overlay
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    expect(find.text('Hebat Sekali!'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
