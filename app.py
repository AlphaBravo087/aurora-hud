"""
AI Investment Intelligence Dashboard
=====================================
A single-file Streamlit application that fetches historical market data,
computes technical indicators and risk metrics, generates AI-driven
conviction scores, and presents interactive charts with investment
suggestions.

Run:
    pip install -r requirements.txt
    streamlit run app.py
"""

from __future__ import annotations

import datetime as dt
from typing import Dict, List

import numpy as np
import pandas as pd
import plotly.graph_objects as go
import streamlit as st
import yfinance as yf
from sklearn.linear_model import LinearRegression

# ---------------------------------------------------------------------------
# Page configuration & theme
# ---------------------------------------------------------------------------

st.set_page_config(
    page_title="AI Investment Intelligence Dashboard",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded",
)

_DARK_CSS = """
<style>
    /* Dark-mode overrides */
    .main { background-color: #0e1117; }
    .stApp { background-color: #0e1117; }
    h1, h2, h3, h4 { color: #e0e0e0; }

    /* Risk badges */
    .badge-low  { background:#1b5e20; color:#fff; padding:3px 10px;
                   border-radius:12px; font-size:0.8rem; font-weight:600; }
    .badge-med  { background:#e65100; color:#fff; padding:3px 10px;
                   border-radius:12px; font-size:0.8rem; font-weight:600; }
    .badge-high { background:#b71c1c; color:#fff; padding:3px 10px;
                   border-radius:12px; font-size:0.8rem; font-weight:600; }

    /* Conviction bar */
    .conv-bar { height:12px; border-radius:6px; }

    /* Disclaimer box */
    .disclaimer-box {
        background: #1a1a2e; border-left: 4px solid #e63946;
        padding: 14px 18px; border-radius: 6px; margin-bottom: 18px;
        font-size: 0.85rem; color: #ccc; line-height: 1.5;
    }

    /* Card styling */
    .metric-card {
        background: #1a1a2e; border-radius: 10px; padding: 18px;
        margin-bottom: 12px; border: 1px solid #2a2a4a;
    }
</style>
"""
st.markdown(_DARK_CSS, unsafe_allow_html=True)

# ---------------------------------------------------------------------------
# Sidebar — disclaimer & user inputs
# ---------------------------------------------------------------------------

st.sidebar.markdown(
    '<div class="disclaimer-box">'
    "<strong>⚠️ Financial Disclaimer</strong><br>"
    "This is <b>not</b> financial advice. AI-generated guesses are for "
    "<b>educational purposes only</b>. Past performance does not guarantee "
    "future results. Always consult a licensed financial advisor before "
    "making investment decisions."
    "</div>",
    unsafe_allow_html=True,
)

st.sidebar.title("Dashboard Controls")

default_tickers = "AAPL, MSFT, TSLA, GOOGL, AMZN, SPY"
ticker_input: str = st.sidebar.text_input(
    "Enter tickers (comma-separated)", value=default_tickers
)
tickers: List[str] = [t.strip().upper() for t in ticker_input.split(",") if t.strip()]

years_back: int = st.sidebar.slider("Years of history", 1, 10, 5)
end_date = dt.date.today()
start_date = end_date - dt.timedelta(days=years_back * 365)

st.sidebar.markdown("---")
st.sidebar.markdown(
    "**Built with** Streamlit · yfinance · Plotly · scikit-learn"
)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

st.title("🧠 AI Investment Intelligence Dashboard")
st.caption(
    "Technical analysis, risk metrics & AI conviction scores — "
    "powered by machine learning."
)

# ---------------------------------------------------------------------------
# Data ingestion
# ---------------------------------------------------------------------------


