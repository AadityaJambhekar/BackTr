import SwiftUI
import Charts

struct ResultsView: View {
    let result: BacktestResponse
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var savedStore: SavedBacktestsStore
    @State private var showShare = false
    @State private var isSaved = false

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {

                    // Nav
                    HStack {
                        Button { Haptics.tap(); dismiss() } label: {
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
                        HStack(spacing: 16) {
                            Button {
                                Haptics.tap()
                                if !isSaved {
                                    savedStore.save(result)
                                    isSaved = true
                                }
                            } label: {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 15))
                                    .foregroundColor(.backtrAccent)
                            }
                            Button { Haptics.tap(); showShare = true } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15))
                                    .foregroundColor(.backtrAccent)
                            }
                            .sheet(isPresented: $showShare) {
                                ShareSheet(items: shareItems())
                            }
                        }
                    }
                    .padding(.top, 8)

                    // Hero return — the number that matters most, given real visual weight
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel("Total Return · \(yearRange())")

                        Text(formatPct(result.metrics.total_return_pct, showPlus: true))
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(result.metrics.total_return_pct >= 0 ? .backtrGreen : .backtrRed)

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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [(result.metrics.total_return_pct >= 0 ? Color.backtrGreen : Color.backtrRed).opacity(0.14), Color.backtrCard],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke((result.metrics.total_return_pct >= 0 ? Color.backtrGreen : Color.backtrRed).opacity(0.25), lineWidth: 1)
                    )

                    // Why — plain-language read on the numbers, styled as an annotation, not a feature card
                    HStack(alignment: .top, spacing: 12) {
                        Rectangle()
                            .fill(Color.backtrAccent.opacity(0.5))
                            .frame(width: 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Why")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.backtrSub)
                            Text(result.ai_insight)
                                .font(.system(size: 13))
                                .foregroundColor(.backtrSub)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)

                    // Metrics grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        MetricTile(label: "EQUITY",    value: formatDollars(result.metrics.final_equity), color: .backtrAccent)
                        MetricTile(label: "DRAWDOWN",  value: formatPct(result.metrics.max_drawdown_pct, showPlus: true), color: .backtrRed)
                        MetricTile(label: "SHARPE",    value: String(format: "%.2f", result.metrics.sharpe_ratio), color: result.metrics.sharpe_ratio >= 1 ? .backtrGreen : .white)
                        MetricTile(label: "WIN RATE",  value: formatPct(result.metrics.win_rate_pct, showPlus: false), color: result.metrics.win_rate_pct >= 50 ? .backtrGreen : .backtrRed)
                        MetricTile(label: "TRADES",    value: "\(result.metrics.num_trades)", color: .white)
                        MetricTile(label: "ALPHA",     value: formatPct(result.metrics.alpha, showPlus: true), color: result.metrics.alpha >= 0 ? .backtrGreen : .backtrRed)
                        MetricTile(label: "CAGR",      value: formatPct(result.metrics.cagr_pct, showPlus: true), color: result.metrics.cagr_pct >= 0 ? .backtrGreen : .backtrRed)
                        MetricTile(label: "SORTINO",   value: String(format: "%.2f", result.metrics.sortino_ratio), color: result.metrics.sortino_ratio >= 1 ? .backtrGreen : .white)
                        MetricTile(label: "CALMAR",    value: String(format: "%.2f", result.metrics.calmar_ratio), color: result.metrics.calmar_ratio >= 1 ? .backtrGreen : .white)
                        MetricTile(label: "PROFIT FACTOR", value: formatProfitFactor(result.metrics.profit_factor), color: (result.metrics.profit_factor ?? 0) >= 1 ? .backtrGreen : .white)
                        MetricTile(label: "AVG DURATION", value: "\(String(format: "%.0f", result.metrics.avg_trade_duration_days))d", color: .white)
                        MetricTile(label: "EXPOSURE",  value: formatPct(result.metrics.exposure_pct, showPlus: false), color: .white)
                    }

                    // Chart
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Equity Curve")
                        EquityChartView(equityCurve: result.equity_curve, bahCurve: result.bah_curve, spyCurve: result.spy_curve)
                    }
                    .padding(16)
                    .backtrCard()

                    // Consistency across sub-periods (walk-forward, no re-fitting — fixed strategy rules)
                    if !result.walk_forward.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel("Consistency")
                            Text("How this strategy did in each stretch of the period, run independently — a big total from one lucky stretch looks different from steady gains across all of them.")
                                .font(.system(size: 11))
                                .foregroundColor(.backtrMuted)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: 0) {
                                ForEach(result.walk_forward) { window in
                                    WalkForwardRow(window: window)
                                    if window.id != result.walk_forward.last?.id {
                                        Divider().background(Color.backtrBorder)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .backtrCard()
                    }

                    // Trade log
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel("Trade Log")
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

    private func formatProfitFactor(_ v: Double?) -> String {
        guard let v else { return "∞" }
        return String(format: "%.2f", v)
    }

    private func shareText() -> String {
        let r = result.metrics
        let plus = r.total_return_pct > 0 ? "+" : ""
        let alphaPct = String(format: "%@%.1f%%", r.alpha >= 0 ? "+" : "", r.alpha)
        return """
        BackTr — \(result.ticker) · \(strategyName()) · \(yearRange())

        Total Return: \(plus)\(String(format: "%.1f", r.total_return_pct))%
        vs Buy & Hold: \(String(format: "%.1f", r.bah_return_pct))%
        vs SPY: \(r.spy_return_pct.map { String(format: "%.1f", $0) + "%" } ?? "n/a")
        Alpha: \(alphaPct)

        CAGR: \(String(format: "%.1f", r.cagr_pct))%
        Sharpe Ratio: \(String(format: "%.2f", r.sharpe_ratio))
        Sortino Ratio: \(String(format: "%.2f", r.sortino_ratio))
        Max Drawdown: \(String(format: "%.1f", r.max_drawdown_pct))%
        Win Rate: \(String(format: "%.1f", r.win_rate_pct))%
        Trades: \(r.num_trades)

        Tested with BackTr
        """
    }

    @MainActor
    private func shareImage() -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(result: result, strategyName: strategyName(), yearRange: yearRange()))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func shareItems() -> [Any] {
        var items: [Any] = []
        if let image = shareImage() { items.append(image) }
        items.append(shareText())
        return items
    }
}

