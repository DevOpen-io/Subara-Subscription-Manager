import WidgetKit
import SwiftUI

// MARK: - Small View
struct MonthlySpendSmallView: View {
    let entry: SubsEntry
    var body: some View {
        if let data = entry.widgetData, !data.subs.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("This Month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(data.currency)\(String(format: "%.2f", data.monthlyTotal))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.7)
                Text("\(data.subs.count) subscriptions")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .widgetBackground()
        } else {
            emptyState
        }
    }
}

// MARK: - Medium View
struct MonthlySpendMediumView: View {
    let entry: SubsEntry
    var body: some View {
        if let data = entry.widgetData, !data.subs.isEmpty {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(data.currency)\(String(format: "%.2f", data.monthlyTotal))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.7)
                    Text("\(data.subs.count) subs")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(data.subs.sorted { $0.monthlyAmount > $1.monthlyAmount }.prefix(2), id: \.name) { sub in
                        HStack {
                            Circle()
                                .fill(Color(flutterARGB: sub.color))
                                .frame(width: 8, height: 8)
                            Text(sub.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(data.currency)\(String(format: "%.2f", sub.monthlyAmount))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .widgetBackground()
        } else {
            emptyState
        }
    }
}

private var emptyState: some View {
    VStack(spacing: 6) {
        Image(systemName: "creditcard")
            .font(.title3)
            .foregroundStyle(.secondary)
        Text("Add a subscription")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .widgetBackground()
}

// MARK: - Entry View (dispatches by size)
struct MonthlySpendEntryView: View {
    let entry: SubsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: MonthlySpendSmallView(entry: entry)
        case .systemMedium: MonthlySpendMediumView(entry: entry)
        default: MonthlySpendSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct MonthlySpendWidget: Widget {
    let kind = "MonthlySpendWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubsTimelineProvider()) { entry in
            MonthlySpendEntryView(entry: entry)
        }
        .configurationDisplayName("Monthly Spend")
        .description("See your total monthly subscription cost.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
