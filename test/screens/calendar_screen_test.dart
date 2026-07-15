import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/screens/calendar_screen.dart';
import 'package:table_calendar/table_calendar.dart';

// Mock SubsController
class MockSubsController extends SubsController {
  @override
  Future<List<SubSlice>> build() async {
    return [
      SubSlice(
        name: 'Netflix',
        amount: 15,
        color: 0xFF000000,
        startDate: DateTime.now(),
      ),
    ];
  }
}

void main() {
  testWidgets('CalendarScreen renders and shows events', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subsControllerProvider.overrideWith(MockSubsController.new),
        ],
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );

    // Wait for async data
    await tester.pumpAndSettle();

    // Verify Calendar is present
    expect(find.byType(TableCalendar<SubSlice>), findsOneWidget);

    // Verify Subscription List shows the item (since it's today)
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('MONTHLY'), findsOneWidget);
  });
}
