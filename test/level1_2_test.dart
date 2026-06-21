import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/spatial/line_tracing_screen.dart';
import 'package:apkuas/features/spatial/advanced_line_tracing_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('LineTracingScreen (Level 1) Scroll Card Layout drawing test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const LineTracingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header and instruction
    expect(find.text('Tiru Garis Dasar'), findsOneWidget);
    expect(find.text('Tiru garis tegak, datar, dan miring di bawah ini!'), findsOneWidget);

    // Verify all 3 challenges are visible
    expect(find.text('Garis Vertikal'), findsOneWidget);
    expect(find.text('Garis Horizontal'), findsOneWidget);
    expect(find.text('Garis Diagonal'), findsOneWidget);

    // Verify no challenge is completed yet
    expect(find.text('Selesai!'), findsNothing);

    // Get finder for Drawing Area for Challenge 0 (Garis Vertikal)
    final drawingArea0Finder = find.byKey(const ValueKey('drawing_area_0'));
    expect(drawingArea0Finder, findsOneWidget);

    Offset topLeft0 = tester.getTopLeft(drawingArea0Finder);
    Size size0 = tester.getSize(drawingArea0Finder);

    Offset dot0_0 = topLeft0 + Offset(0.25 * size0.width, 0.25 * size0.height);
    Offset dot0_2 = topLeft0 + Offset(0.25 * size0.width, 0.75 * size0.height);

    // Draw correct vertical line (0 to 2) on card 0
    TestGesture g1 = await tester.startGesture(dot0_0);
    await g1.moveTo(dot0_2);
    await g1.up();
    await tester.pumpAndSettle();

    // Card 0 should display "Selesai!" (now total 1 completed)
    expect(find.text('Selesai!'), findsOneWidget);

    // Get finder for Drawing Area for Challenge 1 (Garis Horizontal)
    final drawingArea1Finder = find.byKey(const ValueKey('drawing_area_1'));
    expect(drawingArea1Finder, findsOneWidget);

    Offset topLeft1 = tester.getTopLeft(drawingArea1Finder);
    Size size1 = tester.getSize(drawingArea1Finder);

    Offset dot1_0 = topLeft1 + Offset(0.25 * size1.width, 0.25 * size1.height);
    Offset dot1_1 = topLeft1 + Offset(0.75 * size1.width, 0.25 * size1.height);

    // Draw correct horizontal line (0 to 1) on card 1
    TestGesture g2 = await tester.startGesture(dot1_0);
    await g2.moveTo(dot1_1);
    await g2.up();
    await tester.pumpAndSettle();

    // Card 1 should display "Selesai!" (now total 2 completed)
    expect(find.text('Selesai!'), findsNWidgets(2));

    // Get finder for Drawing Area for Challenge 2 (Garis Diagonal)
    final drawingArea2Finder = find.byKey(const ValueKey('drawing_area_2'));
    expect(drawingArea2Finder, findsOneWidget);

    Offset topLeft2 = tester.getTopLeft(drawingArea2Finder);
    Size size2 = tester.getSize(drawingArea2Finder);

    Offset dot2_2 = topLeft2 + Offset(0.25 * size2.width, 0.75 * size2.height);
    Offset dot2_1 = topLeft2 + Offset(0.75 * size2.width, 0.25 * size2.height);

    // Draw correct diagonal line (2 to 1) on card 2
    TestGesture g3 = await tester.startGesture(dot2_2);
    await g3.moveTo(dot2_1);
    await g3.up();
    await tester.pump(); // Simple pump, do not settle to avoid celebration animation timeout

    // Wait for the victory transition to complete (500ms delay + 2.5s overlay animation)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    // Verify victory overlay is displayed
    expect(find.text('HEBAT! 🎉'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('AdvancedLineTracingScreen (Level 2) Scroll Card Layout drawing test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const AdvancedLineTracingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify headers
    expect(find.text('Garis Majemuk'), findsOneWidget);
    expect(find.text('Tiru garis tegak, datar, dan miring di bawah ini!'), findsOneWidget);

    // Verify all 3 challenges
    expect(find.text('Garis Vertikal'), findsOneWidget);
    expect(find.text('Garis Horizontal'), findsOneWidget);
    expect(find.text('Garis Diagonal'), findsOneWidget);

    // Verify no challenge is completed yet
    expect(find.text('Selesai!'), findsNothing);

    // Challenge 0: Garis Vertikal (expects 2 vertical lines: 0 to 2 and 1 to 3)
    final drawingArea0Finder = find.byKey(const ValueKey('drawing_area_0'));
    Offset topLeft0 = tester.getTopLeft(drawingArea0Finder);
    Size size0 = tester.getSize(drawingArea0Finder);

    Offset dot0_0 = topLeft0 + Offset(0.25 * size0.width, 0.25 * size0.height);
    Offset dot0_2 = topLeft0 + Offset(0.25 * size0.width, 0.75 * size0.height);
    Offset dot0_1 = topLeft0 + Offset(0.75 * size0.width, 0.25 * size0.height);
    Offset dot0_3 = topLeft0 + Offset(0.75 * size0.width, 0.75 * size0.height);

    // Draw first line (0 to 2)
    TestGesture g0a = await tester.startGesture(dot0_0);
    await g0a.moveTo(dot0_2);
    await g0a.up();
    await tester.pumpAndSettle();

    // Verify not finished yet
    expect(find.text('Selesai!'), findsNothing);

    // Draw second line (1 to 3)
    TestGesture g0b = await tester.startGesture(dot0_1);
    await g0b.moveTo(dot0_3);
    await g0b.up();
    await tester.pumpAndSettle();

    // Now verified as completed (1 completed)
    expect(find.text('Selesai!'), findsOneWidget);

    // Challenge 1: Garis Horizontal (expects 2 horizontal lines: 0 to 1 and 2 to 3)
    final drawingArea1Finder = find.byKey(const ValueKey('drawing_area_1'));
    Offset topLeft1 = tester.getTopLeft(drawingArea1Finder);
    Size size1 = tester.getSize(drawingArea1Finder);

    Offset dot1_0 = topLeft1 + Offset(0.25 * size1.width, 0.25 * size1.height);
    Offset dot1_1 = topLeft1 + Offset(0.75 * size1.width, 0.25 * size1.height);
    Offset dot1_2 = topLeft1 + Offset(0.25 * size1.width, 0.75 * size1.height);
    Offset dot1_3 = topLeft1 + Offset(0.75 * size1.width, 0.75 * size1.height);

    // Draw horizontal lines
    TestGesture g1a = await tester.startGesture(dot1_0);
    await g1a.moveTo(dot1_1);
    await g1a.up();
    await tester.pumpAndSettle();

    TestGesture g1b = await tester.startGesture(dot1_2);
    await g1b.moveTo(dot1_3);
    await g1b.up();
    await tester.pumpAndSettle();

    // Now verified as completed (2 completed)
    expect(find.text('Selesai!'), findsNWidgets(2));

    // Challenge 2: Garis Diagonal (expects 2 crossing lines: 0 to 3 and 1 to 2)
    final drawingArea2Finder = find.byKey(const ValueKey('drawing_area_2'));
    Offset topLeft2 = tester.getTopLeft(drawingArea2Finder);
    Size size2 = tester.getSize(drawingArea2Finder);

    Offset dot2_0 = topLeft2 + Offset(0.25 * size2.width, 0.25 * size2.height);
    Offset dot2_3 = topLeft2 + Offset(0.75 * size2.width, 0.75 * size2.height);
    Offset dot2_1 = topLeft2 + Offset(0.75 * size2.width, 0.25 * size2.height);
    Offset dot2_2 = topLeft2 + Offset(0.25 * size2.width, 0.75 * size2.height);

    // Draw diagonal lines
    TestGesture g2a = await tester.startGesture(dot2_0);
    await g2a.moveTo(dot2_3);
    await g2a.up();
    await tester.pumpAndSettle();

    TestGesture g2b = await tester.startGesture(dot2_1);
    await g2b.moveTo(dot2_2);
    await g2b.up();
    await tester.pump(); // Simple pump, do not settle to avoid celebration animation timeout

    // Wait for transition/dialog (500ms delay + 2.5s overlay animation)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));

    // Verify celebration overlay (dialog) shows for Level 2
    expect(find.text('LUAR BIASA! 🎉'), findsOneWidget);

    // Clear timers
    await tester.pump(const Duration(seconds: 5));
  });
}