@st.cache_data(show_spinner="Fetching market data …", ttl=900)
def fetch_data(
    symbols: List[str], start: dt.date, end: dt.date
) -> Dict[str, pd.DataFrame]:
    """Download OHLCV data for each ticker via *yfinance*."""
    frames: Dict[str, pd.DataFrame] = {}
    for sym in symbols:
        try:
            df = yf.download(
                sym, start=start, end=end, progress=False, auto_adjust=True
            )
            if df is not None and not df.empty:
                # Flatten MultiIndex columns if present
                if isinstance(df.columns, pd.MultiIndex):
                    df.columns = df.columns.get_level_values(0)
                frames[sym] = df
        except Exception:
            pass
    return frames


if not tickers:
    st.warning("Please enter at least one ticker symbol.")
    st.stop()

with st.spinner("Downloading historical data …"):
    data = fetch_data(tickers, start_date, end_date)

if not data:
    st.error("Could not retrieve data for any of the provided tickers.")
    st.stop()

# ---------------------------------------------------------------------------
# Analysis helpers — technical indicators
# ---------------------------------------------------------------------------


def compute_rsi(series: pd.Series, period: int = 14) -> pd.Series:
    """Relative Strength Index."""
    delta = series.diff()
    gain = delta.clip(lower=0)
    loss = -delta.clip(upper=0)
    avg_gain = gain.ewm(com=period - 1, min_periods=period).mean()
    avg_loss = loss.ewm(com=period - 1, min_periods=period).mean()
    rs = avg_gain / avg_loss
    return 100 - (100 / (1 + rs))


def compute_macd(
    series: pd.Series,
    fast: int = 12,
    slow: int = 26,
    signal: int = 9,
) -> pd.DataFrame:
    """MACD line, signal line, and histogram."""
    ema_fast = series.ewm(span=fast, adjust=False).mean()
    ema_slow = series.ewm(span=slow, adjust=False).mean()
    macd_line = ema_fast - ema_slow
    signal_line = macd_line.ewm(span=signal, adjust=False).mean()
    histogram = macd_line - signal_line
    return pd.DataFrame(
        {"MACD": macd_line, "Signal": signal_line, "Histogram": histogram}
    )


def moving_averages(series: pd.Series) -> pd.DataFrame:
    """50-day and 200-day simple moving averages."""
    return pd.DataFrame(
        {"MA50": series.rolling(50).mean(), "MA200": series.rolling(200).mean()}
    )


# ---------------------------------------------------------------------------
# Analysis helpers — risk metrics
# ---------------------------------------------------------------------------


def compute_beta(stock_returns: pd.Series, market_returns: pd.Series) -> float:
    """Beta relative to the market benchmark."""
    aligned = pd.concat([stock_returns, market_returns], axis=1).dropna()
    if len(aligned) < 30:
        return np.nan
    cov = np.cov(aligned.iloc[:, 0], aligned.iloc[:, 1])
    var_market = cov[1, 1]
    if var_market == 0:
        return np.nan
    return float(cov[0, 1] / var_market)


def compute_sharpe(returns: pd.Series, risk_free_annual: float = 0.04) -> float:
    """Annualised Sharpe ratio (assuming 252 trading days)."""
    excess = returns - risk_free_annual / 252
    if excess.std() == 0:
        return 0.0
    return float(np.sqrt(252) * excess.mean() / excess.std())


def compute_volatility(returns: pd.Series) -> float:
    """Annualised historical volatility."""
    return float(returns.std() * np.sqrt(252))


# ---------------------------------------------------------------------------
# Analysis helpers — AI conviction score
# ---------------------------------------------------------------------------


def conviction_score(close: pd.Series) -> int:
    """
    Generate a 1-100 conviction score using linear-regression slope on the
    most recent 60-day window plus a rolling-average trend comparison.
    """
    recent = close.dropna().tail(60)
    if len(recent) < 30:
        return 50  # neutral when insufficient data

    # Linear regression slope direction & magnitude
    x = np.arange(len(recent)).reshape(-1, 1)
    y = recent.values.reshape(-1, 1)
    model = LinearRegression().fit(x, y)
    slope = float(model.coef_[0][0])
    normalised_slope = np.clip(slope / (recent.mean() + 1e-9) * 100, -50, 50)

    # Rolling-average trend: 10-day vs 30-day
    ma10 = recent.rolling(10).mean().iloc[-1]
    ma30 = recent.rolling(30).mean().iloc[-1]
    trend_bonus = 10 if ma10 > ma30 else -10

    score = int(np.clip(50 + normalised_slope + trend_bonus, 1, 100))
    return score


