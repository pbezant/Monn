# Break Strategy Analysis & Issues

## Date: February 3, 2026
## Account Balance: $79.10 (started with ~$100)
## Performance: 0% Win Rate (0 wins, 10 losses in 7 days)
## Total Loss: -$20.86

---

## Strategy Logic Overview

The `break_strategy` attempts to:
1. Identify consolidation triangles using ZigZag indicators
2. Detect breakouts from these triangles
3. Enter trades in the direction of the breakout
4. Use the opposite trendline as stop-loss
5. Exit when price crosses back into the triangle

---

## Critical Issues Identified

### 1. **Overly Restrictive Entry Conditions**

#### Current Parameters (Aggressive Config):
- `min_zz_pct: 0.01` → Requires 1% ZigZag swing
- `vol_ratio_ma: 1.01` → Volume must be 1.01x above 5-period MA
- `kline_body_ratio: 1.0` → Candle body must equal mean body size
- `zz_dev: 1.0` → ZigZag deviation multiplier

**Problem:** In 8+ hours of live trading, **ZERO signals generated**. Market hasn't seen 1% swings combined with volume spikes.

---

### 2. **Signal Generation Logic Issues**

#### Entry Conditions (lines 156-229):
```python
# Must pass ALL checks:
✓ Volume > vol_ratio_ma * ma_vol
✓ ZigZag change > zz_dev * min_zz_ratio
✓ min_num_cuml candles since last ZigZag
✓ Candle body > kline_body_ratio * mean_body
✓ Valid uptrend & downtrend lines exist
✓ Triangle converging (delta_end < zz_dev * min_zz_ratio)
✓ Candle closes above/below trendline
✓ Price above/below 200 SMA
```

**Problem:** Too many filters mean signals are extremely rare. In volatile markets, this might work, but in normal conditions it catches nothing.

---

### 3. **200 SMA Filter is Deadly**

Lines 207 & 223:
```python
# BUY signal requires:
if last_kline["Close"] > ta.stream.SMA(chart["Close"], 200):
    # Enter BUY trade

# SELL signal requires:
if last_kline["Close"] < ta.stream.SMA(chart["Close"], 200):
    # Enter SELL trade
```

**Problem:** On 1-minute timeframe, 200 SMA is looking back 200 minutes (3.3 hours). This is a **SLOW** trend filter on a **FAST** timeframe. Price needs to be in a strong trend to trade, but the strategy is designed for breakouts during consolidation!

**Contradiction:** Strategy looks for triangles (consolidation) but requires trending prices (200 SMA filter).

---

### 4. **Early Exit Logic Too Aggressive**

Lines 258-292: `check_close_signal()`
```python
# Exits BUY when price crosses below uptrend line
# Exits SELL when price crosses above downtrend line
```

**Problem:** Exits too early on minor pullbacks. Combined with aggressive exit on red/green candles (75% wick check), trades get stopped out before reaching profit.

---

### 5. **Reverse Exit Logic**

Lines 294-332: `check_close_reverse()`
```python
# Closes BUY orders if new peak is lower than 3 peaks ago
# Closes SELL orders if new valley is higher than 3 valleys ago
```

**Problem:** This exits on the first sign of reversal, not allowing trades to run. With tight SL and early exits, trades have no breathing room.

---

## Why 0% Win Rate?

### Trade Lifecycle Problem:
1. **Entry too selective** → Rare signals (only in perfect setups)
2. **SL too tight** → Set at opposite trendline (often 1-2% away)
3. **Early exit on pullback** → Closes before profit
4. **200 SMA filter** → Prevents trades during consolidation (when triangles form!)
5. **Volume filter** → Requires volume spike during breakout

**Result:** Only trades in extremely specific conditions, then exits at first sign of trouble.

### The $19.11 EURUSD Loss:
- 4 trades, all losses
- Likely entered at breakouts, immediately reversed
- Stop losses hit before any profit taking
- Each loss ~$4.78 average

---

## Optimized Parameters

### Created: `configs/optimized_break_strategy.json`

