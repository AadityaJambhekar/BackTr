import Foundation

enum BacktestError: LocalizedError {
    case badURL
    case networkError(Error)
    case badStatus(Int, String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid API URL."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .badStatus(let code, let msg): return "Server error \(code): \(msg)"
        case .decodingError(let e): return "Response parse error: \(e.localizedDescription)"
        }
    }
}

@MainActor
class BacktestService: ObservableObject {

    // ── Your Railway URL ─────────────────────────────────────────────────
    static var baseURL = "https://backtr-production.up.railway.app"
    // ────────────────────────────────────────────────────────────────────

    private func post<Req: Encodable, Res: Decodable>(path: String, body: Req) async throws -> Res {
        guard let url = URL(string: "\(Self.baseURL)\(path)") else { throw BacktestError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do { (data, response) = try await URLSession.shared.data(for: request) }
        catch { throw BacktestError.networkError(error) }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw BacktestError.badStatus(http.statusCode,
                String(data: data, encoding: .utf8) ?? "Unknown error")
        }

        do { return try JSONDecoder().decode(Res.self, from: data) }
        catch { throw BacktestError.decodingError(error) }
    }

    func runBacktest(ticker: String, startDate: String, endDate: String,
                     strategy: String, initialCapital: Double = 10_000) async throws -> BacktestResponse {
        try await post(path: "/backtest", body: BacktestRequest(
            ticker: ticker.uppercased().trimmingCharacters(in: .whitespaces),
            start_date: startDate, end_date: endDate,
            strategy: strategy, initial_capital: initialCapital))
    }

    func runCompare(ticker: String, startDate: String, endDate: String,
                    initialCapital: Double = 10_000) async throws -> CompareResponse {
        try await post(path: "/compare", body: CompareRequest(
            ticker: ticker.uppercased().trimmingCharacters(in: .whitespaces),
            start_date: startDate, end_date: endDate,
            initial_capital: initialCapital))
    }
}
