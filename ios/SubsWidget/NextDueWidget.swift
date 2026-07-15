import WidgetKit
import SwiftUI

struct NextDueSmallView: View {
    let entry: SubsEntry
    var body: some View {
        if let sub = entry.nextDueSub, let days = entry.daysUntilDue, let data = entry.widgetData {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(flutterARGB: sub.color))
                        .frame(width: 8, height: 8)
                    Text("Next Due")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(sub.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(data.currency)\(String(format: "%.2f", sub.amount))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(days == 0 ? "Due today" : "in \(days)d")
                    .font(.caption2)
                    .foregroundStyle(days == 0 ? .red : .secondary)
            }
            .padding()
            .widgetBackground()
        } else {
            emptyNextDue
        }
    }
}

struct NextDueMediumView: View {
    let entry: SubsEntry
    var body: some View {
        if let sub = entry.nextDueSub, let days = entry.daysUntilDue, let data = entry.widgetData {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(flutterARGB: sub.color))
                            .frame(width: 8, height: 8)
                        Text("Next Due")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(sub.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text("\(data.currency)\(String(format: "%.2f", sub.amount))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(days == 0 ? "Due today" : "in \(days) days")
                        .font(.caption2)
                        .foregroundStyle(days == 0 ? .red : .secondary)
                }
                if let second = entry.secondNextSub {
                    let secondDays = entry.sortedUpcomingSubs.dropFirst().first?.daysUntil ?? 0
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(flutterARGB: second.color))
                                .frame(width: 8, height: 8)
                            Text("Then")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(second.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text("\(data.currency)\(String(format: "%.2f", second.amount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("in \(secondDays)d")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .widgetBackground()
        } else {
            emptyNextDue
        }
    }
}

private var emptyNextDue: some View {
    VStack(spacing: 6) {
        Image(systemName: "clock")
            .font(.title3)
            .foregroundStyle(.secondary)
        Text("No subscriptions")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .widgetBackground()
}

struct NextDueEntryView: View {
    let entry: SubsEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        switch family {
        case .systemSmall: NextDueSmallView(entry: entry)
        case .systemMedium: NextDueMediumView(entry: entry)
        default: NextDueSmallView(entry: entry)
        }
    }
}

struct NextDueWidget: Widget {
    let kind = "NextDueWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubsTimelineProvider()) { entry in
            NextDueEntryView(entry: entry)
        }
        .configurationDisplayName("Next Due")
        .description("See your next upcoming subscription payment.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
