import SwiftUI

struct SavedBacktestsView: View {
    @EnvironmentObject var store: SavedBacktestsStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedResult: BacktestResponse? = nil
    @State private var showResult = false

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            VStack(spacing: 0) {
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
                    Text("Saved Backtests")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Close").font(.system(size: 15)).opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if store.items.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 28))
                            .foregroundColor(.backtrMuted)
                        Text("No saved backtests yet")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.backtrSub)
                        Text("Tap the bookmark icon on a results screen to save it here.")
                            .font(.system(size: 12))
                            .foregroundColor(.backtrMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(store.items) { item in
                                Button {
                                    Haptics.selection()
                                    selectedResult = item.response
                                    showResult = true
                                } label: {
                                    SavedBacktestRow(item: item) {
                                        Haptics.tap()
                                        store.remove(item.id)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showResult) {
            if let selectedResult { ResultsView(result: selectedResult).environmentObject(store) }
        }
    }
}

struct SavedBacktestRow: View {
    let item: SavedBacktest
    let onDelete: () -> Void

    private var strategyName: String {
        availableStrategies.first { $0.id == item.response.strategy }?.name ?? item.response.strategy
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.response.ticker)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(strategyName)
                        .font(.system(size: 12))
                        .foregroundColor(.backtrMuted)
                }
                Text("\(item.response.start_date) – \(item.response.end_date)")
                    .font(.system(size: 11))
                    .foregroundColor(.backtrMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(formatPct(item.response.metrics.total_return_pct))
                    .font(.backtrDisplay(16))
                    .monospacedDigit()
                    .foregroundColor(item.response.metrics.total_return_pct >= 0 ? .backtrGreen : .backtrRed)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.backtrMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .backtrCard()
    }

    private func formatPct(_ v: Double) -> String {
        let prefix = v > 0 ? "+" : ""
        return String(format: "\(prefix)%.1f%%", v)
    }
}
