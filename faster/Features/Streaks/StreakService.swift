import Foundation

public enum StreakService {
    /// A fast counts as completed if it hit at least 90% of its planned duration.
    public static let completionThreshold: Double = 0.90

    public static func currentStreak(from sessions: [FastSessionSnapshot], now: Date = Date()) -> Int {
        let completed = sessions
            .filter { $0.endedAt != nil && $0.completionRatio >= completionThreshold }
            .sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }
        guard !completed.isEmpty else { return 0 }
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: now)
        for s in completed {
            guard let ended = s.endedAt else { continue }
            let day = Calendar.current.startOfDay(for: ended)
            if day == cursor || day == Calendar.current.date(byAdding: .day, value: -1, to: cursor) {
                streak += 1
                cursor = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? cursor
            } else {
                break
            }
        }
        return streak
    }

    public static func weeklySummary(from sessions: [FastSessionSnapshot], now: Date = Date()) -> WeeklySummary {
        let cal = Calendar.current
        let weekStart = cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: now)) ?? now
        let recent = sessions.filter { ($0.endedAt ?? $0.startedAt) >= weekStart }
        let completedCount = recent.filter { $0.completionRatio >= completionThreshold }.count
        let totalHours = recent.reduce(0.0) { $0 + $1.durationSeconds / 3600 }
        let avgMood = average(recent.compactMap { $0.mood })
        let avgEnergy = average(recent.compactMap { $0.energy })
        return WeeklySummary(
            completedCount: completedCount,
            totalFastingHours: totalHours,
            avgMood: avgMood,
            avgEnergy: avgEnergy
        )
    }

    private static func average(_ xs: [Int]) -> Double? {
        guard !xs.isEmpty else { return nil }
        return Double(xs.reduce(0, +)) / Double(xs.count)
    }
}

public struct FastSessionSnapshot: Sendable, Hashable {
    public var startedAt: Date
    public var endedAt: Date?
    public var completionRatio: Double
    public var durationSeconds: Double
    public var mood: Int?
    public var energy: Int?

    public init(startedAt: Date, endedAt: Date?, completionRatio: Double, durationSeconds: Double, mood: Int?, energy: Int?) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.completionRatio = completionRatio
        self.durationSeconds = durationSeconds
        self.mood = mood
        self.energy = energy
    }
}

public struct WeeklySummary: Sendable, Equatable {
    public var completedCount: Int
    public var totalFastingHours: Double
    public var avgMood: Double?
    public var avgEnergy: Double?
}
