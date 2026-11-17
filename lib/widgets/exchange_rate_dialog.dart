import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/currency.dart';

/// 34.5, 0.0291, 1250 — at most [decimals] decimals (2 from 100 up),
/// without trailing zeros.
String formatRate(double rate, {int decimals = 4}) => rate
    .toStringAsFixed(rate >= 100 ? 2 : decimals)
    .replaceFirst(RegExp(r'\.?0+$'), '');

/// Result of [showExchangeRateDialog]: a new rate, or a request to remove it.
sealed class RateEdit {
  const RateEdit();
}

class RateSet extends RateEdit {
  const RateSet(this.rate);
  final double rate;
}

class RateRemoved extends RateEdit {
  const RateRemoved();
}

/// Asks "1 [from] = ? [main]". Returns null when cancelled.
Future<RateEdit?> showExchangeRateDialog(
  BuildContext context, {
  required Currency from,
  required Currency main,
  double? current,
}) => showDialog<RateEdit>(
  context: context,
  builder: (_) => _ExchangeRateDialog(from: from, main: main, current: current),
);

class _ExchangeRateDialog extends StatefulWidget {
  const _ExchangeRateDialog({
    required this.from,
    required this.main,
    this.current,
  });

  final Currency from;
  final Currency main;
  final double? current;

  @override
  State<_ExchangeRateDialog> createState() => _ExchangeRateDialogState();
}

class _ExchangeRateDialogState extends State<_ExchangeRateDialog> {
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : formatRate(widget.current!, decimals: 6),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final rate = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (rate == null || !rate.isFinite || rate <= 0) {
      setState(() => _error = 'rates.invalid'.tr());
      return;
    }
    Navigator.of(context).pop(RateSet(rate));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text('rates.title'.tr()),
      content: Material(
        type: MaterialType.transparency,
        child: Row(
          children: [
            Text(
              'rates.equals'.tr(args: [widget.from.code]),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  suffixText: widget.main.symbol,
                  errorText: _error,
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const RateRemoved()),
            child: Text('rates.remove'.tr()),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('dialogs.cancel'.tr()),
        ),
        FilledButton(onPressed: _save, child: Text('common.save'.tr())),
      ],
    );
  }
}
