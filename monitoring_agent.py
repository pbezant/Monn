"""
Monitoring Agent - Continuous Bot Monitoring
Run this on Windows VM as a background service
"""
try:
    import MetaTrader5 as mt5
except ImportError:
    mt5 = None  # Will be None on non-Windows or when MT5 not installed
import time
import logging
from datetime import datetime
import json

# Setup logging
logging.basicConfig(
    filename='monitoring_agent.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class MonitoringAgent:
    def __init__(self):
        self.last_balance = None
        self.last_equity = None
        self.error_count = 0
        self.alert_threshold = 5  # Alert after 5 errors
        
    def check_account_health(self):
        """Monitor account balance and equity"""
        if mt5 is None:
            logging.error("MT5 not available (not on Windows)")
            return False
        if not mt5.initialize():
            logging.error(f"MT5 initialize failed: {mt5.last_error()}")
            return False
        
        account_info = mt5.account_info()
        if account_info is None:
            logging.error(f"Failed to get account info: {mt5.last_error()}")
            mt5.shutdown()
            return False
        
        balance = account_info.balance
        equity = account_info.equity
        profit = account_info.profit
        margin_level = account_info.margin_level
        
        # Check for significant changes
        if self.last_balance is not None:
            balance_change = ((balance - self.last_balance) / self.last_balance) * 100
            equity_change = ((equity - self.last_equity) / self.last_equity) * 100
            
            if abs(equity_change) > 5:  # 5% change
                logging.warning(f"ALERT: Equity changed by {equity_change:.2f}%")
            
            if equity_change < -10:  # 10% drawdown
                logging.critical(f"CRITICAL: Equity drawdown of {equity_change:.2f}%!")
        
        # Check margin level
        if margin_level < 100:
            logging.critical(f"CRITICAL: Margin level at {margin_level:.2f}% - Risk of margin call!")
        
        self.last_balance = balance
        self.last_equity = equity
        
        # Log current status
        status = {
            'timestamp': datetime.now().isoformat(),
            'balance': balance,
            'equity': equity,
            'profit': profit,
            'margin_level': margin_level
        }
        logging.info(f"Status: {json.dumps(status)}")
        
        mt5.shutdown()
        return True
    
    def check_bot_process(self):
        """Check if trading bot is still running"""
        import subprocess
        try:
            result = subprocess.run(
                ['tasklist', '/FI', 'IMAGENAME eq python.exe'],
                capture_output=True,
                text=True
            )
            if 'python.exe' not in result.stdout:
                logging.critical("CRITICAL: Trading bot process not found!")
                return False
            return True
        except Exception as e:
            logging.error(f"Error checking bot process: {e}")
            return False
    
    def monitor_loop(self, check_interval=300):  # 5 minutes
        """Main monitoring loop"""
        logging.info("Monitoring Agent Started")
        print(f"Monitoring Agent running... (checking every {check_interval}s)")
        print("Press Ctrl+C to stop")
        
        try:
            while True:
                # Check bot process
                if not self.check_bot_process():
                    self.error_count += 1
                else:
                    self.error_count = max(0, self.error_count - 1)
                
                # Check account health
                if not self.check_account_health():
                    self.error_count += 1
                else:
                    self.error_count = max(0, self.error_count - 1)
                
                # Alert if too many errors
                if self.error_count >= self.alert_threshold:
                    logging.critical(f"ALERT: {self.error_count} consecutive errors detected!")
                    # Here you could add email/telegram notifications
                
                time.sleep(check_interval)
                
        except KeyboardInterrupt:
            logging.info("Monitoring Agent Stopped")
            print("\nMonitoring stopped")

if __name__ == "__main__":
    agent = MonitoringAgent()
    agent.monitor_loop(check_interval=300)  # Check every 5 minutes
