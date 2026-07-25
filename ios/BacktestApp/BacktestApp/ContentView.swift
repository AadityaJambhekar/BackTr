import SwiftUI

struct ContentView: View {
    @StateObject private var vm = BacktestViewModel()
    @State private var showResults = false
    @State private var showStrategyPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.backtrBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        // Header
                        HStack(alignment: .center) {
                            HStack(spacing: 0) {
                                Text("Back")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .kerning(-0.5)
                                Text("tr")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.backtrAccent)
                                    .kerning(-0.5)
                            }
                            Spacer()
                            Text("Strategy Backtester")
                                .font(.system(size: 12))
                                .foregroundColor(.backtrMuted)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        // Ticker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TICKER")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.backtrMuted)
                                .kerning(0.8)
                            TextField("e.g. AAPL", text: $vm.ticker)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .kerning(-0.5)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                        }
                        .padding(16)
                        .backtrCard()

                        // Date range
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DATE RANGE")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.backtrMuted)
                                .kerning(0.8)

                            HStack(spacing: 8) {
                                ForEach([1, 3, 5], id: \.self) { yr in
                                    Button { setRange(years: yr) } label: {
                                        Text("\(yr)Y")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(isActiveRange(yr) ? .white : .backtrSub)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                isActiveRange(yr)
                                                    ? Color.backtrAccent
                                                    : Color.backtrBorder.opacity(0.5)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }

                            Text("\(fmt(vm.startDate)) – \(fmt(vm.endDate))")
                                .font(.system(size: 12))
                                .foregroundColor(.backtrSub)
                        }
                        .padding(16)
                        .backtrCard()

                        // Strategy picker
                        Button { showStrategyPicker = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("STRATEGY")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.backtrMuted)
                                        .kerning(0.8)
                                    Text(vm.selectedStrategy.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(vm.selectedStrategy.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.backtrMuted)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.backtrMuted)
                            }
                        }
                        .padding(16)
                        .backtrCard()

                        // Initial capital
                        VStack(alignment: .leading, spacing: 6) {
                            Text("INITIAL CAPITAL")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.backtrMuted)
                                .kerning(0.8)
                            HStack(spacing: 2) {
                                Text("$")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.backtrSub)
                                TextField("10000", text: $vm.initialCapital)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                            }
                        }
                        .padding(16)
                        .backtrCard()

                        // Run button
                        Button {
                            Task {
                                await vm.runBacktest()
                                if vm.result != nil { showResults = true }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if vm.isLoading {
                                    ProgressView().tint(.white).scaleEffect(0.85)
                                    Text("Running…")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("Run Backtest")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.backtrAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .opacity(vm.isLoading ? 0.75 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isLoading)

                        // Error
                        if let error = vm.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.backtrRed)
                                    .font(.system(size: 13))
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.backtrRed)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.backtrRed.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showResults, onDismiss: { vm.reset() }) {
                if let result = vm.result { ResultsView(result: result) }
            }
            .sheet(isPresented: $showStrategyPicker) {
                StrategyPickerView(selected: $vm.selectedStrategy)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func setRange(years: Int) {
        vm.endDate = Date()
        vm.startDate = Calendar.current.date(byAdding: .year, value: -years, to: Date()) ?? Date()
    }

    private func isActiveRange(_ years: Int) -> Bool {
        let diff = Calendar.current.dateComponents([.year], from: vm.startDate, to: vm.endDate)
        return diff.year == years
    }

    private func fmt(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: date)
    }
}

struct StrategyPickerView: View {
    @Binding var selected: Strategy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backtrBg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Select Strategy")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundColor(.backtrAccent)
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(20)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(availableStrategies) { s in
                            Button {
                                selected = s
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(s.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.backtrMuted)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    if selected.id == s.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.backtrAccent)
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(14)
                                .background(
                                    selected.id == s.id
                                        ? Color.backtrAccent.opacity(0.12)
                                        : Color.backtrCard
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selected.id == s.id ? Color.backtrAccent : Color.backtrBorder,
                                            lineWidth: selected.id == s.id ? 1 : 0.5
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview { ContentView() }
