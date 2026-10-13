import 'package:diohub/common/pagination/anchor_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selected anchor scrolls into view and visibly highlights', (
    final WidgetTester tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: const [
                SizedBox(height: 1200),
                AnchorHighlight(
                  isHighlighted: true,
                  child: SizedBox(height: 100, child: Text('linked comment')),
                ),
                SizedBox(height: 400),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(controller.offset, greaterThan(0));
    expect(find.text('linked comment'), findsOneWidget);
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AnchorHighlight),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(container.color?.alpha, greaterThan(0));
    await tester.pumpAndSettle();
  });
}
