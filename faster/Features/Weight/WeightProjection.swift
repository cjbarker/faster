import Foundation

struct WeightPoint: Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var weightKg: Double
}

enum WeightProjection {
    /// Compute a simple 7-day moving average.
    static func movingAverage(_ points: [WeightPoint], window: Int = 7) -> [WeightPoint] {
        guard points.count >= 2 else { return points }
        let sorted = points.sorted { $0.date < $1.date }
        var out: [WeightPoint] = []
        for i in 0..<sorted.count {
            let start = max(0, i - window + 1)
            let slice = sorted[start...i]
            let avg = slice.map(\.weightKg).reduce(0, +) / Double(slice.count)
            out.append(WeightPoint(date: sorted[i].date, weightKg: avg))
        }
        return out
    }

    /// A straight-line projection from the latest point to target/goalDate.
    static func projection(latest: WeightPoint?, target: Double, goalDate: Date?) -> [WeightPoint] {
        guard let latest, let goalDate, goalDate > latest.date else { return [] }
        return [
            latest,
            WeightPoint(date: goalDate, weightKg: target)
        ]
    }
}
