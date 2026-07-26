import SwiftUI

struct TermsOfServiceView: View {
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
                        Text("Terms of Service")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text("Last updated July 2026")
                            .font(.system(size: 12))
                            .foregroundColor(.backtrMuted)
                    }

                    // Prominent disclaimer callout
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.backtrRed)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Not Financial Advice")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("Backtr is a hobby project built for education and entertainment. Nothing in this app is investment, financial, tax, or legal advice, and it should not be relied on to make real trading or investment decisions.")
                                .font(.system(size: 13))
                                .foregroundColor(.backtrSub)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .background(Color.backtrRed.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.backtrRed.opacity(0.3), lineWidth: 1))

                    tosSection(
                        "1. Acceptance of Terms",
                        "By downloading, accessing, or using Backtr (\"the App\"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App."
                    )

                    tosSection(
                        "2. For Entertainment & Educational Use Only",
                        "The App simulates the historical performance of trading strategies against past market data. These simulations are hypothetical, do not reflect real trading, and do not account for every real-world factor that could affect actual results — including slippage, liquidity, taxes, and order execution. The App is provided purely for research, learning, and entertainment purposes."
                    )

                    tosSection(
                        "3. Not Financial Advice",
                        "Nothing produced by the App — including backtest results, performance metrics, or the automatically generated \"Why\" analysis — constitutes financial, investment, legal, or tax advice, or a recommendation to buy, sell, or hold any security. You should consult a licensed financial advisor before making any investment decision. Past performance, whether real or simulated, is not indicative of future results."
                    )

                    tosSection(
                        "4. Data & Accuracy",
                        "Market data is sourced from third-party providers and may be delayed, incomplete, or contain errors. Backtr makes no warranty, express or implied, as to the accuracy, completeness, or timeliness of any data or calculation shown in the App."
                    )

                    tosSection(
                        "5. Limitation of Liability",
                        "The App is provided \"as is\" without warranties of any kind. To the fullest extent permitted by law, the developer is not liable for any loss or damage — including trading or investment losses — arising from your use of, or reliance on, the App."
                    )

                    tosSection(
                        "6. Changes to These Terms",
                        "These Terms may be updated from time to time. Continued use of the App after changes are posted constitutes acceptance of the revised Terms."
                    )

                    tosSection(
                        "7. Contact",
                        "Questions about these Terms can be sent to the developer via the App Store listing."
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func tosSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Text(body)
                .font(.system(size: 13))
                .foregroundColor(.backtrSub)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
