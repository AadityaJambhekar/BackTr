import SwiftUI

struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

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
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How BackTr Works")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text("A quick guide to running a backtest and reading the results.")
                            .font(.system(size: 13))
                            .foregroundColor(.backtrSub)
                    }

                    // The basics
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel("The Basics")
                            .padding(.bottom, 14)

                        StepRow(number: "1", title: "Pick a stock", subtitle: "Enter any ticker — AAPL, TSLA, MSFT — or search by company name")
                        Divider().background(Color.backtrBorder).padding(.vertical, 12)
                        StepRow(number: "2", title: "Choose a strategy", subtitle: "MACD, RSI, Bollinger Bands, moving averages, breakout, or a majority-vote ensemble")
                        Divider().background(Color.backtrBorder).padding(.vertical, 12)
                        StepRow(number: "3", title: "Run it", subtitle: "See what that strategy would have returned over your chosen date range, trade by trade")
                    }
                    .padding(20)
                    .backtrCard()

                    // Understanding results
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel("Understanding Your Results")
                            .padding(.bottom, 14)

                        InfoRow(icon: "chart.line.uptrend.xyaxis", title: "Total Return & Alpha",
                                subtitle: "Your strategy's return, and how much better or worse it did than simply buying and holding — or holding SPY.")
                        Divider().background(Color.backtrBorder).padding(.vertical, 12)
                        InfoRow(icon: "waveform.path.ecg", title: "Sharpe & Sortino Ratio",
                                subtitle: "Return per unit of risk taken. Above 1.0 is generally considered solid; Sortino only counts downside volatility.")
                        Divider().background(Color.backtrBorder).padding(.vertical, 12)
                        InfoRow(icon: "arrow.down.right", title: "Max Drawdown",
                                subtitle: "The worst peak-to-trough drop your account would have seen — a measure of how painful the ride was.")
                        Divider().background(Color.backtrBorder).padding(.vertical, 12)
                        InfoRow(icon: "checkmark.circle", title: "Win Rate & Profit Factor",
                                subtitle: "Share of trades that were profitable, and total gains divided by total losses across all trades.")
                    }
                    .padding(20)
                    .backtrCard()

                    // Methodology
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Methodology")
                        Text("Price history comes from Yahoo Finance. Every simulated trade includes a 0.1% transaction cost, and every result is shown against both a buy-and-hold baseline and the S&P 500 (SPY) so you can judge a strategy against the market, not just against doing nothing.")
                            .font(.system(size: 13))
                            .foregroundColor(.backtrSub)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .backtrCard()

                    Text("BackTr simulates historical performance for research and entertainment. It's not a recommendation to buy or sell anything — see Terms of Service for details.")
                        .font(.system(size: 11))
                        .foregroundColor(.backtrMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.backtrAccent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.backtrAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.backtrMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
