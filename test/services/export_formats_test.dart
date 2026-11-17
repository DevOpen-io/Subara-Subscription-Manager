import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/services/export_formats.dart';

SubSlice _sub(
  String name, {
  DateTime? start,
  Frequency f = Frequency.monthly,
  int interval = 1,
  SubStatus status = SubStatus.active,
  Currency? currency,
  String? note,
  double amount = 10,
}) => SubSlice(
  id: name,
  name: name,
  amount: amount,
  color: 0,
  startDate: start ?? DateTime(2026, 1, 15),
  frequency: f,
  interval: interval,
  status: status,
  currency: currency,
  note: note,
);

const _settings = SettingsViewModel(
  theme: ThemeMode.light,
  currency: Currency.try_,
  exchangeRates: {Currency.usd: 30},
);

void main() {
  final now = DateTime(2026, 11, 17);

  group('CSV', () {
    test('header and one row per subscription', () {
      final csv = subsToCsv(
        [
          _sub('Netflix'),
          _sub(
            'Spotify',
            currency: Currency.usd,
            f: Frequency.weekly,
            interval: 2,
          ),
          _sub('Old', status: SubStatus.cancelled, currency: Currency.eur),
        ],
        _settings,
        now,
      );
      final lines = csv.trim().split('\r\n');
      expect(
        lines.first,
        'name,amount,currency,frequency,interval,status,start_date,next_charge,shared_with,my_monthly_in_main_currency,category,note',
      );
      expect(
        lines[1],
        'Netflix,10.00,TRY,monthly,1,active,2026-01-15,2026-12-15,1,10.00,,',
      );
      expect(
        lines[2],
        startsWith('Spotify,10.00,USD,weekly,2,active,2026-01-15,'),
      );
      expect(lines[2], contains(',1,651.79,')); // 10/14 days * 365/12 * 30
      // Cancelled: no next charge; EUR has no rate so no converted amount.
      expect(lines[3], 'Old,10.00,EUR,monthly,1,cancelled,2026-01-15,,1,,,');
    });

    test('escapes commas, quotes and newlines', () {
      final csv = subsToCsv([_sub('A, "B"', note: 'x\ny')], _settings, now);
      expect(csv, contains('"A, ""B"""'));
      expect(csv, contains('"x\ny"'));
    });

    test('neutralises spreadsheet formulas', () {
      final csv = subsToCsv(
        [_sub('=HYPERLINK("http://x")', note: '+1'), _sub('@cmd'), _sub('-2')],
        _settings,
        now,
      );
      expect(csv, contains('"\'=HYPERLINK(""http://x"")"'));
      expect(csv, contains("'+1"));
      expect(csv, contains("'@cmd"));
      expect(csv, contains("'-2"));
    });
  });

  group('iCalendar', () {
    String ics(List<SubSlice> subs) => subsToIcs(subs, now);

    test('one recurring all-day event per active subscription', () {
      final out = ics([
        _sub('Netflix'),
        _sub('Paused', status: SubStatus.paused),
        _sub('Gone', status: SubStatus.cancelled),
      ]);
      expect(out, startsWith('BEGIN:VCALENDAR\r\n'));
      expect(out.trim(), endsWith('END:VCALENDAR'));
      expect('BEGIN:VEVENT'.allMatches(out), hasLength(1));
      expect(out, contains('DTSTART;VALUE=DATE:20260115\r\n'));
      expect(out, contains('RRULE:FREQ=MONTHLY;INTERVAL=1\r\n'));
      expect(out, contains('SUMMARY:Netflix\r\n'));
      expect(out, contains('UID:Netflix@subara\r\n'));
    });

    test('month-end starts clamp to the last day like the app', () {
      expect(
        ics([_sub('A', start: DateTime(2026, 1, 31))]),
        contains(
          'RRULE:FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=28,29,30,31;BYSETPOS=-1\r\n',
        ),
      );
      expect(
        ics([_sub('B', start: DateTime(2026, 1, 29), interval: 3)]),
        contains(
          'RRULE:FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=28,29;BYSETPOS=-1\r\n',
        ),
      );
      expect(
        ics([_sub('C', start: DateTime(2024, 2, 29), f: Frequency.yearly)]),
        contains(
          'RRULE:FREQ=YEARLY;INTERVAL=1;BYMONTH=2;BYMONTHDAY=28,29;BYSETPOS=-1\r\n',
        ),
      );
      expect(
        ics([_sub('D', f: Frequency.weekly, interval: 2)]),
        contains('RRULE:FREQ=WEEKLY;INTERVAL=2\r\n'),
      );
    });

    test('escapes text values', () {
      expect(
        ics([_sub('A;B,C', note: 'line1\nline2')]),
        allOf(
          contains(r'SUMMARY:A\;B\,C'),
          contains(r'DESCRIPTION:line1\nline2'),
        ),
      );
    });
  });
}
