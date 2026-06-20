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

    // 1. Verify header instructions and legend title render correctly
    expect(find.text('Level 50'), findsOneWidget);
    expect(find.text('PALET PILIHAN WARNA'), findsOneWidget);
    expect(
      find.text('Pilih warna di palet bawah dulu, lalu warnai kotak angka yang cocok!'),
      findsOneWidget,
    );

    // 2. Verify state initialization: 100 cells, active color selection starts as null
    final dynamic state = tester.state(find.byType(Level50Screen));
    expect(state.gridNumbers.length, equals(100));
    expect(state.selectedColorNumber, isNull);
    expect(state.userColors.every((val) => val == null), isTrue);

    // 3. Tap a cell without selecting color -> should NOT color it
    final firstCellFinder = find.byKey(const ValueKey('grid_cell_0'));
    await tester.tap(firstCellFinder);
    await tester.pumpAndSettle();
    expect(state.userColors[0], isNull);

    // 4. Find the target number for cell 0
    final int cell0TargetNumber = state.gridNumbers[0];

    // Select an INCORRECT color first: if target is NOT 1, select 1. If target IS 1, select 2.
    final int incorrectColorNumber = cell0TargetNumber == 1 ? 2 : 1;
    final incorrectColorPicker = find.byKey(ValueKey('palette_color_$incorrectColorNumber'));
    await tester.tap(incorrectColorPicker);
    await tester.pumpAndSettle();
    expect(state.selectedColorNumber, equals(incorrectColorNumber));

    // Tap cell 0 with incorrect color selected -> should NOT color it
    await tester.tap(firstCellFinder);
    await tester.pumpAndSettle();
    expect(state.userColors[0], isNull);

    // Select the CORRECT color for cell 0
    final correctColorPicker = find.byKey(ValueKey('palette_color_$cell0TargetNumber'));
    await tester.tap(correctColorPicker);
    await tester.pumpAndSettle();
    expect(state.selectedColorNumber, equals(cell0TargetNumber));

    // Tap cell 0 with correct color selected -> should color it successfully!
    await tester.tap(firstCellFinder);
    await tester.pumpAndSettle();
    expect(state.userColors[0], equals(cell0TargetNumber));

    // 5. Test reset button "Ulangi"
    final ulangiFinder = find.text('Ulangi');
    expect(ulangiFinder, findsOneWidget);
    await tester.tap(ulangiFinder);
    await tester.pumpAndSettle();

    // Verify reset cleared colors and color picker selection state
    expect(state.userColors.every((val) => val == null), isTrue);
    expect(state.selectedColorNumber, isNull);
  });
}
