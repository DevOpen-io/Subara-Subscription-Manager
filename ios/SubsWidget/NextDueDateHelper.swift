import Foundation

enum SubFrequency: String {
    case daily, weekly, monthly, yearly
}

/// Mirrors lib/models/billing.dart and the Android NextDueDateHelper.kt:
/// charge k is start + k * interval periods, always derived from the start
/// date so month-end anchors don't drift (Jan 31 -> Feb 28 -> Mar 31), and a
/// charge due today is "next".
struct NextDueDateHelper {
    static func occurrence(
        startDate: Date,
        frequency: SubFrequency,
        k: Int,
        interval: Int = 1,
        calendar cal: Calendar = .current
    ) -> Date {
        let start = cal.startOfDay(for: startDate)
        let n = k * max(1, interval)
        switch frequency {
        case .daily:
            return cal.date(byAdding: .day, value: n, to: start)!
        case .weekly:
            return cal.date(byAdding: .day, value: 7 * n, to: start)!
        case .monthly:
            // Calendar clamps to the month's last day.
            return cal.date(byAdding: .month, value: n, to: start)!
        case .yearly:
            return cal.date(byAdding: .year, value: n, to: start)!
        }
    }

    /// First charge on or after [today]'s date.
    static func nextDueDate(
        startDate: Date,
        frequency: SubFrequency,
        from today: Date = Date(),
        interval: Int = 1,
        calendar cal: Calendar = .current
    ) -> Date {
        let start = cal.startOfDay(for: startDate)
        let day = cal.startOfDay(for: today)
        if start >= day { return start }

        // Estimate from below (in periods, then in charges), then step forward.
        let periods: Int
        switch frequency {
        case .daily:
            periods = cal.dateComponents([.day], from: start, to: day).day ?? 0
        case .weekly:
            periods = (cal.dateComponents([.day], from: start, to: day).day ?? 0) / 7
        case .monthly:
            periods = cal.dateComponents([.month], from: start, to: day).month ?? 0
        case .yearly:
            periods = cal.dateComponents([.year], from: start, to: day).year ?? 0
        }
        var k = max(0, (periods - 1) / max(1, interval))
        while occurrence(startDate: start, frequency: frequency, k: k, interval: interval, calendar: cal) < day {
            k += 1
        }
        return occurrence(startDate: start, frequency: frequency, k: k, interval: interval, calendar: cal)
    }

    static func daysUntil(_ date: Date, from today: Date = Date()) -> Int {
        let cal = Calendar.current
        let fromDay = cal.startOfDay(for: today)
        let toDay = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: fromDay, to: toDay).day ?? 0
    }
}
