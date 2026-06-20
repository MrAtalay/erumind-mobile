import 'package:erumind/data/models/category.dart';
import 'package:erumind/features/game/presentation/widgets/category_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const categories = [
    Category(id: 'a', name: 'Alpha', colorValue: 0xFF111111),
    Category(id: 'b', name: 'Beta', colorValue: 0xFF222222),
    Category(id: 'c', name: 'Gamma', colorValue: 0xFF333333),
  ];

  testWidgets('spinning the wheel selects a category', (tester) async {
    Category? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 420,
              child: CategoryWheel(
                categories: categories,
                spinLabel: 'Spin',
                onSelected: (c) => selected = c,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Spin'), findsOneWidget);
    expect(selected, isNull);

    await tester.tap(find.text('Spin'));
    await tester.pumpAndSettle();

    // The spin animation has finished and reported a landed category.
    expect(selected, isNotNull);
    expect(categories, contains(selected));
  });
}
