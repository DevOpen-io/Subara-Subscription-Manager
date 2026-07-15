import ActivityKit
import SwiftUI
import WidgetKit

struct SubsDueWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SubsDueAttributes.self) { context in
            // Lock screen / expanded notification banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view (user long-presses island)
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                compactLeading(context: context)
            } compactTrailing: {
                compactTrailing(context: context)
            } minimal: {
                minimal(context: context)
            }
        }
    }

    // MARK: - Lock Screen View
    private func lockScreenView(context: ActivityViewContext<SubsDueAttributes>) -> some View {
        let subs = context.state.dueSubs
        return HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(subs.count == 1 ? "Subscription due today" : "\(subs.count) subscriptions due today")
                    .font(.caption)
                    .fontWeight(.semibold)
                ForEach(subs.prefix(3), id: \.name) { sub in
                    Text("\(sub.name) — \(sub.currency)\(String(format: "%.2f", sub.amount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Compact
    private func compactLeading(context: ActivityViewContext<SubsDueAttributes>) -> some View {
        let first = context.state.dueSubs.first
        return HStack(spacing: 4) {
            if let sub = first {
                Circle()
                    .fill(Color(flutterARGB: sub.color))
                    .frame(width: 8, height: 8)
                Text(sub.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
    }

    private func compactTrailing(context: ActivityViewContext<SubsDueAttributes>) -> some View {
        let first = context.state.dueSubs.first
        return Group {
            if let sub = first {
                Text("\(sub.currency)\(String(format: "%.2f", sub.amount))")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Minimal
    private func minimal(context: ActivityViewContext<SubsDueAttributes>) -> some View {
        let first = context.state.dueSubs.first
        return Group {
            if let sub = first {
                Circle()
                    .fill(Color(flutterARGB: sub.color))
                    .frame(width: 10, height: 10)
            } else {
                Image(systemName: "creditcard")
                    .font(.caption2)
            }
        }
    }

    // MARK: - Expanded
    private func expandedLeading(context: ActivityViewContext<SubsDueAttributes>) -> some View {
        Image(systemName: "creditcard.fill")
            .font(.title3)
    }

    private func expandedTrailing(context: ActivityViewContext<SubsDueAttributes>) -> some View {
        Text("\(context.state.dueSubs.count) due")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func expandedBottom(context: ActivityViewContext<SubsDueAttributes>) -> some View {
        let subs = context.state.dueSubs
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(subs.prefix(3), id: \.name) { sub in
                HStack {
                    Circle()
                        .fill(Color(flutterARGB: sub.color))
                        .frame(width: 8, height: 8)
                    Text(sub.name)
                        .font(.caption)
                    Spacer()
                    Text("\(sub.currency)\(String(format: "%.2f", sub.amount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}
