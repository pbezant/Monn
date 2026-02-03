# 🚀 MONN AGGRESSIVE STRESS TEST - ACTIVE

## 📊 STATUS
**LIVE & MONITORING** (Started: 21:50:56)

## 🎯 Symbols Trading
- **EURUSD** (1-minute candles)
- **GBPUSD** (1-minute candles)

## ⚡ Aggressive Parameters
| Parameter | Value | Impact |
|-----------|-------|--------|
| **Timeframe** | 1m | 60x more frequent than 1H |
| **Volume** | 0.1 lots | 10x larger than conservative |
| **Stop Loss** | 2.0% | Loose, allows breathing room |
| **Min Zigzag** | 0.1% | 5x more sensitive |
| **Volume Ratio** | 1.1x | Triggers on tiny spikes |
| **MA Period** | 5 bars | Extremely reactive |
| **Min Cumulative** | 3 points | Quick pattern detection |
| **Candle Body Ratio** | 1.2 | Accepts smaller breakouts |

## 💰 Demo Account
- **Login:** 102128591
- **Server:** MetaQuotes-Demo
- **Balance:** $100 USD
- **Risk:** Demo only (no real money)

## 📋 Monitor Commands (from Mac)

### Watch Live Logs
```bash
ssh metatrader@192.168.1.201 'powershell -Command "Get-Content C:\Users\metatrader\Developement\Monn\logs\mt5\*.log | Select-Object -Last 20"'
```

### Check Account Status
From Windows VM:
```powershell
C:\Python311\python.exe -c "import MetaTrader5 as mt5; mt5.initialize(); mt5.login(102128591, password='@s6aQeZh', server='MetaQuotes-Demo'); acc = mt5.account_info(); print(f'Balance: ${acc.balance:.2f}'); print(f'Equity: ${acc.equity:.2f}'); print(f'Profit: ${acc.profit:.2f}'); print(f'Positions: {mt5.positions_total()}'); mt5.shutdown()"
```

## ⚠️ IMPORTANT NOTE
**Auto-trading was disabled when tested.** If no trades occur, enable it in MetaTrader 5:
- Open MT5
- Go to: **Tools → Options → Expert Advisors**
- Check: **"Allow Automated Trading"**

## 📁 Files
- **Config:** `configs\aggressive_stress_test.json`
- **Log:** `logs\mt5\bot_2026-01-29-21-50-56.171047.log`

## 🔍 What's Happening
Bot scans market **every minute** looking for breakout patterns with ultra-aggressive parameters. With 1-minute candles and 5x sensitivity on zigzag detection, it should trigger trades much faster than conservative settings!

---
*Generated: 2026-01-29 21:52:00*
