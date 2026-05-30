import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/widgets/floating_sub_card.dart';

void main() {
  testWidgets('FloatingSubCard renders name and amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FloatingSubCard(
            name: 'Netflix',
            amount: '£8.99',
            label: 'Renews\nsoon',
            cardColor: Color(0xFF1B1B1B),
            textColor: Colors.white,
            logoColor: Color(0xFFE50914),
            logoInitials: 'N',
          ),
        ),
      ),
    );
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('£8.99'), findsOneWidget);
  });

  testWidgets('FloatingSubCard applies rotation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FloatingSubCard(
            name: 'Spotify',
            amount: '£16.99',
            label: 'Renews\nsoon',
            cardColor: Colors.white,
            textColor: Color(0xFF1B1B1B),
            logoColor: Color(0xFF1DB954),
            logoInitials: 'S',
            rotation: 0.15,
          ),
        ),
      ),
    );
    expect(find.byType(Transform), findsAtLeastNWidgets(1));
  });
}