struct ShareCardView: View {
    let result: BacktestResponse
    let strategyName: String
    let yearRange: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image("LogoMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 0) {
                        Text("Back").foregroundColor(.white)
                        Text("Tr").foregroundColor(.backtrAccent)
                    }
                    .font(.system(size: 16, weight: .bold))
                    Text("\(result.ticker) · \(strategyName) · \(yearRange)")
                        .font(.system(size: 11))
                        .foregroundColor(.backtrMuted)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(formatPct(result.metrics.total_return_pct))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(result.metrics.total_return_pct >= 0 ? .backtrGreen : .backtrRed)
                Text("vs Buy & Hold \(formatPct(result.metrics.bah_return_pct)) · Alpha \(formatPct(result.metrics.alpha))")
                    .font(.system(size: 12))
                    .foregroundColor(.backtrSub)
            }

            HStack(spacing: 0) {
                shareStat("SHARPE", String(format: "%.2f", result.metrics.sharpe_ratio))
                shareStat("MAX DD", formatPct(result.metrics.max_drawdown_pct))
                shareStat("WIN RATE", String(format: "%.0f%%", result.metrics.win_rate_pct))
                shareStat("TRADES", "\(result.metrics.num_trades)")
            }
            .padding(.vertical, 12)
            .background(Color.backtrBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .frame(width: 360)
        .background(Color.backtrCard)
    }

    private func shareStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.backtrMuted)
                .tracking(0.4)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatPct(_ v: Double) -> String {
        let prefix = v > 0 ? "+" : ""
        return String(format: "\(prefix)%.1f%%", v)
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(label)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .backtrCard(radius: 12)
    }
}

struct WalkForwardRow: View {
    let window: WalkForwardWindow
    private var beatsBah: Bool { window.total_return_pct >= window.bah_return_pct }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(shortDate(window.start_date)) – \(shortDate(window.end_date))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Text("\(window.num_trades) trades · \(String(format: "%.0f", window.win_rate_pct))% win rate")
                    .font(.system(size: 10))
                    .foregroundColor(.backtrMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%@%.1f%%", window.total_return_pct >= 0 ? "+" : "", window.total_return_pct))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(window.total_return_pct >= 0 ? .backtrGreen : .backtrRed)
                Text(beatsBah ? "beat market" : "trailed market")
                    .font(.system(size: 10))
                    .foregroundColor(.backtrMuted)
            }
        }
        .padding(.vertical, 10)
    }

    private func shortDate(_ s: String) -> String {
        let parts = s.split(separator: "-")
        guard parts.count == 3 else { return s }
        let months = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let m = Int(parts[1]) ?? 0
        return "\(months[m]) '\(parts[0].suffix(2))"
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
