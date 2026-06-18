import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/features/matching/chicken_pathfinding_screen.dart';

void main() {
  setUpAll(() {
    // Disable HTTP fetching for Google Fonts in tests to avoid AssetManifest.bin exceptions
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ChickenPathfindingScreen (Level 45) Drag and Drop Test', (WidgetTester tester) async {
    // Set a tablet-like physical size to ensure everything fits comfortably
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChickenPathfindingScreen(levelId: 45),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header and instructions render correctly
    expect(find.text('Level 45'), findsOneWidget);
    expect(
      find.text('Seret bentuk ke gelembung yang sesuai dengan petunjuk contoh!'),
      findsOneWidget,
    );

    // 2. Verify we do NOT have Reset and Bantuan buttons anymore
    expect(find.text('Reset'), findsNothing);
    expect(find.text('Bantuan'), findsNothing);

    // 3. Verify legend and parts bin are visible
    expect(find.byType(PartsBinItem), findsNWidgets(5));
    expect(find.byType(DragTarget<String>), findsNWidgets(12));

    final dynamic state = tester.state(find.byType(ChickenPathfindingScreen));
    expect(state.dots[0]['mark'], equals(''));

    // 4. Test Drag and Drop: Drag correct shape 'x' (draggable index 0) to blue target (index 0)
    final draggableFinder = find.byType(Draggable<String>);
    final targetFinder = find.byType(DragTarget<String>);

    final Offset draggableXOffset = tester.getCenter(draggableFinder.at(0));
    final Offset targetBlueOffset = tester.getCenter(targetFinder.at(0));

    final TestGesture gestureCorrect = await tester.startGesture(draggableXOffset);
    await gestureCorrect.moveTo(targetBlueOffset);
    await gestureCorrect.up();
    await tester.pumpAndSettle();

    // Verify it is accepted and sets mark to 'x'
    expect(state.dots[0]['mark'], equals('x'));

    // 5. Test Drag and Drop Wrong Shape: Drag 'plus' (index 1) to green target (index 2)
    // Green target (index 2) expects 'triangle', not 'plus'
    final Offset draggablePlusOffset = tester.getCenter(draggableFinder.at(1));
    final Offset targetGreenOffset = tester.getCenter(targetFinder.at(2));

    final TestGesture gestureWrong = await tester.startGesture(draggablePlusOffset);
    await gestureWrong.moveTo(targetGreenOffset);
    await gestureWrong.up();
    await tester.pumpAndSettle();

    // Verify it is NOT accepted (remains empty)
    expect(state.dots[2]['mark'], equals(''));
  });
}
