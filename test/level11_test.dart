import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/spatial/shape_completion_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('ShapeCompletionScreen (Level 11) Picker and Tap logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const ShapeCompletionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify instruction and title
    expect(find.text('Pilih warna di bawah, lalu lengkapi bentuk yang sesuai!'), findsOneWidget);

    // Verify 4 target shape cards exist
    final dynamic state = tester.state(find.byType(ShapeCompletionScreen));
    expect(state.completed['square'], isFalse);
    expect(state.completed['circle'], isFalse);
    expect(state.completed['pentagon'], isFalse);
    expect(state.completed['heart'], isFalse);

    // Find the color circles in the palette
    // Palette colors: Green (for square), Yellow.shade700 (for circle), Blue (for pentagon), Red (for heart)
    // Tapping target shape card without selected color does nothing
    final squareCardFinder = find.byKey(state.cardKeys['square']);
    await tester.tap(squareCardFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.completed['square'], isFalse);

    // 1. Select Green
    final greenPicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.green && (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    expect(greenPicker, findsOneWidget);
    await tester.tap(greenPicker);
    await tester.pumpAndSettle();

    // Tap WRONG target first (Circle)
    final circleCardFinder = find.byKey(state.cardKeys['circle']);
    await tester.tap(circleCardFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.completed['circle'], isFalse);

    // Tap CORRECT target (Square)
    await tester.tap(squareCardFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.completed['square'], isTrue);

    // 2. Test Reset
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();
    expect(state.completed['square'], isFalse);

    // 3. Solve all shapes to trigger victory
    // Re-select Green and tap Square
    await tester.tap(greenPicker);
    await tester.pumpAndSettle();
    await tester.tap(squareCardFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Select Yellow and tap Circle
    final yellowPicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.yellow.shade700 && (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    await tester.tap(yellowPicker);
    await tester.pumpAndSettle();
    await tester.tap(circleCardFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Select Blue and tap Pentagon
    final bluePicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.blue && (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    final pentagonCardFinder = find.byKey(state.cardKeys['pentagon']);
    await tester.tap(bluePicker);
    await tester.pumpAndSettle();
    await tester.tap(pentagonCardFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Select Red and tap Heart (completes game)
    final redPicker = find.byWidgetPredicate((widget) => widget is Container && widget.decoration is BoxDecoration && (widget.decoration as BoxDecoration).color == Colors.red && (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    final heartCardFinder = find.byKey(state.cardKeys['heart']);
    await tester.tap(redPicker);
    await tester.pumpAndSettle();
    await tester.tap(heartCardFinder, warnIfMissed: false);
    
    // We expect the celebration pop up
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    expect(find.text('Hebat! ✨'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
