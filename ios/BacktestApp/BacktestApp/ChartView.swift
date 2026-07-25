import SwiftUI
import Charts

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: Double
    let series: String
}

struct EquityChartView: View {
    let equityCurve: [EquityPoint]
    let bahCurve: [BAHPoint]

    private var chartData: [ChartPoint] {
        equityCurve.map { ChartPoint(date: $0.date, value: $0.equity, series: "Strategy") } +
        bahCurve.map    { ChartPoint(date: $0.date, value: $0.bah,    series: "Buy & Hold") }
    }

    var body: some View {
        Chart(chartData) { pt in
            if pt.series == "Strategy" {
                AreaMark(
                    x: .value("Date", pt.date),
                    y: .value("Value", pt.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.backtrAccent.opacity(0.3), Color.backtrAccent.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Date", pt.date),
                    y: .value("Value", pt.value)
                )
                .foregroundStyle(Color.backtrAccent)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
            } else {
                LineMark(
                    x: .value("Date", pt.date),
                    y: .value("Value", pt.value)
                )
                .foregroundStyle(Color.orange.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartForegroundStyleScale([
            "Strategy":   Color.backtrAccent,
            "Buy & Hold": Color.orange,
        ])
        .chartLegend(position: .top, alignment: .trailing) {
            HStack(spacing: 12) {
                Label("Strategy", systemImage: "minus")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.backtrAccent)
                Label("B&H", systemImage: "minus")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange.opacity(0.7))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .init(rawValue: max(1, chartData.count / 5)))) { _ in
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(Color.backtrMuted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { v in
                AxisValueLabel {
                    if let d = v.as(Double.self) {
                        Text("$\(Int(d / 1000))k")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.backtrMuted)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(Color.backtrBorder)
            }
        }
        .frame(height: 180)
    }
}
