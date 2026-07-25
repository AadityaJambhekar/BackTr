"""
Trading strategy signal generators.

Each public *_signals() function receives a DataFrame with OHLCV columns and a
DatetimeIndex, and returns a pandas Series of *trade events*:
    +1 = enter long (buy)
    -1 = exit long  (sell)
     0 = nothing

Internally we also compute *stance* Series (+1 = bullish now, -1 = bearish/flat)
which the Ensemble uses so it can vote on *current regime* rather than on the
exact same bar as a crossover event.
"""

import pandas as pd
import numpy as np


def _ema(series, span):
    return series.ewm(span=span, adjust=False).mean()

def _sma(series, window):
    return series.rolling(window=window).mean()

def _stance_to_events(stance):
    events = pd.Series(0, index=stance.index, dtype=float)
    prev = stance.shift(1)
    events[(stance == 1) & (prev != 1)] = 1
    events[(stance != 1) & (prev == 1)] = -1
    return events


def _macd_stance(df):
    close = df["Close"]
    macd_line = _ema(close, 12) - _ema(close, 26)
    signal_line = _ema(macd_line, 9)
    return pd.Series(np.where(macd_line > signal_line, 1, -1), index=df.index, dtype=float)

def _rsi_stance(df):
    close = df["Close"]
    delta = close.diff()
    gain = delta.clip(lower=0).rolling(14).mean()
    loss = (-delta.clip(upper=0)).rolling(14).mean()
    rs = gain / loss.replace(0, np.nan)
    rsi = 100 - (100 / (1 + rs))
    stance = pd.Series(0, index=df.index, dtype=float)
    stance[rsi < 30] = 1
    stance[rsi > 70] = -1
    return stance.replace(0, np.nan).ffill().fillna(-1)

def _bollinger_stance(df):
    close = df["Close"]
    mid = _sma(close, 20)
    std = close.rolling(20).std()
    stance = pd.Series(0, index=df.index, dtype=float)
    stance[close < mid - 2 * std] = 1
    stance[close > mid + 2 * std] = -1
    return stance.replace(0, np.nan).ffill().fillna(-1)

def _ma_stance(df):
    close = df["Close"]
    return pd.Series(np.where(_sma(close, 20) > _sma(close, 50), 1, -1), index=df.index, dtype=float)

def _breakout_stance(df):
    close = df["Close"]
    stance = pd.Series(0, index=df.index, dtype=float)
    stance[close > close.rolling(20).max().shift(1)] = 1
    stance[close < close.rolling(20).min().shift(1)] = -1
    return stance.replace(0, np.nan).ffill().fillna(-1)


def macd_signals(df):
    return _stance_to_events(_macd_stance(df))

def rsi_signals(df):
    return _stance_to_events(_rsi_stance(df))

def bollinger_signals(df):
    return _stance_to_events(_bollinger_stance(df))

def moving_average_signals(df):
    return _stance_to_events(_ma_stance(df))

def breakout_signals(df):
    return _stance_to_events(_breakout_stance(df))

def ensemble_signals(df):
    vote = sum([_macd_stance(df), _rsi_stance(df), _bollinger_stance(df),
                _ma_stance(df), _breakout_stance(df)])
    ens_stance = pd.Series(np.where(vote >= 1, 1, -1), index=df.index, dtype=float)
    return _stance_to_events(ens_stance)


STRATEGY_MAP = {
    "macd":             macd_signals,
    "rsi":              rsi_signals,
    "bollinger":        bollinger_signals,
    "moving_average":   moving_average_signals,
    "breakout":         breakout_signals,
    "ensemble":         ensemble_signals,
}
