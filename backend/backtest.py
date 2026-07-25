import pandas as pd
import numpy as np


def run_backtest(df, signals, initial_capital=10_000.0):
    close = df["Close"].copy()

    # Build position series
    position = pd.Series(0, index=close.index, dtype=float)
    in_pos = False
    for i in range(len(signals)):
        sig = signals.iloc[i]
        if sig == 1 and not in_pos:
            in_pos = True
        elif sig == -1 and in_pos:
            in_pos = False
        position.iloc[i] = 1.0 if in_pos else 0.0

    daily_returns = close.pct_change().fillna(0)
    strategy_returns = daily_returns * position.shift(1).fillna(0)

    equity = initial_capital * (1 + strategy_returns).cumprod()
    equity.iloc[0] = initial_capital

    bah_equity = initial_capital * (1 + daily_returns).cumprod()
    bah_equity.iloc[0] = initial_capital

    total_return = float((equity.iloc[-1] / initial_capital - 1) * 100)
    bah_total_return = float((bah_equity.iloc[-1] / initial_capital - 1) * 100)

    rolling_max = equity.cummax()
    max_drawdown = float(((equity - rolling_max) / rolling_max).min() * 100)

    sharpe = float((strategy_returns.mean() / strategy_returns.std()) * np.sqrt(252)) \
        if strategy_returns.std() > 0 else 0.0

    # Trade log
    trades = []
    entry_price = entry_date = None
    for i in range(len(signals)):
        sig = signals.iloc[i]
        date = signals.index[i]
        price = float(close.iloc[i])
        if sig == 1 and entry_price is None:
            entry_price, entry_date = price, date
        elif sig == -1 and entry_price is not None:
            pnl = (price - entry_price) / entry_price * 100
            trades.append({"entry_date": str(entry_date.date()), "exit_date": str(date.date()),
                           "entry_price": round(entry_price, 4), "exit_price": round(price, 4),
                           "pnl_pct": round(pnl, 2), "result": "win" if pnl > 0 else "loss"})
            entry_price = entry_date = None

    if entry_price is not None:
        price = float(close.iloc[-1])
        pnl = (price - entry_price) / entry_price * 100
        trades.append({"entry_date": str(entry_date.date()), "exit_date": str(close.index[-1].date()),
                       "entry_price": round(entry_price, 4), "exit_price": round(price, 4),
                       "pnl_pct": round(pnl, 2), "result": "win" if pnl > 0 else "loss"})

    num_trades = len(trades)
    win_rate = round(sum(1 for t in trades if t["result"] == "win") / num_trades * 100, 1) \
        if num_trades > 0 else 0.0

    def resample(series, label):
        step = max(1, len(series) // 300)
        s = series.iloc[::step]
        return [{"date": str(d.date()), label: round(float(v), 4)}
                for d, v in zip(s.index, s.values) if not np.isnan(v)]

    return {
        "metrics": {
            "total_return_pct": round(total_return, 2),
            "bah_return_pct": round(bah_total_return, 2),
            "max_drawdown_pct": round(max_drawdown, 2),
            "sharpe_ratio": round(sharpe, 2),
            "num_trades": num_trades,
            "win_rate_pct": win_rate,
            "final_equity": round(float(equity.iloc[-1]), 2),
            "initial_capital": initial_capital,
        },
        "price_curve": resample(close, "price"),
        "equity_curve": resample(equity, "equity"),
        "bah_curve": resample(bah_equity, "bah"),
        "trade_log": trades,
    }
