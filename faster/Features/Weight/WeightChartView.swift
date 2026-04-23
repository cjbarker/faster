import SwiftUI
import Charts

struct WeightChartView: View {
    var points: [WeightPoint]
    var trend: [WeightPoint]
    var projection: [WeightPoint]

    var body: some View {
        Chart {
            ForEach(points) { p in
                PointMark(x: .value("Date", p.date), y: .value("Weight", p.weightKg))
                    .foregroundStyle(AppColor.accent.opacity(0.6))
            }
            ForEach(trend) { p in
                LineMark(x: .value("Date", p.date), y: .value("Trend", p.weightKg))
                    .foregroundStyle(AppColor.accent)
                    .interpolationMethod(.monotone)
            }
            ForEach(projection) { p in
                LineMark(x: .value("Date", p.date), y: .value("Projection", p.weightKg))
                    .foregroundStyle(AppColor.fastingRing.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
            }
        }
        .frame(height: 220)
    }
}
