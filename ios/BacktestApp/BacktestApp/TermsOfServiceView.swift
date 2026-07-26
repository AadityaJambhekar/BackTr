import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

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
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                    // Document
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TERMS OF SERVICE")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .tracking(0.5)
                            Text("Effective Date: July 26, 2026")
                                .font(.system(size: 12, design: .serif))
                                .italic()
                                .foregroundColor(.backtrMuted)
                        }

                        Rectangle()
                            .fill(Color.backtrBorder)
                            .frame(height: 1)

                        Text("These Terms of Service (\"Terms\") govern your access to and use of the BackTr mobile application (the \"App\"), operated as an independent, individually-developed hobby project. By downloading, accessing, or using the App, you agree to be bound by these Terms. If you do not agree, you should not use the App.")
                            .documentBody()

                        // Prominent disclaimer callout
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.backtrRed)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NOT FINANCIAL ADVICE")
                                    .font(.system(size: 12, weight: .bold, design: .serif))
                                    .tracking(0.5)
                                    .foregroundColor(.white)
                                Text("The App is provided solely for education and entertainment. Nothing in the App constitutes investment, financial, tax, or legal advice, and none of it should be relied upon to make real trading or investment decisions.")
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundColor(.backtrSub)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(16)
                        .background(Color.backtrRed.opacity(0.08))
                        .overlay(Rectangle().frame(width: 3).foregroundColor(.backtrRed), alignment: .leading)

                        tosSection(
                            "1. Nature of the Service",
                            "The App simulates the hypothetical historical performance of rules-based trading strategies against past market data. These simulations do not represent real trades, do not guarantee similar future results, and do not account for every factor that could affect real-world performance, including but not limited to slippage, liquidity constraints, taxes, order execution delays, and changes in market structure. The App is provided strictly for research, learning, and entertainment purposes."
                        )

                        tosSection(
                            "2. No Investment Advice",
                            "Nothing produced by the App — including but not limited to backtest results, performance metrics, benchmark comparisons, or any automatically generated commentary — constitutes financial, investment, legal, or tax advice, or a recommendation to buy, sell, or hold any security or financial instrument. You are solely responsible for any decisions made in connection with your use of the App, and you should consult a licensed financial advisor before making any investment decision. Past performance, whether real or simulated, is not indicative of future results."
                        )

                        tosSection(
                            "3. Data Sources & Accuracy",
                            "Market data displayed or used by the App is sourced from third-party data providers and may be delayed, incomplete, revised, or contain inaccuracies. The developer makes no warranty, express or implied, as to the accuracy, completeness, reliability, or timeliness of any data, calculation, or figure presented within the App."
                        )

                        tosSection(
                            "4. No Warranty",
                            "The App is provided \"as is\" and \"as available,\" without warranties of any kind, whether express, implied, or statutory, including without limitation any warranty of merchantability, fitness for a particular purpose, or non-infringement."
                        )

                        tosSection(
                            "5. Limitation of Liability",
                            "To the fullest extent permitted by applicable law, the developer shall not be liable for any direct, indirect, incidental, consequential, or special damages — including without limitation trading or investment losses — arising out of or in connection with your access to, use of, or inability to use the App."
                        )

                        tosSection(
                            "6. Changes to These Terms",
                            "These Terms may be revised from time to time. Material changes will be reflected by an updated Effective Date above. Continued use of the App following any such change constitutes your acceptance of the revised Terms."
                        )

                        tosSection(
                            "7. Governing Law",
                            "These Terms shall be governed by and construed in accordance with the laws applicable in the developer's jurisdiction of residence, without regard to conflict-of-law principles."
                        )

                        tosSection(
                            "8. Contact",
                            "Questions regarding these Terms may be directed to the developer through the App's listing on the Apple App Store."
                        )
                    }
                    .padding(20)
                    .background(Color.backtrCard)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.backtrBorder, lineWidth: 0.5))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func tosSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold, design: .serif))
                .tracking(0.4)
                .foregroundColor(.white)
            Text(body)
                .documentBody()
        }
    }
}

private extension Text {
    func documentBody() -> some View {
        self
            .font(.system(size: 13, design: .serif))
            .foregroundColor(.backtrSub)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}
