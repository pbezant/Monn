# Monn Trading Bot - AI Agent Architecture

## Overview
This document defines the AI agent system for managing, monitoring, and operating the Monn trading bot. Each agent has specific responsibilities, workflows, and decision-making protocols.

---

## 1. Server Management Agent

### Purpose
Manages the Windows VM infrastructure, system resources, and deployment operations.

### Responsibilities
- Monitor VM health (CPU, RAM, disk space)
- Manage Windows services and processes
- Handle file system operations
- Execute remote commands via SSH/RDP
- Manage Python environment and dependencies

### Workflows

#### Workflow 1.1: Health Check
```yaml
trigger: Every 5 minutes
steps:
  1. SSH into Windows VM (192.168.1.201)
  2. Check Python process status: tasklist | findstr python.exe
  3. Check MT5 running: tasklist | findstr terminal64.exe
  4. Check disk space: wmic logicaldisk get size,freespace,caption
  5. Check memory: wmic OS get FreePhysicalMemory
  6. Log results to health_check.log
  7. Alert if any metric exceeds threshold
```

#### Workflow 1.2: Dependency Update
```yaml
trigger: Weekly or on-demand
steps:
  1. SSH into Windows VM
  2. Backup current environment: robocopy Developement\Monn Developement\Monn_backup /E
  3. Navigate to Monn directory
  4. Update packages: C:\Python311\python.exe -m pip install --upgrade -r requirements.txt
  5. Test import: C:\Python311\python.exe -c "import MetaTrader5; print('OK')"
  6. Rollback if failure detected
```

#### Workflow 1.3: File Deployment
```yaml
trigger: Code changes on Mac
steps:
  1. Identify changed files (git diff, manual selection)
  2. Validate Python syntax locally
  3. SCP files to Windows VM subdirectories:
     - strategies/* -> metatrader@192.168.1.201:Developement/Monn/strategies/
     - exchange/* -> metatrader@192.168.1.201:Developement/Monn/exchange/
     - configs/* -> metatrader@192.168.1.201:Developement/Monn/configs/
  4. Verify file transfer success
  5. Trigger bot restart if critical files changed
```

---

## 2. Start/Stop Control Agent

### Purpose
Manages the trading bot lifecycle - starting, stopping, restarting with proper state handling.

### Responsibilities
- Start bot with correct parameters
- Gracefully stop bot processes
- Handle emergency shutdowns
- Manage configuration file selection
- Coordinate with MT5 platform state

### Workflows

#### Workflow 2.1: Start Bot
```yaml
trigger: Manual or scheduled
preconditions:
  - MT5 platform is running
  - AutoTrading is enabled in MT5
  - Config files exist and are valid
steps:
  1. SSH into Windows VM
  2. Check if bot already running: tasklist | findstr python.exe
  3. If running, skip or prompt for restart
  4. Validate config file exists: dir configs\aggressive_stress_test.json
  5. Start bot in background:
     cd Developement\Monn
     start /B C:\Python311\python.exe main.py --mode live --exch mt5 --exch_cfg_file configs\exchange_config.json --sym_cfg_file configs\aggressive_stress_test.json
  6. Wait 5 seconds
  7. Verify process started: tasklist | findstr python.exe
  8. Tail log to confirm initialization: tail -n 20 logs\YYYY-MM-DD.log
  9. Report status to user
```

#### Workflow 2.2: Stop Bot
```yaml
trigger: Manual or scheduled maintenance
steps:
  1. SSH into Windows VM
  2. Find Python process: tasklist | findstr python.exe
  3. Graceful stop attempt:
     - Send SIGTERM equivalent (Ctrl+C simulation)
     - Wait 10 seconds
  4. Check if process stopped: tasklist | findstr python.exe
  5. If still running, force kill: taskkill /F /IM python.exe
  6. Verify all Python processes terminated
  7. Archive current log file with timestamp
  8. Report status to user
```

#### Workflow 2.3: Restart Bot (After Code Changes)
```yaml
trigger: Post-deployment or bug fix
steps:
  1. Execute Workflow 2.2 (Stop Bot)
  2. Wait 3 seconds for cleanup
  3. Validate new code files exist
  4. Execute Workflow 2.1 (Start Bot)
  5. Monitor logs for first 60 seconds
  6. Check for startup errors
  7. Confirm strategy loaded: grep "Strategy loaded" logs\latest.log
  8. Report success or errors to user
```

