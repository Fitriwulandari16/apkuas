import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/features/matching/level_50.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Level50Screen Tap to Color Grid Game Logic Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: const Level50Screen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify header instructions and legend render correctly
    expect(find.text('Level 50'), findsOneWidget);
    expect(find.text('PANDUAN WARNA'), findsOneWidget);
    expect(
      find.text('Ketuk kotak angka untuk mewarnai sesuai dengan kode warna petunjuk!'),
      findsOneWidget,
    );

    // 2. Verify state initialization with 100 cells
    final dynamic state = tester.state(find.byType(Level50Screen));
    expect(state.gridNumbers.length, equals(100));
    expect(state.userColors.every((val) => val == null), isTrue);

    // 3. Test tapping on cells
    final firstCellFinder = find.byKey(const ValueKey('grid_cell_0'));
    expect(firstCellFinder, findsOneWidget);

    final int targetNumber = state.gridNumbers[0];
    
    await tester.tap(firstCellFinder);
    await tester.pumpAndSettle();

    // Verify cell 0 has colored itself matching the target number code
    expect(state.userColors[0], equals(targetNumber));

    // 4. Test reset button "Ulangi"
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    // Verify reset cleared all cell colors
    expect(state.userColors.every((val) => val == null), isTrue);
  });
}
