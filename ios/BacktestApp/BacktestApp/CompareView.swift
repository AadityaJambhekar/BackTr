import SwiftUI

struct CompareView: View {
    let result: CompareResponse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            VStack(spacing: 0) {

                // Nav
                HStack {
                    Button { Haptics.tap(); dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Close")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(.backtrAccent)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    VStack(spacing: 2) {
                        Text(result.ticker)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Strategy Comparison")
                            .font(.system(size: 11))
                            .foregroundColor(.backtrMuted)
                    }
                    Spacer()
                    // Balance the close button
                    Text("Close").font(.system(size: 15)).opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // B&H baseline
                HStack {
                    Label("Buy & Hold baseline", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12))
                        .foregroundColor(.backtrMuted)
                    Spacer()
                    Text(formatPct(result.bah_return_pct, showPlus: true))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Strategy list
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(result.results.enumerated()), id: \.element.id) { idx, r in
                            CompareRow(rank: idx + 1, result: r, bahReturn: result.bah_return_pct)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formatPct(_ v: Double, showPlus: Bool) -> String {
        let prefix = showPlus && v > 0 ? "+" : ""
        return String(format: "\(prefix)%.1f%%", v)
    }
}

struct CompareRow: View {
    let rank: Int
    let result: CompareResult
    let bahReturn: Double

    private var beatsBah: Bool { result.total_return_pct > bahReturn }
    private var returnColor: Color { result.total_return_pct >= 0 ? .backtrGreen : .backtrRed }
    private var alphaColor: Color { result.alpha >= 0 ? .backtrGreen : .backtrRed }

    var body: some View {
        VStack(spacing: 12) {
            // Top row
            HStack(alignment: .top, spacing: 12) {
                // Rank badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(rank == 1 ? Color.backtrAccent : Color.backtrBorder.opacity(0.5))
                        .frame(width: 32, height: 32)
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(rank == 1 ? .white : .backtrSub)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(result.strategy_name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        if rank == 1 {
                            Text("BEST")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.backtrAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.backtrAccent.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Spacer()
                        Text(formatPct(result.total_return_pct, showPlus: true))
                            .font(.backtrDisplay(20))
                            .monospacedDigit()
                            .foregroundColor(returnColor)
                    }

                    HStack {
                        Text(beatsBah ? "Beats market" : "Underperforms market")
                            .font(.system(size: 11))
                            .foregroundColor(beatsBah ? .backtrGreen : .backtrMuted)
                        Spacer()
                        Text("Alpha \(formatPct(result.alpha, showPlus: true))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(alphaColor)
                    }
                }
            }

            // Stats row
            HStack(spacing: 0) {
                StatChip(label: "SHARPE", value: String(format: "%.2f", result.sharpe_ratio),
                         color: result.sharpe_ratio >= 1 ? .backtrGreen : .white)
                Divider().background(Color.backtrBorder).frame(height: 28)
                StatChip(label: "WIN RATE", value: formatPct(result.win_rate_pct, showPlus: false),
                         color: result.win_rate_pct >= 50 ? .backtrGreen : .backtrRed)
                Divider().background(Color.backtrBorder).frame(height: 28)
                StatChip(label: "DRAWDOWN", value: formatPct(result.max_drawdown_pct, showPlus: true),
                         color: .backtrRed)
                Divider().background(Color.backtrBorder).frame(height: 28)
                StatChip(label: "TRADES", value: "\(result.num_trades)", color: .white)
            }
            .background(Color.backtrBg.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(14)
        .background(rank == 1 ? Color.backtrAccent.opacity(0.08) : Color.backtrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(rank == 1 ? Color.backtrAccent.opacity(0.4) : Color.backtrBorder, lineWidth: rank == 1 ? 1 : 0.5)
        )
    }

    private func formatPct(_ v: Double, showPlus: Bool) -> String {
        let prefix = showPlus && v > 0 ? "+" : ""
        return String(format: "\(prefix)%.1f%%", v)
    }
}

struct StatChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            SectionLabel(label)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