#### Workflow 2.4: Emergency Shutdown
```yaml
trigger: Critical error detected or manual panic
steps:
  1. SSH into Windows VM (parallel connection if needed)
  2. Force kill ALL Python: taskkill /F /IM python.exe
  3. Close all open positions in MT5 (if requested):
     - Use MT5 API to close all positions
     - Or manual instruction to user
  4. Disable AutoTrading in MT5
  5. Archive logs with EMERGENCY prefix
  6. Send immediate notification to user
  7. Document reason for shutdown
```

---

## 3. Research Agent

### Purpose
Investigates errors, analyzes market conditions, and provides insights for strategy optimization.

### Responsibilities
- Debug code errors from logs
- Analyze trade performance
- Research optimal parameters
- Investigate MT5 API behaviors
- Test new strategies in backtest mode

### Workflows

#### Workflow 3.1: Error Investigation
```yaml
trigger: Error detected in logs
input: Error message, stack trace, timestamp
steps:
  1. Parse error type (KeyError, TypeError, MT5 error code)
  2. Read relevant code file at error line
  3. Search workspace for similar error patterns
  4. Identify root cause:
     - Missing null checks
     - API parameter mismatch
     - Data format issues
  5. Propose fix with code changes
  6. Test fix locally (if possible)
  7. Document fix in error_fixes.md
```

#### Workflow 3.2: Trade Performance Analysis
```yaml
trigger: Daily or on-demand
steps:
  1. SSH into Windows VM
  2. Fetch trade history from MT5:
     python -c "import MetaTrader5 as mt5; mt5.initialize(); ..."
  3. Parse trade records (entry, exit, P&L, symbol, strategy)
  4. Calculate metrics:
     - Win rate
     - Average profit/loss
     - Max drawdown
     - Sharpe ratio
  5. Generate performance report
  6. Identify best/worst performing symbols
  7. Recommend parameter adjustments
```

#### Workflow 3.3: Strategy Backtesting
```yaml
trigger: Before deploying new strategy
steps:
  1. Validate strategy code locally
  2. Prepare historical data (download if needed)
  3. Run backtest on Mac:
     python backtest.py --strategy new_strategy --config configs/test_config.json --start 2025-01-01 --end 2026-01-31
  4. Analyze results:
     - Total trades
     - Profitability
     - Risk metrics
  5. Compare with existing strategies
  6. Recommend deployment or further tuning
```

#### Workflow 3.4: Parameter Optimization
```yaml
trigger: Strategy underperforming
steps:
  1. Load current strategy parameters
  2. Define optimization ranges (min_zz_pct, vol_ratio_ma, etc.)
  3. Run parameter tuning:
     python tuning.py --strategy break_strategy --mode grid_search
  4. Evaluate each parameter set
  5. Select best performing parameters
  6. Create new config file with optimized values
  7. Request approval before deployment
```

---

## 4. Monitoring Agent

### Purpose
Continuously observes bot operations, tracks metrics, and alerts on anomalies.

### Responsibilities
- Real-time log monitoring
- Trade execution tracking
- Account balance monitoring
- Error detection and alerting
- Performance metrics collection

### Workflows

#### Workflow 4.1: Real-Time Log Monitoring
```yaml
trigger: Continuous (while bot running)
steps:
  1. SSH into Windows VM with persistent connection
  2. Tail log file: Get-Content logs\YYYY-MM-DD.log -Wait -Tail 50
  3. Parse each new line for patterns:
     - ERROR: Alert immediately
     - WARNING: Log and count
     - "create trade": Track trade signals
     - "retcode": Parse MT5 response codes
  4. Maintain running statistics:
     - Errors per hour
     - Trades per symbol
     - Order rejection rate
  5. Alert user if thresholds exceeded
```

#### Workflow 4.2: Account Balance Monitoring
```yaml
trigger: Every 10 minutes
steps:
  1. Query MT5 account info via Python API
  2. Extract current balance, equity, margin
  3. Compare with last reading:
     - Calculate change percentage
     - Detect drawdown exceeding threshold (e.g., -10%)
  4. Track open positions count
  5. If critical threshold breached:
     - Send immediate alert
     - Execute emergency shutdown if configured
  6. Log metrics to balance_history.csv
```

#### Workflow 4.3: Trade Execution Monitoring
```yaml
trigger: On each trade attempt (detected in logs)
steps:
  1. Detect trade signal: grep "create trade" logs\latest.log
  2. Parse trade details (symbol, side, price, SL, TP)
  3. Monitor for execution confirmation:
     - "order placed" → Success
     - "retcode" → Parse error (10030, 10013, etc.)
  4. Track execution latency (signal to fill time)
  5. Count rejected orders by error type
  6. Alert if rejection rate > 30%
  7. Suggest fixes for common errors
```

