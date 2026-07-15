import Foundation

enum SubFrequency: String {
    case daily, weekly, monthly, yearly
}

struct NextDueDateHelper {
    static func nextDueDate(startDate: Date, frequency: SubFrequency, from today: Date = Date()) -> Date {
        guard startDate > today else {
            let cal = Calendar.current
            switch frequency {
            case .daily:
                let days = cal.dateComponents([.day], from: startDate, to: today).day! + 1
                return cal.date(byAdding: .day, value: days, to: startDate)!
            case .weekly:
                let weeks = cal.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear! + 1
                return cal.date(byAdding: .weekOfYear, value: weeks, to: startDate)!
            case .monthly:
                let months = cal.dateComponents([.month], from: startDate, to: today).month! + 1
                let candidate = cal.date(byAdding: .month, value: months, to: startDate)!
                // candidate might still be <= today due to month-end clamping; advance one more if needed
                if candidate <= today {
                    return cal.date(byAdding: .month, value: 1, to: candidate)!
                }
                return candidate
            case .yearly:
                let years = cal.dateComponents([.year], from: startDate, to: today).year! + 1
                let candidate = cal.date(byAdding: .year, value: years, to: startDate)!
                if candidate <= today {
                    return cal.date(byAdding: .year, value: 1, to: candidate)!
                }
                return candidate
            }
        }
        return startDate
    }

    static func daysUntil(_ date: Date, from today: Date = Date()) -> Int {
        let cal = Calendar.current
        let fromDay = cal.startOfDay(for: today)
        let toDay = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: fromDay, to: toDay).day ?? 0
    }
}
