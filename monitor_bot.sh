#!/bin/bash
# Quick monitoring script for Monn Trading Bot
# Run from Mac: ./monitor_bot.sh

echo "🤖 Monn Trading Bot - Quick Monitor"
echo "===================================="
echo ""

# Check if bot is running
echo "📊 HEALTH CHECK:"
ssh metatrader@192.168.1.201 'powershell -NoProfile -Command "& { $p = Get-Process -Name python -ErrorAction SilentlyContinue; if ($p) { \"Running (PID: \" + ($p.Id -join \", \") + \")\" } else { \"Not Running ❌\" } }"' | sed 's/^/  Bot Process: /'
ssh metatrader@192.168.1.201 'powershell -NoProfile -Command "& { $p = Get-Process -Name terminal64 -ErrorAction SilentlyContinue; if ($p) { \"Running\" } else { \"Not Running ❌\" } }"' | sed 's/^/  MT5 Platform: /'
echo ""

# Get account status
echo "💰 ACCOUNT STATUS:"
ssh metatrader@192.168.1.201 "cd Developement\Monn && C:\Python311\python.exe get_account_status.py"

# Check recent errors
echo ""
echo "⚠️  RECENT ERRORS (last 10):"
ssh metatrader@192.168.1.201 "cd Developement\Monn && powershell \"Get-Content (Get-ChildItem logs\mt5\bot_2026*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName | Select-String -Pattern 'ERROR|retcode' | Select-Object -Last 10\""

echo ""
echo "✅ Monitor complete!"
