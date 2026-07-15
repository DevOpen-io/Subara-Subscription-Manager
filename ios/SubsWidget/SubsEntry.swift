import WidgetKit
import Foundation

struct SubsEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData?
    // Pre-computed for this specific day
    let nextDueSub: WidgetSubEntry?
    let nextDueDate: Date?
    let daysUntilDue: Int?
    let secondNextSub: WidgetSubEntry?
    let secondNextDate: Date?
    // Sorted upcoming subs with due dates and days until
    let sortedUpcomingSubs: [(sub: WidgetSubEntry, dueDate: Date, daysUntil: Int)]
}
