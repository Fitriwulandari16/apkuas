import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/features/matching/sequence_line_matching_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
    await Hive.openBox('progress');
  });

  testWidgets('SequenceLineMatchingScreen (Level 21) Widget Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SequenceLineMatchingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header, instruction, and legend
    expect(find.text('Level 21'), findsOneWidget);
    expect(find.text('Buat garis sesuai urutan warna!'), findsOneWidget);

    // Verify legend hexagons 1 to 5
    expect(find.text('1'), findsWidgets); // Legend and Tutorial card will have it
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text('5'), findsWidgets);

    // 2. Solve Challenge 0 (Tutorial Card)
    // Get finder and layout metrics for challenge box 0
    final box0Finder = find.byKey(const ValueKey('challenge_box_0'));
    expect(box0Finder, findsOneWidget);

    Offset topLeft0 = tester.getTopLeft(box0Finder);
    Size size0 = tester.getSize(box0Finder);

    // Challenge 0 Node positions (normalized coordinates)
    Offset node0_1 = topLeft0 + Offset(0.20 * size0.width, 0.18 * size0.height);
    Offset node0_2 = topLeft0 + Offset(0.80 * size0.width, 0.28 * size0.height);
    Offset node0_3 = topLeft0 + Offset(0.55 * size0.width, 0.50 * size0.height);
    Offset node0_4 = topLeft0 + Offset(0.22 * size0.width, 0.72 * size0.height);
    Offset node0_5 = topLeft0 + Offset(0.78 * size0.width, 0.82 * size0.height);

    // Drag: 1 -> 2
    TestGesture gesture = await tester.startGesture(node0_1);
    await gesture.moveTo(node0_2);
    await gesture.up();
    await tester.pumpAndSettle();

    // Drag: 2 -> 3
    gesture = await tester.startGesture(node0_2);
    await gesture.moveTo(node0_3);
    await gesture.up();
    await tester.pumpAndSettle();

    // Drag: 3 -> 4
    gesture = await tester.startGesture(node0_3);
    await gesture.moveTo(node0_4);
    await gesture.up();
    await tester.pumpAndSettle();

    // Drag: 4 -> 5
    gesture = await tester.startGesture(node0_4);
    await gesture.moveTo(node0_5);
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify Challenge 0 is completed (check badge)
    // Since challenge_box_0 is completed, there will be a check badge inside it
    expect(find.descendant(of: box0Finder, matching: find.byIcon(Icons.check)), findsOneWidget);

    // 3. Test Reset Button functionality
    final resetBtn = find.text('Ulangi');
    expect(resetBtn, findsOneWidget);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    // Verify check badge is gone from challenge box 0
    expect(find.descendant(of: box0Finder, matching: find.byIcon(Icons.check)), findsNothing);

    // 4. Solve all 4 challenges to trigger success
    // Solve Challenge 0 again
    await _solveChallenge(tester, 0, [
      const Offset(0.20, 0.18),
      const Offset(0.80, 0.28),
      const Offset(0.55, 0.50),
      const Offset(0.22, 0.72),
      const Offset(0.78, 0.82),
    ]);

    // Solve Challenge 1
    await _solveChallenge(tester, 1, [
      const Offset(0.22, 0.18),
      const Offset(0.80, 0.38),
      const Offset(0.80, 0.82),
      const Offset(0.50, 0.50),
      const Offset(0.20, 0.80),
    ]);

    // Solve Challenge 2
    await _solveChallenge(tester, 2, [
      const Offset(0.80, 0.82),
      const Offset(0.80, 0.35),
      const Offset(0.20, 0.82),
      const Offset(0.20, 0.18),
      const Offset(0.45, 0.50),
    ]);

    // Solve Challenge 3
    await _solveChallenge(tester, 3, [
      const Offset(0.68, 0.18),
      const Offset(0.20, 0.45),
      const Offset(0.48, 0.82),
      const Offset(0.78, 0.58),
      const Offset(0.80, 0.82),
    ]);

    // All challenge boxes should show check badges
    for (int i = 0; i < 4; i++) {
      final boxFinder = find.byKey(ValueKey('challenge_box_$i'));
      expect(find.descendant(of: boxFinder, matching: find.byIcon(Icons.check)), findsOneWidget);
    }

    // Wait for victory overlay and process pending timers
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2, milliseconds: 500));
    
    expect(find.text('Hebat Sekali!'), findsOneWidget);

    // Let any remaining timers/animations settle
    await tester.pump(const Duration(seconds: 5));
  });
}

Future<void> _solveChallenge(WidgetTester tester, int boxId, List<Offset> normalizedCoords) async {
  final boxFinder = find.byKey(ValueKey('challenge_box_$boxId'));
  Offset topLeft = tester.getTopLeft(boxFinder);
  Size size = tester.getSize(boxFinder);

  for (int i = 0; i < normalizedCoords.length - 1; i++) {
    Offset start = topLeft + Offset(normalizedCoords[i].dx * size.width, normalizedCoords[i].dy * size.height);
    Offset end = topLeft + Offset(normalizedCoords[i + 1].dx * size.width, normalizedCoords[i + 1].dy * size.height);

    TestGesture gesture = await tester.startGesture(start);
    await gesture.moveTo(end);
    await gesture.up();
    if (boxId == 3 && i == normalizedCoords.length - 2) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pumpAndSettle();
    }
  }
}
