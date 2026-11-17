import 'package:freezed_annotation/freezed_annotation.dart';

enum Currency {
  try_('₺', 'Turkish Lira'),
  usd(r'$', 'US Dollar'),
  eur('€', 'Euro'),
  gbp('£', 'British Pound'),
  jpy('¥', 'Japanese Yen'),
  cad(r'C$', 'Canadian Dollar'),
  aud(r'A$', 'Australian Dollar');

  const Currency(this.symbol, this.label);

  final String symbol;
  final String label;

  /// ISO-style code for display ("TRY", "USD"); [name] is the stored key.
  String get code => name.replaceAll('_', '').toUpperCase();
}

/// Stores rates by currency name. Decoding never throws: unknown currencies
/// and non-positive or non-numeric rates are dropped, so a bad entry can't
/// make the whole settings row undecodable (which would reset settings).
class ExchangeRatesConverter
    implements JsonConverter<Map<Currency, double>, Object?> {
  const ExchangeRatesConverter();

  @override
  Map<Currency, double> fromJson(Object? json) {
    if (json is! Map) return {};
    final rates = <Currency, double>{};
    for (final MapEntry(:key, :value) in json.entries) {
      final currency = Currency.values.where((c) => c.name == key).firstOrNull;
      if (currency == null || value is! num) continue;
      final rate = value.toDouble();
      if (rate.isFinite && rate > 0) rates[currency] = rate;
    }
    return rates;
  }

  @override
  Map<String, double> toJson(Map<Currency, double> rates) => {
    for (final MapEntry(:key, :value) in rates.entries) key.name: value,
  };
}
