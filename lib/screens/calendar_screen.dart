import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/billing.dart';
import '../models/money.dart';
import '../models/sub_slice.dart';
import '../providers/settings_controller.dart';
import '../providers/subs_controller.dart';
import '../utils/billing_labels.dart';
import '../widgets/brand_logo.dart';
import '../widgets/sub_zilla_app_bar.dart';

class CalendarScreen extends HookConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subsControllerProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final focusedDay = useState(DateTime.now());
    final selectedDay = useState<DateTime?>(DateTime.now());

    // Paused and cancelled subscriptions aren't charged.
    List<SubSlice> getEventsForDay(DateTime day, List<SubSlice> subs) => subs
        .where(
          (sub) =>
              sub.status != SubStatus.paused &&
              sub.status != SubStatus.cancelled &&
              sub.isDueOn(day),
        )
        .toList();

    return Scaffold(
      appBar: const SubaraAppBar(),
      body: subsAsync.when(
        data: (subs) {
          final selectedEvents = selectedDay.value == null
              ? <SubSlice>[]
              : getEventsForDay(selectedDay.value!, subs);

          return Column(
            children: [
              TableCalendar<SubSlice>(
                locale: context.locale.toString(),
                firstDay: DateTime.utc(2020),
                // Relative, so the calendar never runs past its last day.
                lastDay: DateTime.utc(DateTime.now().year + 10, 12, 31),
                focusedDay: focusedDay.value,
                selectedDayPredicate: (day) =>
                    isSameDay(selectedDay.value, day),
                onDaySelected: (selected, focused) {
                  selectedDay.value = selected;
                  focusedDay.value = focused;
                },
                eventLoader: (day) => getEventsForDay(day, subs),
                calendarBuilders: CalendarBuilders<SubSlice>(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(4).map((sub) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: Color(sub.color),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  cellMargin: const EdgeInsets.all(8),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final sub = selectedEvents[index];
                    return ListTile(
                      leading: sub.brand != null
                          ? BrandLogo(brand: sub.brand)
                          : CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(sub.color),
                              child: Text(sub.name[0].toUpperCase()),
                            ),
                      title: Text(sub.name),
                      subtitle: Text(
                        '${settings?.currencyOf(sub).symbol ?? ''}${sub.amount.toStringAsFixed(2)}',
                      ),
                      trailing: Text(sub.cycleLabel),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