#### Workflow 4.4: System Resource Monitoring
```yaml
trigger: Every 5 minutes
steps:
  1. SSH into Windows VM
  2. Check CPU usage: wmic cpu get loadpercentage
  3. Check memory: wmic OS get FreePhysicalMemory,TotalVisibleMemorySize
  4. Check disk space: fsutil volume diskfree C:
  5. Check network connectivity: ping -n 1 8.8.8.8
  6. If resource critical (>90% CPU/RAM, <1GB disk):
     - Log warning
     - Alert user
     - Prepare for graceful shutdown if needed
```

#### Workflow 4.5: Error Pattern Detection
```yaml
trigger: Hourly analysis
steps:
  1. Parse last hour of logs
  2. Extract all errors and warnings
  3. Group by error type:
     - MT5 API errors (retcode)
     - Python exceptions (KeyError, TypeError)
     - Strategy logic issues
  4. Count occurrences of each error type
  5. Identify recurring patterns (same error >3 times)
  6. Cross-reference with known fixes in error_fixes.md
  7. Generate error report with recommendations
  8. Auto-fix if solution known and safe
```

---

## 5. Configuration Management Agent

### Purpose
Manages strategy configurations, parameter tuning, and A/B testing setups.

### Responsibilities
- Validate config file syntax
- Version control for configs
- Parameter range enforcement
- Config backup and rollback
- Multi-config orchestration

### Workflows

#### Workflow 5.1: Config Validation
```yaml
trigger: Before deploying new config
input: Config file path
steps:
  1. Read JSON file
  2. Validate JSON syntax
  3. Check required fields:
     - strategy_name
     - All strategy parameters
     - symbols array
  4. Validate parameter ranges:
     - min_zz_pct: 0.001 to 0.1
     - vol_ratio_ma: 1.0 to 2.0
     - max_sl_pct: 0.5 to 5.0
  5. Check symbol format (EURUSD, GBPUSD, etc.)
  6. Verify referenced strategy exists
  7. Return validation result (pass/fail with details)
```

#### Workflow 5.2: Config Backup
```yaml
trigger: Before any config change
steps:
  1. Create backup directory: Developement\Monn\config_backups\YYYY-MM-DD_HHMMSS\
  2. Copy all config files:
     - exchange_config.json
     - aggressive_stress_test.json
     - All strategy configs
  3. Create backup manifest with timestamp and reason
  4. Maintain only last 10 backups (delete older)
  5. Confirm backup success
```

#### Workflow 5.3: Config Rollback
```yaml
trigger: Manual after failed deployment
steps:
  1. Stop bot (Workflow 2.2)
  2. List available backups: dir config_backups /O-D
  3. Select backup to restore (user choice or latest)
  4. Copy backup configs to configs\ directory
  5. Verify restoration
  6. Restart bot (Workflow 2.1)
  7. Monitor for 5 minutes to confirm stability
```

---

## 6. Communication Agent

### Purpose
Manages user notifications, reporting, and interaction with external services.

### Responsibilities
- Format status reports for user
- Send alerts via multiple channels
- Generate daily/weekly summaries
- Handle user commands and queries
- Coordinate between other agents

### Workflows

#### Workflow 6.1: Status Report Generation
```yaml
trigger: User request or daily schedule
steps:
  1. Collect data from all agents:
     - Server status (uptime, resources)
     - Bot status (running/stopped, last restart)
     - Trade stats (count, P&L, open positions)
     - Error summary (last 24 hours)
  2. Format report:
     ```
     === Monn Trading Bot Status Report ===
     Date: YYYY-MM-DD HH:MM:SS
     
     Server: Online (192.168.1.201)
     Bot Status: Running (uptime: 6h 23m)
     Strategy: break_strategy (aggressive_stress_test.json)
     
     Account:
     - Balance: $100.00
     - Equity: $78.24
     - Open Positions: 2
     - P&L Today: -$1.45
     
     Trading Activity:
     - Signals detected: 24
     - Orders placed: 8
     - Orders rejected: 2 (filling mode)
     - Win rate: 37.5%
     
     Errors: 3 warnings, 0 critical
     
     Recommendations:
     - Consider adjusting min_zz_pct (high rejection rate)
     ```
  3. Send to user via preferred channel
```

