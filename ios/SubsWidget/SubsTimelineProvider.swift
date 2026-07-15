import WidgetKit
import Foundation

struct SubsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SubsEntry {
        makeEntry(for: Date(), widgetData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SubsEntry) -> Void) {
        let data = SubsDataReader.read()
        completion(makeEntry(for: Date(), widgetData: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubsEntry>) -> Void) {
        let data = SubsDataReader.read()
        var entries: [SubsEntry] = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for dayOffset in 0..<30 {
            let day = cal.date(byAdding: .day, value: dayOffset, to: today)!
            entries.append(makeEntry(for: day, widgetData: data))
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func parseDate(_ string: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let d = f.date(from: string) { return d }
        // Fallback for strings that include a timezone designator
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: string)
    }

    private func makeEntry(for day: Date, widgetData: WidgetData?) -> SubsEntry {
        guard let data = widgetData, !data.subs.isEmpty else {
            return SubsEntry(
                date: day,
                widgetData: nil,
                nextDueSub: nil,
                nextDueDate: nil,
                daysUntilDue: nil,
                secondNextSub: nil,
                secondNextDate: nil,
                sortedUpcomingSubs: []
            )
        }

        // Compute next due dates for all subs as of this day
        let subsWithDates: [(WidgetSubEntry, Date)] = data.subs.compactMap { sub in
            guard let freq = SubFrequency(rawValue: sub.frequency),
                  let start = parseDate(sub.startDate) else { return nil }
            let nextDate = NextDueDateHelper.nextDueDate(startDate: start, frequency: freq, from: day)
            return (sub, nextDate)
        }.sorted { $0.1 < $1.1 }

        let first = subsWithDates.first
        let second = subsWithDates.dropFirst().first

        let sortedUpcoming = subsWithDates.map { (sub, dueDate) in
            (sub: sub, dueDate: dueDate, daysUntil: NextDueDateHelper.daysUntil(dueDate, from: day))
        }

        return SubsEntry(
            date: day,
            widgetData: data,
            nextDueSub: first?.0,
            nextDueDate: first?.1,
            daysUntilDue: first.map { NextDueDateHelper.daysUntil($0.1, from: day) },
            secondNextSub: second?.0,
            secondNextDate: second?.1,
            sortedUpcomingSubs: sortedUpcoming
        )
    }
}
