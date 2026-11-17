import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subs_tracker/models/money.dart';
import 'package:subs_tracker/models/settings_view_model.dart';
import 'package:subs_tracker/models/sub_slice.dart';

SubSlice _sub(String name, double amount, [Currency? currency]) => SubSlice(
  id: name,
  name: name,
  amount: amount,
  color: 0,
  startDate: DateTime(2026),
  currency: currency,
);

SettingsViewModel _settings(Map<Currency, double> rates) => SettingsViewModel(
  theme: ThemeMode.light,
  currency: Currency.try_,
  exchangeRates: rates,
);

void main() {
  test('subs without a currency use the main currency', () {
    final s = _settings({});
    expect(s.currencyOf(_sub('a', 10)), Currency.try_);
    expect(s.toMain(10, Currency.try_), 10);
  });

  test('converts with the user-entered rate', () {
    final s = _settings({Currency.usd: 34.5});
    expect(s.toMain(10, Currency.usd), closeTo(345, 1e-9));
    expect(s.toMain(10, Currency.eur), isNull);
  });

  test('display codes hide the storage name', () {
    expect(Currency.try_.code, 'TRY');
    expect(Currency.usd.code, 'USD');
  });

  test('typed rate accessors', () {
    final s = _settings({Currency.usd: 30});
    expect(s.rateFor(Currency.usd), 30);
    expect(s.rateFor(Currency.eur), isNull);
    expect(s.hasRate(Currency.try_), isTrue); // main
    expect(s.hasRate(Currency.usd), isTrue);
    expect(s.hasRate(Currency.eur), isFalse);
    expect(s.rateCount, 1);
  });

  test('inMain converts amounts and leaves out subs without a rate', () {
    final s = _settings({Currency.usd: 30});
    final r = s.inMain([
      _sub('tl', 100),
      _sub('usd', 10, Currency.usd),
      _sub('eur', 5, Currency.eur),
      _sub('explicit-main', 7, Currency.try_),
    ]);
    expect(r.subs.map((x) => (x.name, x.amount)), [
      ('tl', 100.0),
      ('usd', 300.0),
      ('explicit-main', 7.0),
    ]);
    expect(r.subs.every((x) => x.currency == null), isTrue);
    expect(r.missing, [Currency.eur]);
  });

  test('changing the main currency rebases known rates', () {
    // 1 USD = 30 TRY, 1 EUR = 33 TRY. New main USD.
    final rebased = rebaseRates(
      {Currency.usd: 30, Currency.eur: 33},
      from: Currency.try_,
      to: Currency.usd,
    );
    expect(rebased[Currency.usd], isNull);
    expect(rebased[Currency.try_], closeTo(1 / 30, 1e-12));
    expect(rebased[Currency.eur], closeTo(1.1, 1e-12));
  });

  test('changing to a currency without a rate drops the old rates', () {
    final rebased = rebaseRates(
      {Currency.usd: 30},
      from: Currency.try_,
      to: Currency.eur,
    );
    expect(rebased, isEmpty);
  });

  group('ExchangeRatesConverter', () {
    const c = ExchangeRatesConverter();

    test('round-trips by currency name', () {
      final json = c.toJson({Currency.usd: 30, Currency.eur: 33.5});
      expect(json, {'usd': 30.0, 'eur': 33.5});
      expect(c.fromJson(json), {Currency.usd: 30.0, Currency.eur: 33.5});
    });

    test('drops unknown currencies and invalid values instead of failing', () {
      expect(
        c.fromJson({
          'usd': 30,
          'xyz': 2,
          'eur': 'abc',
          'gbp': -1,
          'jpy': 0,
          'cad': null,
        }),
        {Currency.usd: 30.0},
      );
      expect(c.fromJson('garbage'), isEmpty);
      expect(c.fromJson(null), isEmpty);
    });
  });

  test('settings JSON without rates (1.0.0) decodes with none', () {
    final s = SettingsViewModel.fromJson({
      'theme': 'light',
      'currency': 'try_',
      'isFirstTime': false,
    });
    expect(s.exchangeRates, isEmpty);
  });

  test('a sub with an unknown currency code falls back to main', () {
    final json = _sub('a', 1).toJson()..['currency'] = 'xyz';
    expect(SubSlice.fromJson(json).currency, isNull);
  });

  group('shared subscriptions', () {
    test('totals use your share', () {
      final s = _settings({Currency.usd: 30});
      final r = s.inMain([
        _sub('family', 40).copyWith(sharedWith: 4),
        _sub('usd', 10, Currency.usd).copyWith(sharedWith: 2),
      ]);
      expect(r.subs.map((x) => x.amount), [10.0, 150.0]);
    });

    test('invalid people counts act as 1', () {
      expect(_sub('a', 10).copyWith(sharedWith: 0).people, 1);
      expect(_sub('a', 10).copyWith(sharedWith: -3).people, 1);
      expect(
        _sub('a', 10).copyWith(sharedWith: 1000).people,
        SubSlice.maxPeople,
      );
      expect(
        _sub('a', 10).copyWith(sharedWith: 3).myAmount,
        closeTo(10 / 3, 1e-9),
      );
    });
  });

  group('budget', () {
    test('legacy settings have no budget', () {
      final s = SettingsViewModel.fromJson({
        'theme': 'light',
        'currency': 'try_',
      });
      expect(s.monthlyBudget, isNull);
    });

    test('invalid stored budget is ignored', () {
      final s = SettingsViewModel.fromJson({
        'theme': 'light',
        'currency': 'try_',
        'monthlyBudget': 'abc',
      });
      expect(s.monthlyBudget, isNull);
      final neg = SettingsViewModel.fromJson({
        'theme': 'light',
        'currency': 'try_',
        'monthlyBudget': -5,
      });
      expect(neg.monthlyBudget, isNull);
    });

    test('budget progress', () {
      final s = _settings({}).copyWith(monthlyBudget: 100);
      expect(s.budgetUsage(80), closeTo(0.8, 1e-9));
      expect(s.budgetUsage(120), closeTo(1.2, 1e-9));
      expect(_settings({}).budgetUsage(80), isNull);
    });
  });
}
