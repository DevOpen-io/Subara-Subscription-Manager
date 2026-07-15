import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/sub_slice.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.borderRadius = 8,
  });

  final SubStatus status;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        'detail.status_${status.name}'.tr(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusColor(status),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

Color statusColor(SubStatus status) {
  switch (status) {
    case SubStatus.active:
      return Colors.green;
    case SubStatus.freeTrial:
      return Colors.amber;
    case SubStatus.paused:
      return Colors.grey;
    case SubStatus.cancelled:
      return Colors.red;
  }
}

void showStatusPicker(
  BuildContext context,
  SubStatus current,
  ValueChanged<SubStatus> onSelected,
) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'detail.status'.tr(),
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...SubStatus.values.map(
            (status) => ListTile(
              title: Text('detail.status_${status.name}'.tr()),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              trailing: status == current
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.of(ctx).pop();
                onSelected(status);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
