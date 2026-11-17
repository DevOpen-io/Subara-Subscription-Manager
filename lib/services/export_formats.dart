import 'dart:convert';

import '../models/billing.dart';
import '../models/money.dart';
import '../models/settings_view_model.dart';
import '../models/sub_slice.dart';

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

bool _charges(SubSlice s) =>
    s.status != SubStatus.paused && s.status != SubStatus.cancelled;

// ---------------------------------------------------------------------------
// CSV (RFC 4180) for spreadsheets and budgeting tools.
// ---------------------------------------------------------------------------

const _csvHeader = [
  'name',
  'amount',
  'currency',
  'frequency',
  'interval',
  'status',
  'start_date',
  'next_charge',
  'shared_with',
  'my_monthly_in_main_currency',
  'category',
  'note',
];

/// Every subscription as a CSV row. `my_monthly_in_main_currency` is your
/// share, empty when there is no exchange rate for the subscription's
/// currency.
String subsToCsv(
  List<SubSlice> subs,
  SettingsViewModel settings,
  DateTime now,
) {
  final rows = <List<String>>[
    _csvHeader,
    for (final s in subs)
      [
        s.name,
        s.amount.toStringAsFixed(2),
        settings.currencyOf(s).code,
        s.frequency.name,
        '${s.period}',
        s.status.name,
        _date(s.startDate),
        if (_charges(s)) _date(s.nextChargeDate(now)) else '',
        '${s.people}',
        settings
                .toMain(s.monthlyAmount / s.people, settings.currencyOf(s))
                ?.toStringAsFixed(2) ??
            '',
        s.category ?? s.brand?.category ?? '',
        s.note ?? '',
      ],
  ];
  return '${rows.map((r) => r.map(_csvField).join(',')).join('\r\n')}\r\n';
}

String _csvField(String value) {
  // A leading = + - @ makes spreadsheets run the cell as a formula.
  final safe = RegExp(r'^[=+\-@\t\r]').hasMatch(value) ? "'$value" : value;
  return RegExp('[",\r\n]').hasMatch(safe)
      ? '"${safe.replaceAll('"', '""')}"'
      : safe;
}

// ---------------------------------------------------------------------------
// iCalendar (RFC 5545): one recurring all-day event per charging
// subscription, for importing into any calendar app.
// ---------------------------------------------------------------------------

String subsToIcs(List<SubSlice> subs, DateTime now) {
  final stamp = now.toUtc();
  final dtStamp =
      '${_date(stamp).replaceAll('-', '')}T'
      '${stamp.hour.toString().padLeft(2, '0')}'
      '${stamp.minute.toString().padLeft(2, '0')}'
      '${stamp.second.toString().padLeft(2, '0')}Z';
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Subara//Subscriptions//EN',
    'CALSCALE:GREGORIAN',
    for (final s in subs.where(_charges)) ...[
      'BEGIN:VEVENT',
      'UID:${s.id.isEmpty ? s.name : s.id}@subara',
      'DTSTAMP:$dtStamp',
      'DTSTART;VALUE=DATE:${_date(s.startDate).replaceAll('-', '')}',
      'RRULE:${_rrule(s)}',
      'SUMMARY:${_icsText(s.name)}',
      if (s.note != null) 'DESCRIPTION:${_icsText(s.note!)}',
      'TRANSP:TRANSPARENT',
      'END:VEVENT',
    ],
    'END:VCALENDAR',
  ];
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// Matches billing.dart: a start on the 29th–31st (or Feb 29) falls on the
/// last day of shorter months instead of skipping them.
String _rrule(SubSlice s) {
  final base = 'FREQ=${s.frequency.name.toUpperCase()};INTERVAL=${s.period}';
  final day = s.startDate.day;
  String lastDayUpTo(int d) =>
      'BYMONTHDAY=${[for (var i = 28; i <= d; i++) i].join(',')};BYSETPOS=-1';
  return switch (s.frequency) {
    Frequency.monthly when day > 28 => '$base;${lastDayUpTo(day)}',
    Frequency.yearly when s.startDate.month == 2 && day == 29 =>
      '$base;BYMONTH=2;${lastDayUpTo(29)}',
    _ => base,
  };
}

String _icsText(String v) => v
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll(RegExp('\r?\n'), r'\n');

/// Folds lines longer than 75 octets (continuation lines start with a space).
String _fold(String line) {
  final bytes = utf8.encode(line);
  if (bytes.length <= 75) return line;
  final out = StringBuffer();
  var count = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    final len = utf8.encode(ch).length;
    if (count + len > 75) {
      out.write('\r\n ');
      count = 1;
    }
    out.write(ch);
    count += len;
  }
  return out.toString();
}
