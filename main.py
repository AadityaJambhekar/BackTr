from __future__ import annotations
import logging
from datetime import date, timedelta
from typing import Literal

import yfinance as yf
import pandas as pd
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from strategies import STRATEGY_MAP
from backtest import run_backtest, benchmark_curve, generate_insight, walk_forward_windows, _resample

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Backtest API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

StrategyName = Literal["macd", "rsi", "bollinger", "moving_average", "breakout", "ensemble"]

STRATEGY_NAMES = {
    "macd": "MACD",
    "rsi": "RSI",
    "bollinger": "Bollinger Bands",
    "moving_average": "MA Crossover",
    "breakout": "Breakout",
    "ensemble": "Ensemble",
}


class BacktestRequest(BaseModel):
    ticker: str = Field(..., example="AAPL")
    start_date: str = Field(..., example="2020-01-01")
    end_date: str = Field(..., example="2024-01-01")
    strategy: StrategyName = Field(..., example="macd")
    initial_capital: float = Field(default=10_000.0, ge=100)


class CompareRequest(BaseModel):
    ticker: str = Field(..., example="AAPL")
    start_date: str = Field(..., example="2020-01-01")
    end_date: str = Field(..., example="2024-01-01")
    initial_capital: float = Field(default=10_000.0, ge=100)


def _fetch(ticker, start, end):
    try:
        df = yf.download(ticker, start=start, end=end, auto_adjust=True, progress=False)
    except Exception as e:
        raise HTTPException(502, f"Data fetch failed: {e}")
    if df.empty:
        raise HTTPException(404, f"No data for '{ticker}' in {start}–{end}. Check the ticker and date range.")
    if isinstance(df.columns, pd.MultiIndex):
        df.columns = df.columns.get_level_values(0)
    if len(df) < 60:
        raise HTTPException(422, f"Date range too short ({len(df)} days). Need at least 60 trading days.")
    return df


def _cap_end(e: date) -> date:
    cutoff = date.today() - timedelta(days=7)
    return min(e, cutoff)


def _parse_dates(start_date, end_date):
    try:
        s, e = date.fromisoformat(start_date), date.fromisoformat(end_date)
    except ValueError:
        raise HTTPException(422, "Dates must be YYYY-MM-DD.")
    e = _cap_end(e)
    if s >= e:
        raise HTTPException(422, "start_date must be before end_date.")
    return s, e


def _run(ticker, start_date, end_date, strategy, initial_capital):
    ticker = ticker.upper().strip()
    s, e = _parse_dates(start_date, end_date)
    if strategy not in STRATEGY_MAP:
        raise HTTPException(422, f"Unknown strategy. Valid: {list(STRATEGY_MAP)}")
    df = _fetch(ticker, str(s), str(e))
    signals = STRATEGY_MAP[strategy](df)
    result = run_backtest(df, signals, initial_capital)
    result["walk_forward"] = walk_forward_windows(df, signals, initial_capital)

    if ticker == "SPY":
        spy_equity, spy_return_pct = benchmark_curve(df["Close"], initial_capital)
    else:
        try:
            spy_df = _fetch("SPY", str(s), str(e))
            spy_equity, spy_return_pct = benchmark_curve(spy_df["Close"], initial_capital)
        except HTTPException:
            spy_equity, spy_return_pct = None, None

    result["metrics"]["spy_return_pct"] = spy_return_pct
    result["spy_curve"] = _resample(spy_equity, "spy") if spy_equity is not None else []

    strategy_name = STRATEGY_NAMES.get(strategy, strategy)
    result["ai_insight"] = generate_insight(result["metrics"], strategy_name)

    return {"ticker": ticker, "start_date": start_date, "end_date": end_date, "strategy": strategy, **result}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/symbols/search")
def search_symbols(q: str = Query(..., min_length=1, max_length=20)):
    query = q.strip()
    if not query:
        return {"results": []}
    try:
        quotes = yf.Search(query, max_results=8).quotes
    except Exception as e:
        logger.warning(f"Symbol search failed for '{query}': {e}")
        return {"results": []}

    results, seen = [], set()
    for item in quotes:
        symbol = item.get("symbol")
        quote_type = item.get("quoteType")
        if not symbol or quote_type not in ("EQUITY", "ETF") or symbol in seen:
            continue
        seen.add(symbol)
        results.append({"symbol": symbol, "name": item.get("shortname") or item.get("longname") or ""})
    return {"results": results}


@app.get("/strategies")
def list_strategies():
    return {"strategies": [
        {"id": "macd",           "description": "MACD crossover (12/26/9)"},
        {"id": "rsi",            "description": "RSI mean-reversion (period 14)"},
        {"id": "bollinger",      "description": "Bollinger Bands (20-day, ±2σ)"},
        {"id": "moving_average", "description": "SMA crossover (fast 20, slow 50)"},
        {"id": "breakout",       "description": "Channel breakout (20-day high/low)"},
        {"id": "ensemble",       "description": "Majority vote across all 5 strategies"},
    ]}


@app.post("/backtest")
def backtest_post(req: BacktestRequest):
    return _run(req.ticker, req.start_date, req.end_date, req.strategy, req.initial_capital)


@app.get("/backtest")
def backtest_get(
    ticker: str = Query(...),
    start_date: str = Query(...),
    end_date: str = Query(...),
    strategy: StrategyName = Query(...),
    initial_capital: float = Query(default=10_000.0),
):
    return _run(ticker, start_date, end_date, strategy, initial_capital)


@app.post("/compare")
def compare_post(req: CompareRequest):
    ticker = req.ticker.upper().strip()
    s, e = _parse_dates(req.start_date, req.end_date)
    df = _fetch(ticker, str(s), str(e))

    results = []
    for strategy_id, signal_fn in STRATEGY_MAP.items():
        try:
            r = run_backtest(df, signal_fn(df), req.initial_capital)
            m = r["metrics"]
            results.append({
                "strategy": strategy_id,
                "strategy_name": STRATEGY_NAMES.get(strategy_id, strategy_id),
                "total_return_pct": m["total_return_pct"],
                "bah_return_pct": m["bah_return_pct"],
                "alpha": m["total_return_pct"] - m["bah_return_pct"],
                "sharpe_ratio": m["sharpe_ratio"],
                "win_rate_pct": m["win_rate_pct"],
                "max_drawdown_pct": m["max_drawdown_pct"],
                "num_trades": m["num_trades"],
                "final_equity": m["final_equity"],
            })
        except Exception:
            pass

    results.sort(key=lambda x: x["total_return_pct"], reverse=True)
    bah = results[0]["bah_return_pct"] if results else 0

    return {
        "ticker": ticker,
        "start_date": req.start_date,
        "end_date": req.end_date,
        "bah_return_pct": bah,
        "results": results,
    }