| Parameter | Old Value | New Value | Reason |
|-----------|-----------|-----------|--------|
| `min_zz_pct` | 0.01 (1%) | **0.005 (0.5%)** | More signals, smaller swings |
| `zz_dev` | 1.0 | **0.8** | Slightly looser triangle filter |
| `ma_vol` | 5 | **10** | Smoother volume MA |
| `vol_ratio_ma` | 1.01 | **0.8** | Allow trades on 80% volume (more permissive) |
| `kline_body_ratio` | 1.0 | **0.5** | Allow smaller candle bodies |
| `max_sl_pct` | 2.0% | **1.5%** | Tighter risk management |
| `volume` | 0.1 | **0.01** | 10x smaller position (limit losses) |
| `months` | [1] | **[1, 2]** | Enable trading in February |

---

## Fundamental Strategy Flaws

### Issue #1: Timeframe Mismatch
- **1-minute charts** for entries
- **200 SMA** for trend filter (3.3 hour lookback)
- **Triangles** form during consolidation (no trend)

**Contradiction:** Can't have consolidation AND strong trend simultaneously.

### Issue #2: No Take Profit
- Only SL defined
- Exits rely on crosses/reversals
- No profit target = random exits

**Result:** Winners get closed early, losers run to SL.

### Issue #3: Over-optimization
Strategy has 10+ conditions that must ALL be true:
- ZigZag swings
- Volume above MA
- Candle body size
- Triangle convergence
- Trendline break
- 200 SMA position
- Candle wick ratios

**Result:** 8 hours = 0 signals.

---

## Recommendations

### Immediate Actions:
1. ✅ **Deploy optimized config** (more permissive parameters)
2. ✅ **Reduce position size** to 0.01 lots (limit damage while testing)
3. ⚠️ **Remove or adjust 200 SMA filter** (conflicts with consolidation strategy)

### Short-term Testing:
1. Run optimized config for 24 hours
2. Monitor signal generation (aim for 5-10 signals/day)
3. Track win rate (target >40%)
4. Analyze why losers lose (premature exits vs bad signals)

### Long-term Fixes:
1. **Add Take Profit logic** (1.5x risk:reward minimum)
2. **Remove 200 SMA filter** or change to 20 SMA
3. **Simplify entry conditions** (reduce from 10 to 5 filters)
4. **Add time-of-day filter** (trade only during London/NY sessions)
5. **Backtest properly** before live deployment

### Alternative Strategy:
Consider switching to:
- `ma_cross_strategy` (simpler, proven logic)
- `rsi_divergence` (less filters, clearer signals)
- `price_action` (pure price, no indicators)

---

## Next Steps

### Option A: Test Optimized Config
```bash
# Deploy new config
scp configs/optimized_break_strategy.json metatrader@192.168.1.201:Developement/Monn/configs/

# Restart bot with new config
ssh metatrader@192.168.1.201
taskkill /F /IM python.exe
cd Developement\Monn
start /B C:\Python311\python.exe main.py --mode live --exch mt5 --exch_cfg_file configs\exchange_config.json --sym_cfg_file configs\optimized_break_strategy.json
```

### Option B: Switch Strategy
Change to a simpler, more proven strategy with better backtested results.

### Option C: Paper Trade & Backtest
Stop live trading, backtest optimized parameters on historical data, verify >50% win rate before going live again.

---

## Risk Warning

**Current trajectory:** -$20.86 in 7 days = -$89/month = account blown in <1 month.

With optimized config:
- 10x smaller positions = 10x less loss
- More signals = more data for analysis
- Looser filters = catch more opportunities

**BUT:** Until underlying strategy logic is fixed (200 SMA conflict, no TP, early exits), expect continued losses, just smaller ones.

---

## Monitoring

Track these metrics daily:
- Signals generated per day
- Entry success rate
- Average hold time
- Exit reasons (SL vs early close vs reverse)
- Profitable symbols vs losing symbols

**Goal:** Identify which part of the strategy is broken (entry, exit, risk management).
