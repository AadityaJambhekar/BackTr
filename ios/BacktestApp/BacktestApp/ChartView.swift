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
    let spyCurve: [SPYPoint]

    @State private var scrubbedDate: String? = nil

    private var chartData: [ChartPoint] {
        equityCurve.map { ChartPoint(date: $0.date, value: $0.equity, series: "Strategy") } +
        bahCurve.map    { ChartPoint(date: $0.date, value: $0.bah,    series: "Buy & Hold") } +
        spyCurve.map    { ChartPoint(date: $0.date, value: $0.spy,    series: "SPY") }
    }

    // Last known value at-or-before `date` for a resampled series (arrays are ascending by date).
    private func nearestValue<T>(_ points: [T], on date: String, date dateKey: (T) -> String, value valueKey: (T) -> Double) -> Double? {
        var best: T? = nil
        for p in points {
            if dateKey(p) <= date { best = p } else { break }
        }
        return best.map(valueKey) ?? points.first.map(valueKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(chartData) { pt in
                    switch pt.series {
                    case "Strategy":
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
                    case "SPY":
                        LineMark(
                            x: .value("Date", pt.date),
                            y: .value("Value", pt.value)
                        )
                        .foregroundStyle(Color.backtrSub)
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [2, 2]))
                        .interpolationMethod(.catmullRom)
                    default:
                        LineMark(
                            x: .value("Date", pt.date),
                            y: .value("Value", pt.value)
                        )
                        .foregroundStyle(Color.orange.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                        .interpolationMethod(.catmullRom)
                    }
                }

                if let scrubbedDate {
                    RuleMark(x: .value("Date", scrubbedDate))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }
            .chartForegroundStyleScale([
                "Strategy":   Color.backtrAccent,
                "Buy & Hold": Color.orange,
                "SPY":        Color.backtrSub,
            ])
            .chartLegend(position: .top, alignment: .trailing) {
                HStack(spacing: 12) {
                    Label("Strategy", systemImage: "minus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.backtrAccent)
                    Label("B&H", systemImage: "minus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange.opacity(0.7))
                    Label("SPY", systemImage: "minus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.backtrSub)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
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
                    AxisGridLine()
                        .foregroundStyle(Color.backtrBorder)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let x = drag.location.x - origin.x
                                    if let date: String = proxy.value(atX: x) {
                                        if scrubbedDate != date { Haptics.selection() }
                                        scrubbedDate = date
                                    }
                                }
                                .onEnded { _ in scrubbedDate = nil }
                        )
                }
            }
            .frame(height: 180)

            if let scrubbedDate {
                ScrubReadout(
                    date: scrubbedDate,
                    strategy: nearestValue(equityCurve, on: scrubbedDate, date: { $0.date }, value: { $0.equity }),
                    bah: nearestValue(bahCurve, on: scrubbedDate, date: { $0.date }, value: { $0.bah }),
                    spy: nearestValue(spyCurve, on: scrubbedDate, date: { $0.date }, value: { $0.spy })
                )
            }
        }
    }
}

private struct ScrubReadout: View {
    let date: String
    let strategy: Double?
    let bah: Double?
    let spy: Double?

    var body: some View {
        HStack(spacing: 14) {
            Text(date)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.backtrSub)
            Spacer()
            if let strategy { readout("Strategy", strategy, .backtrAccent) }
            if let bah { readout("B&H", bah, .orange.opacity(0.8)) }
            if let spy { readout("SPY", spy, .backtrSub) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.backtrBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.backtrBorder, lineWidth: 0.5))
    }

    private func readout(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 3) {
                Circle().fill(color).frame(width: 5, height: 5)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.backtrMuted)
            }
            Text(value >= 1000 ? String(format: "$%.1fk", value / 1000) : String(format: "$%.0f", value))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
