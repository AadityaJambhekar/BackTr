import Foundation

struct BacktestRequest: Encodable {
    let ticker: String
    let start_date: String
    let end_date: String
    let strategy: String
    let initial_capital: Double
}

struct CompareRequest: Encodable {
    let ticker: String
    let start_date: String
    let end_date: String
    let initial_capital: Double
}

struct BacktestResponse: Decodable {
    let ticker: String
    let strategy: String
    let start_date: String
    let end_date: String
    let metrics: Metrics
    let price_curve: [PricePoint]
    let equity_curve: [EquityPoint]
    let bah_curve: [BAHPoint]
    let trade_log: [Trade]
}

struct CompareResponse: Decodable {
    let ticker: String
    let start_date: String
    let end_date: String
    let bah_return_pct: Double
    let results: [CompareResult]
}

struct CompareResult: Decodable, Identifiable {
    var id: String { strategy }
    let strategy: String
    let strategy_name: String
    let total_return_pct: Double
    let bah_return_pct: Double
    let alpha: Double
    let sharpe_ratio: Double
    let win_rate_pct: Double
    let max_drawdown_pct: Double
    let num_trades: Int
    let final_equity: Double
}

struct Metrics: Decodable {
    let total_return_pct: Double
    let bah_return_pct: Double
    let max_drawdown_pct: Double
    let sharpe_ratio: Double
    let num_trades: Int
    let win_rate_pct: Double
    let final_equity: Double
    let initial_capital: Double

    var alpha: Double { total_return_pct - bah_return_pct }
}

struct PricePoint: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let price: Double
}

struct EquityPoint: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let equity: Double
}

struct BAHPoint: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let bah: Double
}

struct Trade: Decodable, Identifiable {
    var id: String { entry_date + exit_date }
    let entry_date: String
    let exit_date: String
    let entry_price: Double
    let exit_price: Double
    let pnl_pct: Double
    let result: String

    func dollarPnl(capital: Double) -> Double {
        capital * pnl_pct / 100
    }
}

struct Strategy: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
}

let availableStrategies: [Strategy] = [
    Strategy(id: "macd",           name: "MACD",                     description: "12/26/9 crossover signal"),
    Strategy(id: "rsi",            name: "RSI",                      description: "Mean-reversion, period 14"),
    Strategy(id: "bollinger",      name: "Bollinger Bands",          description: "20-day bands ±2σ"),
    Strategy(id: "moving_average", name: "MA Crossover",             description: "20/50-day SMA cross"),
    Strategy(id: "breakout",       name: "Breakout",                 description: "20-day channel high/low"),
    Strategy(id: "ensemble",       name: "Ensemble",                 description: "Majority vote across all 5"),
]

let quickTickers = ["SPY", "AAPL", "TSLA", "NVDA", "MSFT"]
