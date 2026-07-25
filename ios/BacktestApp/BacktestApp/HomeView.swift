import SwiftUI

struct HomeView: View {
    @Binding var showHome: Bool

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // Logo
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.backtrAccent)
                            .frame(width: 80, height: 80)
                        Text("B")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 0) {
                        Text("Back")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .kerning(-0.8)
                        Text("tr")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.backtrAccent)
                            .kerning(-0.8)
                    }

                    Text("Test any stock strategy. See real results.")
                        .font(.system(size: 15))
                        .foregroundColor(.backtrSub)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // How to use
                VStack(alignment: .leading, spacing: 0) {
                    Text("HOW IT WORKS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.backtrMuted)
                        .kerning(1)
                        .padding(.bottom, 14)

                    StepRow(number: "1", title: "Pick a stock", subtitle: "Enter any ticker — AAPL, TSLA, MSFT")
                    Divider().background(Color.backtrBorder).padding(.vertical, 12)
                    StepRow(number: "2", title: "Choose a strategy", subtitle: "MACD, RSI, Bollinger Bands and more")
                    Divider().background(Color.backtrBorder).padding(.vertical, 12)
                    StepRow(number: "3", title: "See what would have happened", subtitle: "Returns, drawdown, Sharpe ratio, every trade")
                }
                .padding(20)
                .background(Color.backtrCard)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.backtrBorder, lineWidth: 0.5))
                .padding(.horizontal, 20)

                Spacer().frame(height: 32)

                // Get started button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showHome = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.backtrAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Spacer().frame(height: 48)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct StepRow: View {
    let number: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.backtrAccent.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.backtrAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.backtrMuted)
            }
        }
    }
}
