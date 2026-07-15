import Foundation

struct WidgetSubEntry: Decodable {
    let name: String
    let amount: Double
    let monthlyAmount: Double
    let startDate: String  // ISO 8601
    let frequency: String  // "daily" | "weekly" | "monthly" | "yearly"
    let color: Int
}

struct WidgetData: Decodable {
    let subs: [WidgetSubEntry]
    let currency: String
    let monthlyTotal: Double
}
