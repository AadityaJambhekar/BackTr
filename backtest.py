import pandas as pd
import numpy as np

TRADE_COST_PCT = 0.001  # 0.1% per transaction (charged on both entry and exit)


def _resample(series, label):
    step = max(1, len(series) // 300)
    s = series.iloc[::step]
    return [{"date": str(d.date()), label: round(float(v), 4)}
            for d, v in zip(s.index, s.values) if not np.isnan(v)]


def benchmark_curve(close, initial_capital=10_000.0):
    """Equity curve + total return for a plain buy-and-hold of `close`."""
    daily_returns = close.pct_change().fillna(0)
    equity = initial_capital * (1 + daily_returns).cumprod()
    equity.iloc[0] = initial_capital
    total_return = float((equity.iloc[-1] / initial_capital - 1) * 100)
    return equity, round(total_return, 2)


def generate_insight(metrics, strategy_name):
    total = metrics["total_return_pct"]
    bah = metrics["bah_return_pct"]
    spy = metrics.get("spy_return_pct")
    alpha = total - bah
    sharpe = metrics["sharpe_ratio"]
    win_rate = metrics["win_rate_pct"]
    max_dd = metrics["max_drawdown_pct"]
    trades = metrics["num_trades"]
    exposure = metrics["exposure_pct"]
    profit_factor = metrics.get("profit_factor")

    parts = []

    spy_clause = ""
    if spy is not None:
        spy_diff = total - spy
        spy_clause = f" and {'outpaced' if spy_diff >= 0 else 'lagged'} SPY by {abs(spy_diff):.1f} points"

    if alpha > 5:
        parts.append(f"{strategy_name} beat buy-and-hold by {alpha:.1f} percentage points{spy_clause}.")
    elif alpha < -5:
        parts.append(f"{strategy_name} trailed buy-and-hold by {abs(alpha):.1f} percentage points{spy_clause}, "
                      "suggesting the signal added noise rather than edge over this period.")
    else:
        parts.append(f"{strategy_name} performed roughly in line with buy-and-hold ({alpha:+.1f}pp), "
                      "so market direction — not the strategy's timing — was the main driver of returns.")

    if sharpe >= 1.5:
        parts.append(f"A Sharpe ratio of {sharpe:.2f} indicates strong risk-adjusted returns.")
    elif sharpe >= 0.5:
        parts.append(f"A Sharpe ratio of {sharpe:.2f} is respectable but not exceptional on a risk-adjusted basis.")
    elif sharpe > 0:
        parts.append(f"A low Sharpe ratio of {sharpe:.2f} means returns barely compensated for the volatility taken on.")
    else:
        parts.append(f"A negative Sharpe ratio ({sharpe:.2f}) means the strategy lost money on a risk-adjusted basis.")

    if trades == 0:
        parts.append("No trades were completed in this window, so the strategy never generated a signal to act on.")
    else:
        pf_desc = f"a profit factor of {profit_factor:.2f}" if profit_factor is not None else "no losing trades"
        if win_rate >= 55:
            parts.append(f"It won {win_rate:.0f}% of its {trades} trades with {pf_desc}, "
                          "showing the entry/exit logic was well-timed.")
        elif win_rate <= 40:
            parts.append(f"It only won {win_rate:.0f}% of its {trades} trades ({pf_desc}), "
                          "which points to a signal that struggles to time entries and exits.")
        else:
            parts.append(f"Win rate came in near coin-flip at {win_rate:.0f}% across {trades} trades ({pf_desc}).")

    if max_dd <= -25:
        parts.append(f"Drawdowns reached {max_dd:.1f}%, a level that would be hard for most investors to sit through.")
    elif max_dd <= -10:
        parts.append(f"Max drawdown was a moderate {max_dd:.1f}%.")
    else:
        parts.append(f"Drawdowns stayed shallow (max {max_dd:.1f}%), reflecting a conservative risk profile.")

    if exposure < 40 and alpha >= 0:
        parts.append(f"Notably, it achieved this while only being in the market {exposure:.0f}% of the time — capital efficient.")
    elif exposure > 85 and alpha < 0:
        parts.append(f"It was in the market {exposure:.0f}% of the time yet still underperformed simply holding, "
                      "so the entry/exit signals subtracted value rather than adding it.")

    return " ".join(parts)


def walk_forward_windows(df, signals, initial_capital=10_000.0, n_windows=4):
    """
    Split the already-computed strategy signals into N consecutive, non-overlapping
    windows and re-run the backtest independently (fresh capital) in each one.

    This does NOT re-fit or re-optimize anything — the strategies here have fixed
    parameters — it just shows whether the strategy's overall return came from
    consistent performance across the whole period, or from one lucky stretch.
    """
    n = len(df)
    if n < n_windows * 30:
        return []

    edges = [round(i * n / n_windows) for i in range(n_windows + 1)]
    windows = []
    for i in range(n_windows):
        lo, hi = edges[i], edges[i + 1]
        if hi - lo < 20:
            continue
        sub_df = df.iloc[lo:hi]
        sub_signals = signals.iloc[lo:hi]
        try:
            sub_result = run_backtest(sub_df, sub_signals, initial_capital)
        except Exception:
            continue
        m = sub_result["metrics"]
        windows.append({
            "start_date": str(sub_df.index[0].date()),
            "end_date": str(sub_df.index[-1].date()),
            "total_return_pct": m["total_return_pct"],
            "bah_return_pct": m["bah_return_pct"],
            "num_trades": m["num_trades"],
            "win_rate_pct": m["win_rate_pct"],
        })
    return windows


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

    # Transaction costs: charged on the day the position flips (entry or exit)
    position_changes = position.diff().fillna(0).abs()
    strategy_returns = strategy_returns - position_changes * TRADE_COST_PCT

    equity = initial_capital * (1 + strategy_returns).cumprod()
    equity.iloc[0] = initial_capital

    bah_equity, bah_total_return = benchmark_curve(close, initial_capital)

    total_return = float((equity.iloc[-1] / initial_capital - 1) * 100)

    rolling_max = equity.cummax()
    max_drawdown = float(((equity - rolling_max) / rolling_max).min() * 100)

    sharpe = float((strategy_returns.mean() / strategy_returns.std()) * np.sqrt(252)) \
        if strategy_returns.std() > 0 else 0.0

    downside_returns = strategy_returns[strategy_returns < 0]
    downside_std = downside_returns.std()
    sortino = float((strategy_returns.mean() / downside_std) * np.sqrt(252)) \
        if downside_std and downside_std > 0 else 0.0

    num_days = (close.index[-1] - close.index[0]).days
    years = num_days / 365.25 if num_days > 0 else 0
    cagr = float(((equity.iloc[-1] / initial_capital) ** (1 / years) - 1) * 100) \
        if years > 0 and equity.iloc[-1] > 0 else 0.0

    calmar = float(cagr / abs(max_drawdown)) if max_drawdown != 0 else 0.0

    exposure_pct = float(position.mean() * 100)

    # Trade log (prices adjusted for the round-trip transaction cost)
    trades = []
    entry_price = entry_date = None
    for i in range(len(signals)):
        sig = signals.iloc[i]
        d = signals.index[i]
        price = float(close.iloc[i])
        if sig == 1 and entry_price is None:
            entry_price, entry_date = price, d
        elif sig == -1 and entry_price is not None:
            adj_entry = entry_price * (1 + TRADE_COST_PCT)
            adj_exit = price * (1 - TRADE_COST_PCT)
            pnl = (adj_exit - adj_entry) / adj_entry * 100
            duration_days = (d - entry_date).days
            trades.append({"entry_date": str(entry_date.date()), "exit_date": str(d.date()),
                           "entry_price": round(entry_price, 4), "exit_price": round(price, 4),
                           "pnl_pct": round(pnl, 2), "result": "win" if pnl > 0 else "loss",
                           "duration_days": duration_days})
            entry_price = entry_date = None

    if entry_price is not None:
        price = float(close.iloc[-1])
        exit_date = close.index[-1]
        adj_entry = entry_price * (1 + TRADE_COST_PCT)
        adj_exit = price * (1 - TRADE_COST_PCT)
        pnl = (adj_exit - adj_entry) / adj_entry * 100
        duration_days = (exit_date - entry_date).days
        trades.append({"entry_date": str(entry_date.date()), "exit_date": str(exit_date.date()),
                       "entry_price": round(entry_price, 4), "exit_price": round(price, 4),
                       "pnl_pct": round(pnl, 2), "result": "win" if pnl > 0 else "loss",
                       "duration_days": duration_days})

    num_trades = len(trades)
    win_rate = round(sum(1 for t in trades if t["result"] == "win") / num_trades * 100, 1) \
        if num_trades > 0 else 0.0

    avg_trade_duration_days = round(sum(t["duration_days"] for t in trades) / num_trades, 1) \
        if num_trades > 0 else 0.0

    gross_win = sum(t["pnl_pct"] for t in trades if t["pnl_pct"] > 0)
    gross_loss = abs(sum(t["pnl_pct"] for t in trades if t["pnl_pct"] < 0))
    profit_factor = round(gross_win / gross_loss, 2) if gross_loss > 0 else None

    metrics = {
        "total_return_pct": round(total_return, 2),
        "bah_return_pct": bah_total_return,
        "max_drawdown_pct": round(max_drawdown, 2),
        "sharpe_ratio": round(sharpe, 2),
        "sortino_ratio": round(sortino, 2),
        "calmar_ratio": round(calmar, 2),
        "cagr_pct": round(cagr, 2),
        "profit_factor": profit_factor,
        "avg_trade_duration_days": avg_trade_duration_days,
        "exposure_pct": round(exposure_pct, 2),
        "num_trades": num_trades,
        "win_rate_pct": win_rate,
        "final_equity": round(float(equity.iloc[-1]), 2),
        "initial_capital": initial_capital,
    }

    return {
        "metrics": metrics,
        "price_curve": _resample(close, "price"),
        "equity_curve": _resample(equity, "equity"),
        "bah_curve": _resample(bah_equity, "bah"),
        "trade_log": trades,
    }