# ---------------------------------------------------------------------------
# Risk-factor badge
# ---------------------------------------------------------------------------


def risk_badge(vol: float) -> str:
    """Return an HTML badge based on annualised volatility."""
    if vol < 0.20:
        return '<span class="badge-low">Low</span>'
    if vol < 0.40:
        return '<span class="badge-med">Medium</span>'
    return '<span class="badge-high">High</span>'


def risk_label(vol: float) -> str:
    """Plain-text risk label."""
    if vol < 0.20:
        return "Low"
    if vol < 0.40:
        return "Medium"
    return "High"


# ---------------------------------------------------------------------------
# Reasoning generator
# ---------------------------------------------------------------------------


def generate_reasoning(
    rsi_val: float, macd_hist: float, ma50: float, ma200: float, price: float
) -> str:
    """Build a concise reasoning string from indicator values."""
    parts: List[str] = []

    # RSI insight
    if rsi_val < 30:
        parts.append("RSI indicates oversold conditions")
    elif rsi_val > 70:
        parts.append("RSI indicates overbought conditions")
    else:
        parts.append(f"RSI is neutral ({rsi_val:.0f})")

    # MACD insight
    if macd_hist > 0:
        parts.append("MACD histogram is positive (bullish momentum)")
    else:
        parts.append("MACD histogram is negative (bearish momentum)")

    # MA crossover insight
    if ma50 > ma200:
        parts.append("50-day MA is above 200-day MA (golden cross / bullish trend)")
    elif ma200 > ma50:
        parts.append("200-day MA is above 50-day MA (death cross / bearish trend)")

    # Price vs MAs
    if price > ma50:
        parts.append("price is above the 50-day MA")
    else:
        parts.append("price is below the 50-day MA")

    return "; ".join(parts) + "."


# ---------------------------------------------------------------------------
# Run the Strategy Brain on every ticker
# ---------------------------------------------------------------------------

# Fetch market benchmark for beta calculation
market_key = "SPY"
if market_key not in data:
    spy_df = yf.download(market_key, start=start_date, end=end_date, progress=False, auto_adjust=True)
    if spy_df is not None and not spy_df.empty:
        if isinstance(spy_df.columns, pd.MultiIndex):
            spy_df.columns = spy_df.columns.get_level_values(0)
        data[market_key] = spy_df

market_returns = (
    data[market_key]["Close"].pct_change().dropna() if market_key in data else pd.Series(dtype=float)
)

results: List[Dict] = []

for ticker, df in data.items():
    close: pd.Series = df["Close"]
    returns = close.pct_change().dropna()

    rsi = compute_rsi(close)
    macd_df = compute_macd(close)
    mas = moving_averages(close)

    last_rsi = float(rsi.iloc[-1]) if not rsi.empty else 50.0
    last_macd_hist = float(macd_df["Histogram"].iloc[-1]) if not macd_df.empty else 0.0
    last_ma50 = float(mas["MA50"].iloc[-1]) if not mas["MA50"].isna().all() else float(close.iloc[-1])
    last_ma200 = float(mas["MA200"].iloc[-1]) if not mas["MA200"].isna().all() else float(close.iloc[-1])
    last_price = float(close.iloc[-1])

    vol = compute_volatility(returns)
    beta = compute_beta(returns, market_returns) if not market_returns.empty else np.nan
    sharpe = compute_sharpe(returns)
    score = conviction_score(close)

    reasoning = generate_reasoning(
        last_rsi, last_macd_hist, last_ma50, last_ma200, last_price
    )

    results.append(
        {
            "Ticker": ticker,
            "Price": last_price,
            "RSI": last_rsi,
            "MACD Hist": last_macd_hist,
            "MA50": last_ma50,
            "MA200": last_ma200,
            "Beta": beta,
            "Sharpe": sharpe,
            "Volatility": vol,
            "Conviction": score,
            "Risk": risk_label(vol),
            "Reasoning": reasoning,
            # Keep raw data for charts
            "_close": close,
            "_rsi": rsi,
            "_macd": macd_df,
            "_mas": mas,
            "_df": df,
        }
    )

