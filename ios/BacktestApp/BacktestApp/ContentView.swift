import SwiftUI

struct ContentView: View {
    @Binding var showHome: Bool
    @StateObject private var vm = BacktestViewModel()
    @State private var showResults = false
    @State private var showStrategyPicker = false
    @State private var showCompare = false
    @State private var selectedYears: Int = 3
    @State private var compareResult: CompareResponse? = nil
    @State private var isComparing = false
    @State private var compareError: String? = nil
    @State private var suggestions: [TickerSuggestion] = []
    @FocusState private var tickerFieldFocused: Bool
    @StateObject private var savedStore = SavedBacktestsStore()
    @State private var showSaved = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.backtrBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        // Header
                        HStack {
                            HStack(spacing: 0) {
                                Text("Back")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .kerning(-0.5)
                                Text("Tr")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.backtrAccent)
                                    .kerning(-0.5)
                            }
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    Haptics.tap()
                                    showSaved = true
                                } label: {
                                    Image(systemName: savedStore.items.isEmpty ? "bookmark" : "bookmark.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.backtrAccent)
                                }
                                .buttonStyle(.plain)
                                Button {
                                    Haptics.tap()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showHome = true
                                    }
                                } label: {
                                    Image(systemName: "house")
                                        .font(.system(size: 16))
                                        .foregroundColor(.backtrAccent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        // Ticker card
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Ticker")

                            TextField("e.g. AAPL", text: $vm.ticker)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($tickerFieldFocused)
                                .task(id: vm.ticker) { await fetchSuggestions() }

                            if tickerFieldFocused && !suggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(suggestions) { s in
                                        Button {
                                            Haptics.selection()
                                            vm.ticker = s.symbol
                                            suggestions = []
                                            tickerFieldFocused = false
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text(s.symbol)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.white)
                                                    Text(s.name)
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.backtrMuted)
                                                        .lineLimit(1)
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        if s.id != suggestions.last?.id {
                                            Divider().background(Color.backtrBorder)
                                        }
                                    }
                                }
                            } else {
                                // Quick tickers
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(quickTickers, id: \.self) { t in
                                            Button {
                                                Haptics.selection()
                                                vm.ticker = t
                                            } label: {
                                                Text(t)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(vm.ticker == t ? .white : .backtrSub)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(vm.ticker == t ? Color.backtrAccent : Color.backtrBorder.opacity(0.6))
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .backtrCard()

                        // Date range
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel("Date Range")

                            HStack(spacing: 8) {
                                ForEach([1, 3, 5], id: \.self) { yr in
                                    Button {
                                        Haptics.selection()
                                        selectedYears = yr
                                        vm.endDate = Date()
                                        vm.startDate = Calendar.current.date(byAdding: .year, value: -yr, to: Date()) ?? Date()
                                    } label: {
                                        Text("\(yr)Y")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedYears == yr ? .white : .backtrSub)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(selectedYears == yr ? Color.backtrAccent : Color.backtrBorder.opacity(0.5))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Text("\(fmt(vm.startDate)) – \(fmt(vm.endDate))")
                                .font(.system(size: 12))
                                .foregroundColor(.backtrSub)
                        }
                        .padding(16)
                        .backtrCard()

                        // Strategy picker
                        Button {
                            Haptics.tap()
                            showStrategyPicker = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    SectionLabel("Strategy")
                                    Text(vm.selectedStrategy.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(vm.selectedStrategy.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.backtrMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.backtrMuted)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                        .backtrCard()

                        // Capital
                        VStack(alignment: .leading, spacing: 6) {
                            SectionLabel("Initial Capital")
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
                            Haptics.tap()
                            Task {
                                await vm.runBacktest()
                                if vm.result != nil {
                                    Haptics.success()
                                    showResults = true
                                } else {
                                    Haptics.error()
                                }
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
                            .opacity(vm.isLoading ? 0.7 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isLoading || isComparing)

                        // Compare button
                        Button {
                            Haptics.tap()
                            Task { await runCompare() }
                        } label: {
                            HStack(spacing: 8) {
                                if isComparing {
                                    ProgressView().tint(.backtrAccent).scaleEffect(0.85)
                                    Text("Comparing…")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.backtrAccent)
                                } else {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.backtrAccent)
                                    Text("Compare All Strategies")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.backtrAccent)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.backtrAccent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.backtrAccent.opacity(0.3), lineWidth: 1))
                            .opacity(isComparing ? 0.7 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isLoading || isComparing)

                        // Errors
                        if let error = vm.errorMessage {
                            ErrorBanner(message: error)
                        }
                        if let error = compareError {
                            ErrorBanner(message: error)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showResults, onDismiss: { vm.reset() }) {
                if let result = vm.result { ResultsView(result: result).environmentObject(savedStore) }
            }
            .sheet(isPresented: $showStrategyPicker) {
                StrategyPickerView(selected: $vm.selectedStrategy)
            }
            .sheet(isPresented: $showCompare) {
                if let cr = compareResult { CompareView(result: cr) }
            }
            .sheet(isPresented: $showSaved) {
                SavedBacktestsView().environmentObject(savedStore)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func runCompare() async {
        guard !vm.ticker.trimmingCharacters(in: .whitespaces).isEmpty else {
            compareError = "Enter a ticker first."; return
        }
        isComparing = true; compareError = nil
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        do {
            compareResult = try await BacktestService().runCompare(
                ticker: vm.ticker,
                startDate: df.string(from: vm.startDate),
                endDate: df.string(from: vm.endDate))
            Haptics.success()
            showCompare = true
        } catch {
            Haptics.error()
            compareError = error.localizedDescription
        }
        isComparing = false
    }

    private func fmt(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: date)
    }

    private func fetchSuggestions() async {
        let query = vm.ticker.trimmingCharacters(in: .whitespaces)
        guard query.count >= 1 else { suggestions = []; return }
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }
        do {
            let results = try await BacktestService().searchSymbols(query: query)
            guard !Task.isCancelled else { return }
            suggestions = results
        } catch {
            suggestions = []
        }
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.backtrRed).font(.system(size: 13))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.backtrRed)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backtrRed.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                Haptics.selection()
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
                                    }
                                    Spacer()
                                    if selected.id == s.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.backtrAccent)
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(14)
                                .background(selected.id == s.id ? Color.backtrAccent.opacity(0.12) : Color.backtrCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(selected.id == s.id ? Color.backtrAccent : Color.backtrBorder,
                                            lineWidth: selected.id == s.id ? 1 : 0.5))
                            }
                            .buttonStyle(.plain)
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

#Preview { ContentView(showHome: .constant(false)) }
