import SwiftUI
import Charts

struct WeightChartView: View {
    var points: [WeightPoint]
    var trend: [WeightPoint]
    var projection: [WeightPoint]

    var body: some View {
        Chart {
            ForEach(points) { p in
                PointMark(
                    x: .value("Date", p.date),
                    y: .value("Weight", p.weightKg)
                )
                .foregroundStyle(AppColor.accent.opacity(0.5))
                .symbolSize(36)
            }
            ForEach(trend) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Trend", p.weightKg)
                )
                .foregroundStyle(AppColor.accentGradient)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            ForEach(projection) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Projection", p.weightKg)
                )
                .foregroundStyle(AppColor.fastingRing.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color.secondary)
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
            }
        }
        .frame(height: 200)
    }
}