#### Workflow 6.2: Alert Dispatch
```yaml
trigger: Critical event detected by any agent
input: Alert level (INFO/WARNING/CRITICAL), message, source agent
steps:
  1. Format alert message:
     [LEVEL] Source: Agent Name
     Message: Detailed description
     Timestamp: YYYY-MM-DD HH:MM:SS
     Action required: Yes/No
  2. Route based on severity:
     - CRITICAL: Immediate notification (all channels)
     - WARNING: Standard notification
     - INFO: Log only
  3. Send via configured channels:
     - Console output (always)
     - Log file (always)
     - Future: Email, Telegram, Discord
  4. Track alert acknowledgment
  5. Escalate if no response within timeout
```

---

## 7. Data Management Agent

### Purpose
Handles log files, trade history, backtest data, and performance archives.

### Responsibilities
- Log rotation and archival
- Database management (if applicable)
- Historical data cleanup
- Export reports
- Backup trade records

### Workflows

#### Workflow 7.1: Log Rotation
```yaml
trigger: Daily at midnight or log size > 50MB
steps:
  1. SSH into Windows VM
  2. Check current log size: dir logs\YYYY-MM-DD.log
  3. If size > 50MB or new day:
     - Compress log: powershell Compress-Archive logs\YYYY-MM-DD.log logs\archive\YYYY-MM-DD.zip
     - Move original to archive
     - Create new log file
  4. Clean old archives (keep last 30 days)
  5. Update log file reference in monitoring
```

#### Workflow 7.2: Trade History Export
```yaml
trigger: Weekly or on-demand
steps:
  1. Query MT5 for trade history (last 7 days)
  2. Export to CSV format:
     Ticket,OpenTime,CloseTime,Symbol,Type,Volume,OpenPrice,ClosePrice,SL,TP,Profit,Strategy
  3. Save to: Developement\Monn\trade_history\YYYY-MM-DD.csv
  4. Append to master history file
  5. Generate summary statistics
  6. Create visualization (if tools available)
```

---

## Agent Coordination Matrix

| Trigger Event | Primary Agent | Supporting Agents | Communication Flow |
|---------------|---------------|-------------------|--------------------|
| Code Deployment | Server Management | Start/Stop, Monitoring | Server → Start/Stop → Monitoring → Communication |
| Error Detected | Monitoring | Research, Communication | Monitoring → Research (analysis) → Communication (alert) |
| Performance Issue | Monitoring | Research, Config Management | Monitoring → Research → Config Management → Start/Stop |
| User Query | Communication | All (as needed) | Communication → [Query relevant agent] → Communication |
| Daily Report | Communication | Monitoring, Data Management | Communication → [Collect from all] → Format → Send |
| Emergency | Monitoring | Start/Stop, Communication | Monitoring → Start/Stop (shutdown) → Communication (alert) |

---

## Agent Decision Tree

```
User Request/Event
    │
    ├─ "Start bot" → Start/Stop Agent → Workflow 2.1
    ├─ "Stop bot" → Start/Stop Agent → Workflow 2.2
    ├─ "Fix error" → Research Agent → Workflow 3.1 → Server Management (deploy) → Start/Stop (restart)
    ├─ "Show status" → Communication Agent → Workflow 6.1 (collect from all agents)
    ├─ "Deploy code" → Server Management → Workflow 1.3 → Start/Stop → Workflow 2.3
    ├─ "Optimize strategy" → Research Agent → Workflow 3.4 → Config Management → Workflow 5.1
    └─ [Error in log] → Monitoring Agent → Workflow 4.5 → Research Agent → Communication (alert)
```

---

## Future Enhancements

### 1. Machine Learning Agent
- Learn from past trades to optimize parameters
- Predict optimal entry/exit points
- Auto-tune strategy parameters

### 2. Risk Management Agent
- Real-time position sizing
- Portfolio-level risk limits
- Correlation analysis across symbols

### 3. Market Analysis Agent
- Economic calendar integration
- News sentiment analysis
- Volatility forecasting

### 4. Multi-Strategy Orchestrator Agent
- Run multiple strategies simultaneously
- Dynamic capital allocation
- Strategy performance comparison

---

## Implementation Priority

1. **Phase 1 (Current)**: Server Management, Start/Stop, Basic Monitoring
2. **Phase 2**: Research Agent error investigation, Communication Agent alerts
3. **Phase 3**: Configuration Management, Advanced Monitoring
4. **Phase 4**: Data Management, automated reporting
5. **Phase 5**: Future enhancements (ML, Advanced Risk Management)
