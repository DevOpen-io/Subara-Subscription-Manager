import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/screens/intro_page.dart';

void main() {
  testWidgets('IntroPage calls onGetStarted when CTA tapped', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntroPage(onGetStarted: () => called = true),
        ),
      ),
    );
    await tester.pump();

    final ctaFinder = find.byType(FilledButton);
    expect(ctaFinder, findsOneWidget);

    await tester.tap(ctaFinder);
    expect(called, isTrue);
  });

  testWidgets('IntroPage fades Netflix card when pageOffset > 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntroPage(onGetStarted: () {}, pageOffset: 0.5),
        ),
      ),
    );
    await tester.pump();

    // Netflix card is wrapped in Opacity — find the one that fades with pageOffset
    final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
    // (1.0 - 0.5 * 3).clamp(0,1) = 0.0 — at 0.5 the card is fully faded
    expect(
      opacityWidgets.any((o) => o.opacity == 0.0),
      isTrue,
    );
  });
}
