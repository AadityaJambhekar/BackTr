import SwiftUI
import Charts

struct ResultsView: View {
    let result: BacktestResponse
    @Environment(\.dismiss) private var dismiss
    @State private var showShare = false

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Nav
                    HStack {
                        Button { dismiss() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(.backtrAccent)
                        }
                        Spacer()
                        Text("\(result.ticker) · \(strategyName())")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Button { showShare = true } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15))
                                .foregroundColor(.backtrAccent)
                        }
                        .sheet(isPresented: $showShare) {
                            ShareSheet(items: [shareText()])
                        }
                    }
                    .padding(.top, 8)

                    // Hero return
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TOTAL RETURN · \(yearRange())")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.backtrMuted)
                            .kerning(0.4)

                        Text(formatPct(result.metrics.total_return_pct, showPlus: true))
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(result.metrics.total_return_pct >= 0 ? .backtrGreen : .backtrRed)
                            .kerning(-2)

                        HStack(spacing: 6) {
                            Text("vs Buy & Hold \(formatPct(result.metrics.bah_return_pct, showPlus: true))")
                                .foregroundColor(.backtrSub)
                            Text("·")
                                .foregroundColor(.backtrMuted)
                            Text("Alpha \(formatPct(result.metrics.alpha, showPlus: true))")
                                .foregroundColor(result.metrics.alpha >= 0 ? .backtrGreen : .backtrRed)
                        }
                        .font(.system(size: 12))
                    }
                    .padding(16)
                    .backtrCard()

                    // Metrics grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        MetricTile(label: "EQUITY",    value: formatDollars(result.metrics.final_equity), color: .backtrAccent)
                        MetricTile(label: "DRAWDOWN",  value: formatPct(result.metrics.max_drawdown_pct, showPlus: true), color: .backtrRed)
                        MetricTile(label: "SHARPE",    value: String(format: "%.2f", result.metrics.sharpe_ratio), color: result.metrics.sharpe_ratio >= 1 ? .backtrGreen : .white)
                        MetricTile(label: "WIN RATE",  value: formatPct(result.metrics.win_rate_pct, showPlus: false), color: result.metrics.win_rate_pct >= 50 ? .backtrGreen : .backtrRed)
                        MetricTile(label: "TRADES",    value: "\(result.metrics.num_trades)", color: .white)
                        MetricTile(label: "ALPHA",     value: formatPct(result.metrics.alpha, showPlus: true), color: result.metrics.alpha >= 0 ? .backtrGreen : .backtrRed)
                    }

                    // Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EQUITY CURVE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.backtrMuted)
                            .kerning(0.4)
                        EquityChartView(equityCurve: result.equity_curve, bahCurve: result.bah_curve)
                    }
                    .padding(16)
                    .backtrCard()

                    // Trade log
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("TRADE LOG")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.backtrMuted)
                                .kerning(0.4)
                            Spacer()
                            Text("\(result.trade_log.count) trades")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.backtrAccent)
                        }

                        if result.trade_log.isEmpty {
                            Text("No completed trades in this period.")
                                .font(.system(size: 13))
                                .foregroundColor(.backtrMuted)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(result.trade_log.enumerated()), id: \.element.id) { idx, trade in
                                    TradeRow(trade: trade, capital: result.metrics.initial_capital)
                                    if idx < result.trade_log.count - 1 {
                                        Divider()
                                            .background(Color.backtrBorder)
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .backtrCard()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func strategyName() -> String {
        availableStrategies.first { $0.id == result.strategy }?.name ?? result.strategy
    }

    private func yearRange() -> String {
        let s = result.start_date.prefix(4)
        let e = result.end_date.prefix(4)
        if s == e { return String(s) }
        let diff = (Int(e) ?? 0) - (Int(s) ?? 0)
        return "\(diff)Y"
    }

    private func formatPct(_ v: Double, showPlus: Bool) -> String {
        let prefix = showPlus && v > 0 ? "+" : ""
        return String(format: "\(prefix)%.1f%%", v)
    }

    private func formatDollars(_ v: Double) -> String {
        if v >= 1_000 { return String(format: "$%.0fk", v / 1000) }
        return String(format: "$%.0f", v)
    }

    private func shareText() -> String {
        let r = result.metrics
        let plus = r.total_return_pct > 0 ? "+" : ""
        let alphaPct = String(format: "%@%.1f%%", r.alpha >= 0 ? "+" : "", r.alpha)
        return """
        📊 Backtr — \(result.ticker) · \(strategyName()) · \(yearRange())

        Total Return: \(plus)\(String(format: "%.1f", r.total_return_pct))%
        vs Buy & Hold: \(String(format: "%.1f", r.bah_return_pct))%
        Alpha: \(alphaPct)

        Sharpe Ratio: \(String(format: "%.2f", r.sharpe_ratio))
        Max Drawdown: \(String(format: "%.1f", r.max_drawdown_pct))%
        Win Rate: \(String(format: "%.1f", r.win_rate_pct))%
        Trades: \(r.num_trades)

        Tested with Backtr
        """
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.backtrMuted)
                .kerning(0.4)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .kerning(-0.4)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .backtrCard()
    }
}

struct TradeRow: View {
    let trade: Trade
    let capital: Double
    private var isWin: Bool { trade.result == "win" }

    var body: some View {
        HStack(spacing: 12) {
            // Colored left bar
            Rectangle()
                .fill(isWin ? Color.backtrGreen : Color.backtrRed)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .frame(height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(shortDate(trade.entry_date)) – \(shortDate(trade.exit_date))")
                    .font(.system(size: 11))
                    .foregroundColor(.backtrSub)
                Text("Buy $\(String(format: "%.2f", trade.entry_price)) → Sell $\(String(format: "%.2f", trade.exit_price))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                let dollars = trade.dollarPnl(capital: capital)
                Text(String(format: "%@$%.0f", dollars >= 0 ? "+" : "-", abs(dollars)))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isWin ? .backtrGreen : .backtrRed)
                Text(String(format: "%@%.1f%%", trade.pnl_pct >= 0 ? "+" : "", trade.pnl_pct))
                    .font(.system(size: 11))
                    .foregroundColor(isWin ? .backtrGreen.opacity(0.7) : .backtrRed.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
    }

    private func shortDate(_ s: String) -> String {
        let parts = s.split(separator: "-")
        guard parts.count == 3 else { return s }
        let months = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let m = Int(parts[1]) ?? 0
        let d = Int(parts[2]) ?? 0
        return "\(months[m]) \(d)"
    }
}

import UIKit
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