# Sort by conviction score descending
results.sort(key=lambda r: r["Conviction"], reverse=True)

# ---------------------------------------------------------------------------
# Top Picks table
# ---------------------------------------------------------------------------

st.header("🏆 Top Picks")

picks_df = pd.DataFrame(
    [
        {
            "Ticker": r["Ticker"],
            "Price": f"${r['Price']:.2f}",
            "Conviction": r["Conviction"],
            "RSI": f"{r['RSI']:.1f}",
            "Sharpe": f"{r['Sharpe']:.2f}",
            "Beta": f"{r['Beta']:.2f}" if not np.isnan(r["Beta"]) else "N/A",
            "Volatility": f"{r['Volatility']:.1%}",
            "Risk": r["Risk"],
        }
        for r in results
    ]
)

st.dataframe(picks_df, use_container_width=True, hide_index=True)

# Reasoning cards
st.subheader("📝 Analysis Reasoning")
for r in results:
    badge_html = risk_badge(r["Volatility"])
    st.markdown(
        f'<div class="metric-card">'
        f"<strong>{r['Ticker']}</strong> &nbsp; {badge_html} &nbsp; "
        f"Conviction: <b>{r['Conviction']}/100</b><br>"
        f"<span style='color:#aaa'>{r['Reasoning']}</span>"
        f"</div>",
        unsafe_allow_html=True,
    )

# ---------------------------------------------------------------------------
# Interactive charts — one tab per ticker
# ---------------------------------------------------------------------------

st.header("📊 Interactive Charts")

chart_tabs = st.tabs([r["Ticker"] for r in results])

