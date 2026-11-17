import '../models/sub_slice.dart';

/// Subscriptions paid the same way, with their summed monthly amount.
typedef PaymentGroup = ({
  String? method,
  String? card,
  double monthly,
  int count,
});

String? _clean(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// Groups [subs] (already converted to one currency) by payment method and
/// card, ignoring case and spacing in the method name; biggest first.
List<PaymentGroup> groupByPaymentMethod(List<SubSlice> subs) {
  final groups = <String, PaymentGroup>{};
  for (final s in subs) {
    final method = _clean(s.paymentMethod);
    final card = _clean(s.cardLastFour);
    final key = '${method?.toLowerCase()}|$card';
    final g = groups[key];
    groups[key] = (
      method: g?.method ?? method,
      card: card,
      monthly: (g?.monthly ?? 0) + s.monthlyAmount,
      count: (g?.count ?? 0) + 1,
    );
  }
  return groups.values.toList()..sort((a, b) => b.monthly.compareTo(a.monthly));
}

/// "Visa •••• 1234", "•••• 1234", "PayPal", or [notSet].
String paymentLabel(String? method, String? card, {required String notSet}) {
  final m = _clean(method);
  final c = _clean(card);
  if (m == null && c == null) return notSet;
  return [?m, if (c != null) '•••• $c'].join(' ');
}
