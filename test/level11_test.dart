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

  testWidgets('ShapeCompletionScreen (Level 11) Drag and Drop logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const ShapeCompletionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify instruction and title
    expect(find.text('Geser potongan ke bentuk yang tepat!'), findsOneWidget);

    final dynamic state = tester.state(find.byType(ShapeCompletionScreen));
    expect(state.completed['square'], isFalse);
    expect(state.completed['circle'], isFalse);
    expect(state.completed['pentagon'], isFalse);
    expect(state.completed['heart'], isFalse);

    // Verify all 4 draggables exist
    for (var id in ['square', 'circle', 'pentagon', 'heart']) {
      final draggable = find.byWidgetPredicate((w) => w is Draggable<String> && w.data == id);
      expect(draggable, findsOneWidget);
    }

    // Try dragging correct shape to square target
    final squareCardFinder = find.byKey(state.cardKeys['square']!);
    final squareDraggable = find.byWidgetPredicate((w) => w is Draggable<String> && w.data == 'square');

    TestGesture dragGesture = await tester.startGesture(tester.getCenter(squareDraggable));
    await dragGesture.moveTo(tester.getCenter(squareCardFinder));
    await dragGesture.up();
    await tester.pumpAndSettle();

    expect(state.completed['square'], isTrue);

    // Test Reset
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    expect(state.completed['square'], isFalse);

    // Solve all shapes to trigger victory
    for (var id in ['square', 'circle', 'pentagon', 'heart']) {
      final cardFinder = find.byKey(state.cardKeys[id]!);
      final draggable = find.byWidgetPredicate((w) => w is Draggable<String> && w.data == id);
      
      TestGesture gesture = await tester.startGesture(tester.getCenter(draggable));
      await gesture.moveTo(tester.getCenter(cardFinder));
      await gesture.up();
      
      if (id == 'heart') {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      } else {
        await tester.pumpAndSettle();
      }
    }

    // Verify celebration overlay
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));
    expect(find.text('Hebat! ✨'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
