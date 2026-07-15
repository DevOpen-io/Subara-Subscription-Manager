import WidgetKit
import SwiftUI

struct UpcomingMediumView: View {
    let entry: SubsEntry
    var body: some View {
        if !entry.sortedUpcomingSubs.isEmpty {
            upcomingList(entry: entry, maxItems: 3)
        } else {
            emptyUpcoming
        }
    }
}

struct UpcomingLargeView: View {
    let entry: SubsEntry
    var body: some View {
        if !entry.sortedUpcomingSubs.isEmpty {
            upcomingList(entry: entry, maxItems: 6)
        } else {
            emptyUpcoming
        }
    }
}

private func upcomingList(entry: SubsEntry, maxItems: Int) -> some View {
    let items = entry.sortedUpcomingSubs.prefix(maxItems)
    let currency = entry.widgetData?.currency ?? "$"
    let monthlyTotal = entry.widgetData?.monthlyTotal ?? 0
    return VStack(alignment: .leading, spacing: 6) {
        Text("Upcoming")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            HStack {
                Circle()
                    .fill(Color(flutterARGB: item.sub.color))
                    .frame(width: 8, height: 8)
                Text(item.sub.name)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Text(item.daysUntil == 0 ? "Today" : "in \(item.daysUntil)d")
                    .font(.caption2)
                    .foregroundStyle(item.daysUntil == 0 ? .red : .secondary)
                Text("\(currency)\(String(format: "%.2f", item.sub.amount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        Divider()
        HStack {
            Text("Monthly Total")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(currency)\(String(format: "%.2f", monthlyTotal))")
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }
    .padding()
    .widgetBackground()
}

private var emptyUpcoming: some View {
    VStack(spacing: 6) {
        Image(systemName: "list.bullet")
            .font(.title3)
            .foregroundStyle(.secondary)
        Text("No subscriptions")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .widgetBackground()
}

struct UpcomingEntryView: View {
    let entry: SubsEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .systemMedium: UpcomingMediumView(entry: entry)
        case .systemLarge: UpcomingLargeView(entry: entry)
        default: UpcomingMediumView(entry: entry)
        }
    }
}

struct UpcomingWidget: Widget {
    let kind = "UpcomingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubsTimelineProvider()) { entry in
            UpcomingEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming")
        .description("See your upcoming subscription payments.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