for tab, r in zip(chart_tabs, results):
    with tab:
        df = r["_df"]
        mas = r["_mas"]
        rsi_series = r["_rsi"]
        macd_df = r["_macd"]

        # --- Candlestick with MA overlays ---
        fig = go.Figure()

        fig.add_trace(
            go.Candlestick(
                x=df.index,
                open=df["Open"],
                high=df["High"],
                low=df["Low"],
                close=df["Close"],
                name="OHLC",
                increasing_line_color="#26a69a",
                decreasing_line_color="#ef5350",
            )
        )

        fig.add_trace(
            go.Scatter(
                x=mas.index, y=mas["MA50"], name="MA 50",
                line=dict(color="#42a5f5", width=1.5),
            )
        )
        fig.add_trace(
            go.Scatter(
                x=mas.index, y=mas["MA200"], name="MA 200",
                line=dict(color="#ffa726", width=1.5),
            )
        )

        # Buy/sell signal markers based on MA crossovers
        ma50 = mas["MA50"]
        ma200 = mas["MA200"]
        cross = (ma50 > ma200).astype(int).diff()
        buy_signals = cross[cross == 1].index
        sell_signals = cross[cross == -1].index

        if len(buy_signals) > 0:
            fig.add_trace(
                go.Scatter(
                    x=buy_signals,
                    y=df.loc[buy_signals, "Low"] * 0.97,
                    mode="markers",
                    marker=dict(symbol="triangle-up", size=12, color="#00e676"),
                    name="Buy Signal",
                )
            )

        if len(sell_signals) > 0:
            fig.add_trace(
                go.Scatter(
                    x=sell_signals,
                    y=df.loc[sell_signals, "High"] * 1.03,
                    mode="markers",
                    marker=dict(symbol="triangle-down", size=12, color="#ff1744"),
                    name="Sell Signal",
                )
            )

        fig.update_layout(
            title=f"{r['Ticker']} — Candlestick & Moving Averages",
            template="plotly_dark",
            xaxis_rangeslider_visible=False,
            height=500,
            margin=dict(l=40, r=20, t=50, b=30),
        )
        st.plotly_chart(fig, use_container_width=True)

        # --- RSI sub-chart ---
        col1, col2 = st.columns(2)

        with col1:
            fig_rsi = go.Figure()
            fig_rsi.add_trace(
                go.Scatter(
                    x=rsi_series.index, y=rsi_series, name="RSI",
                    line=dict(color="#ab47bc", width=1.5),
                )
            )
            fig_rsi.add_hline(y=70, line_dash="dash", line_color="#ef5350",
                              annotation_text="Overbought")
            fig_rsi.add_hline(y=30, line_dash="dash", line_color="#26a69a",
                              annotation_text="Oversold")
            fig_rsi.update_layout(
                title="RSI (14)",
                template="plotly_dark",
                height=300,
                margin=dict(l=40, r=20, t=50, b=30),
                yaxis=dict(range=[0, 100]),
            )
            st.plotly_chart(fig_rsi, use_container_width=True)

        with col2:
            fig_macd = go.Figure()
            fig_macd.add_trace(
                go.Scatter(
                    x=macd_df.index, y=macd_df["MACD"], name="MACD",
                    line=dict(color="#42a5f5", width=1.5),
                )
            )
            fig_macd.add_trace(
                go.Scatter(
                    x=macd_df.index, y=macd_df["Signal"], name="Signal",
                    line=dict(color="#ffa726", width=1.5),
                )
            )
            fig_macd.add_trace(
                go.Bar(
                    x=macd_df.index, y=macd_df["Histogram"], name="Histogram",
                    marker_color=np.where(
                        macd_df["Histogram"] >= 0, "#26a69a", "#ef5350"
                    ),
                )
            )
            fig_macd.update_layout(
                title="MACD (12 / 26 / 9)",
                template="plotly_dark",
                height=300,
                margin=dict(l=40, r=20, t=50, b=30),
            )
            st.plotly_chart(fig_macd, use_container_width=True)

        # --- Key metrics cards ---
        m1, m2, m3, m4 = st.columns(4)
        m1.metric("Conviction", f"{r['Conviction']}/100")
        m2.metric("RSI", f"{r['RSI']:.1f}")
        m3.metric("Sharpe", f"{r['Sharpe']:.2f}")
        m4.metric(
            "Beta",
            f"{r['Beta']:.2f}" if not np.isnan(r["Beta"]) else "N/A",
        )

# ---------------------------------------------------------------------------
# Ready to Invest? — Brokerage links
# ---------------------------------------------------------------------------

st.header("🚀 Ready to Invest?")
st.info(
    "The links below redirect you to established brokerage platforms where "
    "you can execute trades. This dashboard does **not** process any "
    "transactions."
)

brokerages = {
    "Interactive Brokers": "https://www.interactivebrokers.com",
    "Vanguard": "https://investor.vanguard.com",
    "Fidelity": "https://www.fidelity.com",
    "Charles Schwab": "https://www.schwab.com",
    "TD Ameritrade": "https://www.tdameritrade.com",
}

cols = st.columns(len(brokerages))
for col, (name, url) in zip(cols, brokerages.items()):
    col.link_button(f"Open {name}", url, use_container_width=True)

# ---------------------------------------------------------------------------
# Footer disclaimer
# ---------------------------------------------------------------------------

st.markdown("---")
st.markdown(
    '<div class="disclaimer-box">'
    "<strong>⚠️ Important Notice</strong><br>"
    "All analysis, scores, and suggestions presented on this dashboard are "
    "generated algorithmically and are intended <b>solely for educational "
    "and informational purposes</b>. They do not constitute investment "
    "advice, recommendations, or endorsements. Markets are inherently "
    "unpredictable; invest responsibly."
    "</div>",
    unsafe_allow_html=True,
)
