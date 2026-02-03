# Monn Bot Monitoring Guide

## 📊 Health Check Results

### System Status ✅
- **Bot Process**: Running (PID: 8212)
- **MT5 Platform**: Running
- **Memory**: 1.4 GB free / 4.1 GB total (66% available)
- **Disk Space**: 24.7 GB free / 59.4 GB total

### Account Status 💰
- **Balance**: $100.00
- **Equity**: $81.10
- **P&L**: -$18.90 (-18.9%)
- **Margin Level**: 340.76% ✅ (Safe - above 100%)

### Open Positions (2)
1. **EURUSD BUY** - Ticket 6599323854
   - Entry: 1.19254 | Current: 1.18038
   - P&L: -$12.16
   - Opened: Jan 29, 22:05

2. **EURUSD BUY** - Ticket 6623115052
   - Entry: 1.18708 | Current: 1.18038
   - P&L: -$6.70
   - Opened: Jan 30, 11:43

### Trading Activity
- **Today**: 0 trades (bot just restarted with fixes)
- **Last 7 Days**: 0 closed trades
- **Bot Status**: Running smoothly, processing all 6 pairs every minute

---

## 🚀 How to Monitor the Bot

### Option 1: Quick Check (From Mac)
Run the monitoring script anytime:
```bash
cd /Users/prestonbezant/_Developement/Monn
./monitor_bot.sh
```

Note: The script uses PowerShell on the Windows VM (no Unix tools like `awk`). If you saw the health check lines echo literally before, rerun after the latest update.

This will show:
- Bot health status
- Account balance and open positions
- Recent errors

### Option 2: Detailed Analysis (From Mac)
SSH into Windows VM and run the status script:
```bash
ssh metatrader@192.168.1.201
cd Developement\Monn
C:\Python311\python.exe get_account_status.py
```

### Option 3: Real-Time Log Monitoring
Watch the bot's live activity:
```bash
ssh metatrader@192.168.1.201
cd Developement\Monn
powershell "Get-Content (Get-ChildItem logs\mt5\bot_2026*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName -Wait -Tail 20"
```

### Option 4: Continuous Monitoring Agent (Advanced)
Run the monitoring agent on Windows VM for automated alerts:
```bash
ssh metatrader@192.168.1.201
cd Developement\Monn
start /B C:\Python311\python.exe monitoring_agent.py
```

This will:
- Check account health every 5 minutes
- Alert on significant equity changes (>5%)
- Alert on low margin levels (<100%)
- Log all checks to monitoring_agent.log
- Detect if bot process crashes

---

## 📈 Performance Analysis

### Trade Performance Metrics
To analyze strategy performance:
```bash
ssh metatrader@192.168.1.201
cd Developement\Monn
C:\Python311\python.exe get_account_status.py
```

This shows:
- Win rate and total P&L
- Performance by symbol
- Average profit per trade
- Number of trades in last 7 days

### Backtest Comparison
Compare live results with backtest:
```bash
python backtest.py --strategy break_strategy --config configs/aggressive_stress_test.json --start 2025-01-01 --end 2026-01-31
```

---

## ⚠️ Error Monitoring

### Check Recent Errors
```bash
ssh metatrader@192.168.1.201 "cd Developement\Monn && powershell \"Get-Content (Get-ChildItem logs\mt5\bot_2026*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName | Select-String -Pattern 'ERROR|WARNING|retcode' | Select-Object -Last 20\""
```

### Common Issues to Watch For
- `retcode: 10030` - Unsupported filling mode (should be fixed)
- `retcode: 10013` - Invalid request
- `TypeError: 'NoneType'` - Data validation issue (should be fixed)
- High rejection rate (>30%) - Strategy parameters too aggressive

---

## 🔄 Agent Workflows Available

From [AGENTS.md](AGENTS.md):

### Monitoring Agent Workflows
- **4.1**: Real-time log monitoring
- **4.2**: Account balance monitoring (every 10 min)
- **4.3**: Trade execution monitoring
- **4.4**: System resource monitoring
- **4.5**: Error pattern detection (hourly)

### Research Agent Workflows
- **3.2**: Trade performance analysis (daily/on-demand)
- **3.4**: Parameter optimization

### Server Management Workflows
- **1.1**: Health check (every 5 min)
- **1.3**: File deployment

---

## 🎯 Quick Commands Cheat Sheet

| Task | Command |
|------|---------|
| Quick monitor | `./monitor_bot.sh` |
| Account status | `ssh metatrader@192.168.1.201 "cd Developement\Monn && C:\Python311\python.exe get_account_status.py"` |
| Check if running | `ssh metatrader@192.168.1.201 "tasklist \| findstr python.exe"` |
| View live logs | `ssh metatrader@192.168.1.201 "cd Developement\Monn\logs\mt5 && powershell Get-Content (ls bot_2026*.log \| sort LastWriteTime -Desc \| select -First 1).FullName -Wait -Tail 20"` |
| Stop bot | `ssh metatrader@192.168.1.201 "taskkill /F /IM python.exe"` |
| Start bot | `ssh metatrader@192.168.1.201 "cd Developement\Monn && start /B C:\Python311\python.exe main.py --mode live --exch mt5 --exch_cfg_file configs\exchange_config.json --sym_cfg_file configs\aggressive_stress_test.json"` |

---

## 📝 Command Verification Results

✅ **Working Commands**:
- Check if running: `tasklist | findstr python.exe` ✓
- Account status: `get_account_status.py` ✓
- View logs: `powershell Get-Content ... -Tail 10` ✓
- Check errors: `Select-String -Pattern 'ERROR|WARNING|retcode'` ✓
- Stop bot: `taskkill /F /IM python.exe` ✓
- Start bot: Uses `start /B` to run in background ✓

⚠️ **Important Notes**:
- **Restart = Stop + Start (2 separate commands)** - Cannot chain with `&&` over SSH
- After stopping, wait 3-5 seconds before starting
- After code changes, MUST restart bot for changes to take effect

## 📝 Current Status Summary

✅ **System verified**
- All monitoring commands tested and working
- Account status shows: Balance $81.12 (positions closed)
- Bot successfully stopped for restart

⚠️ **Bot needs restart**
- Code fixes are deployed to server
- Bot was running old code (errors still showing `type_filling: 1`)
- Need to start bot with fresh process to load updated filling mode logic

🎯 **Next Steps**
1. Start bot: `ssh metatrader@192.168.1.201 "cd Developement\Monn && start /B C:\Python311\python.exe main.py --mode live --exch mt5 --exch_cfg_file configs\exchange_config.json --sym_cfg_file configs\aggressive_stress_test.json"`
2. Wait 10 seconds for initialization
3. Monitor logs for new trade signals
4. Verify orders use `type_filling: 2` (RETURN mode) instead of `1` (IOC mode)
