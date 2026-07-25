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

                        // Logo
                        HStack(spacing: 0) {
                            Text("Back")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                                .kerning(-0.6)
                            Text("tr")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.backtrAccent)
                                .kerning(-0.6)
                        }
                        .padding(.top, 8)

                        // Ticker card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TICKER")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.backtrMuted)
                                .kerning(0.5)
                            HStack {
                                TextField("AAPL", text: $vm.ticker)
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                    .kerning(-0.6)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                Spacer()
                                Text("NASDAQ")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.backtrAccent)
                                    .kerning(0.3)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.backtrAccent.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(16)
                        .backtrCard()

                        // Date range card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DATE RANGE")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.backtrMuted)
                                .kerning(0.5)

                            HStack(spacing: 8) {
                                ForEach([1, 3, 5], id: \.self) { yr in
                                    Button {
                                        setRange(years: yr)
                                    } label: {
                                        Text("\(yr)Y")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(isActiveRange(yr) ? .white : .backtrSub)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isActiveRange(yr) ? Color.backtrAccent : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isActiveRange(yr) ? Color.clear : Color.backtrBorder, lineWidth: 0.5))
                                    }
                                }
                            }

                            let df = displayFormatter()
                            Text("\(df.string(from: vm.startDate)) – \(df.string(from: vm.endDate))")
                                .font(.system(size: 12))
                                .foregroundColor(.backtrSub)
                        }
                        .padding(16)
                        .backtrCard()

                        // Strategy card
                        Button { showStrategyPicker = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("STRATEGY")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.backtrMuted)
                                        .kerning(0.5)
                                    Text(vm.selectedStrategy.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .kerning(-0.3)
                                    Text(vm.selectedStrategy.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.backtrMuted)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.backtrAccent)
                            }
                        }
                        .padding(16)
                        .backtrCard()

                        // Capital card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INITIAL CAPITAL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.backtrMuted)
                                .kerning(0.5)
                            HStack {
                                Text("$")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.backtrSub)
                                TextField("10000", text: $vm.initialCapital)
                                    .font(.system(size: 20, weight: .bold))
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
                            ZStack {
                                LinearGradient(
                                    colors: [Color(hex: "5B9EFF"), Color(hex: "2563eb")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                                if vm.isLoading {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.white)
                                        Text("Running…")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Text("Run Backtest")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 52)
                        }
                        .disabled(vm.isLoading)

                        if let error = vm.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.backtrRed)
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
                    .padding(.bottom, 32)
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

    private func displayFormatter() -> DateFormatter {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f
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
                    Text("Strategy")
                        .font(.system(size: 20, weight: .bold))
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
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(s.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.backtrMuted)
                                    }
                                    Spacer()
                                    if selected.id == s.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.backtrAccent)
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .padding(16)
                                .backtrCard()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selected.id == s.id ? Color.backtrAccent : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview { ContentView() }
