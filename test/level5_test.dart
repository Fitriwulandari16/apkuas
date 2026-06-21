import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/spatial/shape_matching_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('ShapeMatchingScreen (Level 5) Drag and Drop game logic test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const ShapeMatchingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify headers and elements are rendered
    expect(find.text('Cocokkan Bentuk'), findsOneWidget);
    expect(find.text('Pasangkan Bentuk ke Rumahnya!'), findsOneWidget);
    expect(find.text('Kotak'), findsOneWidget);
    expect(find.text('Lingkaran'), findsOneWidget);
    expect(find.text('Segitiga'), findsOneWidget);

    final squareDraggable = find.byKey(const ValueKey('draggable_shape_square'));
    final circleDraggable = find.byKey(const ValueKey('draggable_shape_circle'));
    final triangleDraggable = find.byKey(const ValueKey('draggable_shape_triangle'));

    final squareTarget = find.byKey(const ValueKey('target_card_square'));
    final circleTarget = find.byKey(const ValueKey('target_card_circle'));
    final triangleTarget = find.byKey(const ValueKey('target_card_triangle'));

    expect(squareDraggable, findsOneWidget);
    expect(circleDraggable, findsOneWidget);
    expect(triangleDraggable, findsOneWidget);
    expect(squareTarget, findsOneWidget);
    expect(circleTarget, findsOneWidget);
    expect(triangleTarget, findsOneWidget);

    // 2. Drag INCORRECT shape: Circle to Square target -> should not match
    final TestGesture incorrectDrag = await tester.startGesture(tester.getCenter(circleDraggable));
    await incorrectDrag.moveTo(tester.getCenter(squareTarget));
    await incorrectDrag.up();
    await tester.pumpAndSettle();

    // Verify snackbar warning is shown
    expect(find.text('Ups! Itu bukan rumah Kotak!'), findsOneWidget);
    
    // Hide snackbar
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 3. Drag CORRECT shape: Square to Square target
    final TestGesture correctDragSquare = await tester.startGesture(tester.getCenter(squareDraggable));
    await correctDragSquare.moveTo(tester.getCenter(squareTarget));
    await correctDragSquare.up();
    await tester.pumpAndSettle();

    // The square draggable should be gone (replaced with empty slot), so finding it matches nothing
    expect(find.byKey(const ValueKey('draggable_shape_square')), findsNothing);

    // 4. Test Reset button "Ulangi"
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    // Square draggable should be back!
    expect(find.byKey(const ValueKey('draggable_shape_square')), findsOneWidget);

    // Get the dynamic positions again in case they shuffled
    final squareDraggableNew = find.byKey(const ValueKey('draggable_shape_square'));
    final circleDraggableNew = find.byKey(const ValueKey('draggable_shape_circle'));
    final triangleDraggableNew = find.byKey(const ValueKey('draggable_shape_triangle'));

    final squareTargetNew = find.byKey(const ValueKey('target_card_square'));
    final circleTargetNew = find.byKey(const ValueKey('target_card_circle'));
    final triangleTargetNew = find.byKey(const ValueKey('target_card_triangle'));

    // 5. Solve all shapes to trigger victory
    // Square
    final TestGesture drag1 = await tester.startGesture(tester.getCenter(squareDraggableNew));
    await drag1.moveTo(tester.getCenter(squareTargetNew));
    await drag1.up();
    await tester.pumpAndSettle();

    // Circle
    final TestGesture drag2 = await tester.startGesture(tester.getCenter(circleDraggableNew));
    await drag2.moveTo(tester.getCenter(circleTargetNew));
    await drag2.up();
    await tester.pumpAndSettle();

    // Triangle
    final TestGesture drag3 = await tester.startGesture(tester.getCenter(triangleDraggableNew));
    await drag3.moveTo(tester.getCenter(triangleTargetNew));
    await drag3.up();
    await tester.pump(); // Simple pump, do not settle to avoid celebration animation timeout

    // Wait for the transition / celebration overlay to render (500ms + 2.5s)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    // Verify victory overlay is displayed
    expect(find.text('LUAR BIASA! 🌟'), findsOneWidget);

    // Clean timers
    await tester.pump(const Duration(seconds: 5));
  });
}
