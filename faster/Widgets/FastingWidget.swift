import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct FastingWidgetBundle: WidgetBundle {
    var body: some Widget {
        FastingHomeWidget()
        #if canImport(ActivityKit)
        FastingLiveActivityWidget()
        #endif
    }
}

struct FastingEntry: TimelineEntry {
    let date: Date
    let start: Date?
    let end: Date?
    let phaseTitle: String
    let progress: Double

    static let placeholder = FastingEntry(
        date: Date(),
        start: Date().addingTimeInterval(-4 * 3600),
        end: Date().addingTimeInterval(12 * 3600),
        phaseTitle: "Early Fast",
        progress: 0.25
    )
}

struct FastingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        completion(.placeholder)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        // In production, read active fast from an App Group JSON file.
        let timeline = Timeline(entries: [FastingEntry.placeholder], policy: .after(Date().addingTimeInterval(600)))
        completion(timeline)
    }
}

struct FastingHomeWidget: Widget {
    let kind = "FastingHomeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingTimelineProvider()) { entry in
            FastingWidgetView(entry: entry)
        }
        .configurationDisplayName("Fasting Timer")
        .description("See your fasting progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct FastingWidgetView: View {
    var entry: FastingEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().stroke(.secondary.opacity(0.3), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 12, weight: .semibold))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(entry.phaseTitle).font(.caption.bold())
                if let end = entry.end {
                    Text(end, style: .timer).font(.title3.monospacedDigit())
                }
            }
        default:
            VStack(spacing: 6) {
                Text(entry.phaseTitle).font(.caption).foregroundStyle(.secondary)
                if let end = entry.end {
                    Text(end, style: .timer).font(.title.monospacedDigit())
                }
                ProgressView(value: entry.progress).tint(.blue)
            }
            .padding()
        }
    }
}

#if canImport(ActivityKit)
struct FastingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            VStack(alignment: .leading) {
                Text(context.state.phaseTitle).font(.caption.bold())
                Text(context.state.end, style: .timer).font(.title.monospacedDigit())
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phaseTitle).font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.end, style: .timer).monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.protocolLabel).font(.caption2)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.state.end, style: .timer).monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
#endif
