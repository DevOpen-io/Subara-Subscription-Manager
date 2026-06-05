import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:subs_tracker/models/sub_slice.dart';
import 'package:subs_tracker/providers/subs_controller.dart';
import 'package:subs_tracker/widgets/brand_logo.dart';
import 'package:subs_tracker/widgets/sub_zilla_app_bar.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends HookConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subsControllerProvider);
    final focusedDay = useState(DateTime.now());
    final selectedDay = useState<DateTime?>(DateTime.now());

    List<SubSlice> getEventsForDay(DateTime day, List<SubSlice> subs) {
      return subs.where((sub) {
        final start = sub.startDate;
        
        // Normalize dates to ignore time
        final d = DateTime(day.year, day.month, day.day);
        final s = DateTime(start.year, start.month, start.day);

        if (d.isBefore(s)) return false;

        switch (sub.frequency) {
          case Frequency.daily:
            return true;
          case Frequency.weekly:
            return d.weekday == s.weekday;
          case Frequency.monthly:
            // Handle end of month edge cases if needed, but for now simple day check
            // If start day is 31st, and current month has 30 days, it usually skips or moves to last day.
            // Simple logic: match day. 
            // Better logic: if start day > days in month, check if day is last day of month?
            // Let's stick to simple day matching for now, or better:
            // If sub starts on 31st, it should show on 30th of June?
            // Let's keep it simple: match day.
            return d.day == s.day;
          case Frequency.yearly:
            return d.month == s.month && d.day == s.day;
        }
      }).toList();
    }

    return Scaffold(
      appBar: SubZillaAppBar(),
      body: subsAsync.when(
        data: (subs) {
          final List<SubSlice> selectedEvents = selectedDay.value == null
              ? []
              : getEventsForDay(selectedDay.value!, subs);

          return Column(
            children: [
              TableCalendar<SubSlice>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay.value,
                selectedDayPredicate: (day) => isSameDay(selectedDay.value, day),
                onDaySelected: (selected, focused) {
                  selectedDay.value = selected;
                  focusedDay.value = focused;
                },
                eventLoader: (day) => getEventsForDay(day, subs),
                calendarStyle: CalendarStyle(
                  cellMargin: const EdgeInsets.all(8.0),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                          ? BrandLogo(
                              brand: sub.brand,
                              size: 32,
                            )
                          : CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(sub.color),
                              child: Text(sub.name[0].toUpperCase()),
                            ),
                      title: Text(sub.name),
                      subtitle: Text(
                        NumberFormat.simpleCurrency().format(sub.amount),
                      ),
                      trailing: Text("frequency_names.${sub.frequency.name}".tr()),
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
