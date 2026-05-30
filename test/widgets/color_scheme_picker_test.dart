import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/utils/app_theme.dart';
import 'package:subs_tracker/widgets/color_scheme_picker.dart';

void main() {
  group('ColorSchemePicker', () {
    testWidgets('renders 16 dots', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorSchemePicker(
              selectedScheme: FlexScheme.bahamaBlue,
              onSchemeSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(ColorSchemeDot), findsNWidgets(16));
    });

    testWidgets('selected dot shows check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorSchemePicker(
              selectedScheme: FlexScheme.indigo,
              onSchemeSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tapping a dot calls onSchemeSelected with correct scheme', (tester) async {
      FlexScheme? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorSchemePicker(
              selectedScheme: FlexScheme.bahamaBlue,
              onSchemeSelected: (s) => selected = s,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ColorSchemeDot).at(2));
      expect(selected, kCuratedSchemes[2].$1);
    });
  });
}
