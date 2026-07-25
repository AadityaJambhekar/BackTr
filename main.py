from __future__ import annotations
import logging
from datetime import date
from typing import Literal

import yfinance as yf
import pandas as pd
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from strategies import STRATEGY_MAP
from backtest import run_backtest

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Backtest API", version="1.0.0")

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

StrategyName = Literal["macd", "rsi", "bollinger", "moving_average", "breakout", "ensemble"]


class BacktestRequest(BaseModel):
    ticker: str = Field(..., example="AAPL")
    start_date: str = Field(..., example="2020-01-01")
    end_date: str = Field(..., example="2024-01-01")
    strategy: StrategyName = Field(..., example="macd")
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


def _run(ticker, start_date, end_date, strategy, initial_capital):
    ticker = ticker.upper().strip()
    try:
        s, e = date.fromisoformat(start_date), date.fromisoformat(end_date)
    except ValueError:
        raise HTTPException(422, "Dates must be YYYY-MM-DD.")
    if s >= e:
        raise HTTPException(422, "start_date must be before end_date.")
    yesterday = date.today() - __import__('datetime').timedelta(days=7)
    if e > yesterday:
        e = yesterday
    if strategy not in STRATEGY_MAP:
        raise HTTPException(422, f"Unknown strategy. Valid: {list(STRATEGY_MAP)}")
    df = _fetch(ticker, str(s), str(e))
    result = run_backtest(df, STRATEGY_MAP[strategy](df), initial_capital)
    return {"ticker": ticker, "start_date": start_date, "end_date": end_date, "strategy": strategy, **result}


@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/strategies")
def list_strategies():
    return {"strategies": [
        {"id": "macd",           "description": "MACD crossover (12/26/9)"},
        {"id": "rsi",            "description": "RSI mean-reversion (period 14, buy<30, sell>70)"},
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
