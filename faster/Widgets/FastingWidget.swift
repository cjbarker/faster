import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Shared App Group keys (must match FastingController.SharedKey)

private enum SharedKey {
    static let suite    = "group.com.faster.app"
    static let start    = "fastStart"
    static let end      = "fastEnd"
    static let protocol_ = "fastProtocol"
}

// MARK: - Timeline entry

struct FastingEntry: TimelineEntry {
    let date: Date
    let start: Date?
    let end: Date?
    let phaseTitle: String
    let progress: Double
    let protocolLabel: String

    static let placeholder = FastingEntry(
        date: Date(),
        start: Date().addingTimeInterval(-4 * 3600),
        end:   Date().addingTimeInterval(12 * 3600),
        phaseTitle: "Early Fast",
        progress: 0.25,
        protocolLabel: "16:8"
    )

    static let empty = FastingEntry(
        date: Date(),
        start: nil,
        end: nil,
        phaseTitle: "Not fasting",
        progress: 0,
        protocolLabel: ""
    )
}

// MARK: - Timeline provider

struct FastingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        completion(context.isPreview ? .placeholder : makeCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: SharedKey.suite)
        let start    = defaults?.object(forKey: SharedKey.start)     as? Date
        let end      = defaults?.object(forKey: SharedKey.end)       as? Date
        let label    = defaults?.string(forKey: SharedKey.protocol_) ?? ""
        let now      = Date()

        guard let start, let end, end > now else {
            // No active fast — poll every 10 min in case the user starts one
            let entry = FastingEntry(date: now, start: nil, end: nil,
                                     phaseTitle: "Not fasting", progress: 0,
                                     protocolLabel: label)
            completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(10 * 60))))
            return
        }

        // Build entries at: now + each future phase boundary + planned end
        let target = end.timeIntervalSince(start)
        var dates: [Date] = [now]
        for phaseHour in [4.0, 12.0, 16.0, 24.0] {
            let t = start.addingTimeInterval(phaseHour * 3600)
            if t > now && t <= end { dates.append(t) }
        }
        dates.append(end)

        let entries = dates.sorted().map { date -> FastingEntry in
            let elapsed  = date.timeIntervalSince(start)
            let progress = target > 0 ? min(1.0, max(0.0, elapsed / target)) : 0
            let phase    = FastingPhase.phase(forHoursElapsed: elapsed / 3600)
            return FastingEntry(date: date, start: start, end: end,
                                phaseTitle: phase.title, progress: progress,
                                protocolLabel: label)
        }

        // After the fast ends, poll again in 10 minutes to detect the next one
        completion(Timeline(entries: entries, policy: .after(end.addingTimeInterval(10 * 60))))
    }

    // Reads current state for getSnapshot
    private func makeCurrentEntry() -> FastingEntry {
        let defaults = UserDefaults(suiteName: SharedKey.suite)
        guard let start = defaults?.object(forKey: SharedKey.start) as? Date,
              let end   = defaults?.object(forKey: SharedKey.end)   as? Date else {
            return .empty
        }
        let label    = defaults?.string(forKey: SharedKey.protocol_) ?? ""
        let now      = Date()
        let elapsed  = now.timeIntervalSince(start)
        let target   = end.timeIntervalSince(start)
        let progress = target > 0 ? min(1.0, max(0.0, elapsed / target)) : 0
        let phase    = FastingPhase.phase(forHoursElapsed: elapsed / 3600)
        return FastingEntry(date: now, start: start, end: end,
                            phaseTitle: phase.title, progress: progress,
                            protocolLabel: label)
    }
}

// MARK: - Widget bundle

@main
struct FastingWidgetBundle: WidgetBundle {
    var body: some Widget {
        FastingHomeWidget()
        #if canImport(ActivityKit)
        FastingLiveActivityWidget()
        #endif
    }
}

// MARK: - Home / Lock Screen widget

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

// MARK: - Widget views

struct FastingWidgetView: View {
    var entry: FastingEntry
    @Environment(\.widgetFamily) private var family

    private var accentColor: Color { Color(red: 0.18, green: 0.78, blue: 0.68) }
    private var isFasting: Bool { entry.start != nil }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.25), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.phaseTitle)
                    .font(.caption.bold())
                if let end = entry.end {
                    Text(end, style: .timer)
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(accentColor)
                } else {
                    Text("Start a fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        default:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(isFasting ? entry.protocolLabel : "faster")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: isFasting ? "fork.knife" : "moon.zzz")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                if let end = entry.end {
                    Text(end, style: .timer)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(.white)
                } else {
                    Text("Not fasting")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                Text(entry.phaseTitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                ProgressView(value: entry.progress)
                    .tint(.white)
            }
            .padding()
            .containerBackground(for: .widget) { accentColor }
        }
    }
}

// MARK: - Live Activity widget

#if canImport(ActivityKit)
struct FastingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // Lock Screen / StandBy banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.protocolLabel)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Text(context.state.phaseTitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.end, style: .timer)
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.white)
                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding()
            .background(Color(red: 0.18, green: 0.78, blue: 0.68))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.phaseTitle, systemImage: "fork.knife")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 0.18, green: 0.78, blue: 0.68))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.end, style: .timer)
                        .monospacedDigit()
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.protocolLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "fork.knife")
                    .foregroundStyle(Color(red: 0.18, green: 0.78, blue: 0.68))
            } compactTrailing: {
                Text(context.state.end, style: .timer)
                    .monospacedDigit()
                    .font(.caption2.bold())
            } minimal: {
                Image(systemName: "fork.knife")
                    .foregroundStyle(Color(red: 0.18, green: 0.78, blue: 0.68))
            }
        }
    }
}
#endif
