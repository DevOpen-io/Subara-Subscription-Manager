import 'dart:convert';

/// A "Paid" tap on a reminder: mark `charge` of the sub `subId` as paid.
typedef MarkPaidRequest = ({String subId, DateTime charge});

/// The "Paid" button on a reminder; `label` is its localized text.
typedef MarkPaidAction = ({String subId, DateTime charge, String label});

/// Notification action id of the "Paid" button.
const markPaidActionId = 'mark_paid';

/// iOS category that carries the "Paid" button.
const markPaidCategoryId = 'mark_paid';

String encodeMarkPaid(MarkPaidRequest r) => jsonEncode({
  'sub': r.subId,
  'charge':
      '${r.charge.year.toString().padLeft(4, '0')}-'
      '${r.charge.month.toString().padLeft(2, '0')}-'
      '${r.charge.day.toString().padLeft(2, '0')}',
});

/// Null for anything that isn't a valid "Paid" payload.
MarkPaidRequest? decodeMarkPaid(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final json = jsonDecode(payload);
    if (json is! Map) return null;
    final sub = json['sub'];
    final charge = DateTime.tryParse('${json['charge']}');
    if (sub is! String || sub.isEmpty || charge == null) return null;
    return (
      subId: sub,
      charge: DateTime(charge.year, charge.month, charge.day),
    );
  } on FormatException {
    return null;
  }
}
