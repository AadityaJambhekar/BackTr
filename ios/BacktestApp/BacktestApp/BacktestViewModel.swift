import Foundation

@MainActor
class BacktestViewModel: ObservableObject {
    @Published var ticker: String = "AAPL"
    @Published var startDate: Date = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var selectedStrategy: Strategy = availableStrategies[0]
    @Published var initialCapital: String = "10000"
    @Published var isLoading = false
    @Published var result: BacktestResponse? = nil
    @Published var errorMessage: String? = nil

    private let service = BacktestService()
    private let df: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    func runBacktest() async {
        guard !ticker.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a ticker symbol."; return
        }
        isLoading = true; errorMessage = nil; result = nil
        do {
            result = try await service.runBacktest(
                ticker: ticker,
                startDate: df.string(from: startDate),
                endDate: df.string(from: endDate),
                strategy: selectedStrategy.id,
                initialCapital: Double(initialCapital) ?? 10_000)
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func reset() { result = nil; errorMessage = nil }
}
