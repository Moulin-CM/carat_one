import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/widgets/sell_options_sheet.dart';

void main() {
  testWidgets('bottom sheet keeps its action button on screen at 3x text scale',
      (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(3.0)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showSellOptionsSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'layout overflowed');

    final cancel = find.byType(TextButton);
    expect(cancel, findsOneWidget);
    final rect = tester.getRect(cancel);
    expect(rect.bottom, lessThanOrEqualTo(700.0));
    expect(rect.top, greaterThanOrEqualTo(0.0));
  });
}
