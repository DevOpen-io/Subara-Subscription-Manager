import 'settings_view_model.dart';
import 'sub_slice.dart';

extension SettingsMoney on SettingsViewModel {
  /// The currency a subscription is billed in (main currency if unset).
  Currency currencyOf(SubSlice sub) => sub.currency ?? currency;

  /// User-entered rate of [c] in the main currency, if any.
  double? rateFor(Currency c) => exchangeRates[c];

  bool hasRate(Currency c) => c == currency || exchangeRates.containsKey(c);

  int get rateCount => exchangeRates.length;

  /// [amount] in [from], converted to the main currency, or null when the
  /// user hasn't entered a rate for [from].
  double? toMain(double amount, Currency from) {
    if (from == currency) return amount;
    final rate = exchangeRates[from];
    return rate == null ? null : amount * rate;
  }

  /// Spending relative to [monthlyBudget] (1.0 = exactly on budget), or
  /// null without a budget.
  double? budgetUsage(double monthlyTotal) {
    final budget = monthlyBudget;
    return budget == null ? null : monthlyTotal / budget;
  }

  /// Copies of [subs] with your share of each amount, converted to the main
  /// currency, for totals, sorting, charts and the home widget. Subs whose currency has no
  /// rate are left out and their currencies listed in `missing`.
  ({List<SubSlice> subs, List<Currency> missing}) inMain(
    Iterable<SubSlice> subs,
  ) {
    final converted = <SubSlice>[];
    final missing = <Currency>{};
    for (final s in subs) {
      final from = currencyOf(s);
      // Your share of a cost split between several people.
      final amount = toMain(s.myAmount, from);
      if (amount == null) {
        missing.add(from);
      } else {
        converted.add(
          s.copyWith(amount: amount, currency: null, sharedWith: 1),
        );
      }
    }
    return (subs: converted, missing: missing.toList());
  }
}

/// Re-expresses [rates] (relative to [from]) relative to [to]. Needs the
/// rate of [to]; without it the old rates are meaningless and are dropped.
Map<Currency, double> rebaseRates(
  Map<Currency, double> rates, {
  required Currency from,
  required Currency to,
}) {
  if (from == to) return rates;
  final pivot = rates[to];
  if (pivot == null) return {};
  return {
    for (final MapEntry(:key, :value) in rates.entries)
      if (key != to) key: value / pivot,
    from: 1 / pivot,
  };
}
