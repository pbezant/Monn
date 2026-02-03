"""
Quick script to get MT5 account status and trade history
Run this on Windows VM to check bot performance
"""
import MetaTrader5 as mt5  # type: ignore
from datetime import datetime, timedelta
import sys

def main():
    if not mt5.initialize():
        print(f"[-] MT5 initialize failed: {mt5.last_error()}")
        sys.exit(1)
    
    # Get account info
    account_info = mt5.account_info()
    if account_info is None:
        print(f"[-] Failed to get account info: {mt5.last_error()}")
        mt5.shutdown()
        sys.exit(1)
    
    print("=" * 60)
    print("ACCOUNT STATUS")
    print("=" * 60)
    print(f"Account: {account_info.login}")
    print(f"Balance: ${account_info.balance:.2f}")
    print(f"Equity: ${account_info.equity:.2f}")
    print(f"Profit: ${account_info.profit:.2f}")
    print(f"Margin: ${account_info.margin:.2f}")
    print(f"Free Margin: ${account_info.margin_free:.2f}")
    print(f"Margin Level: {account_info.margin_level:.2f}%")
    print()
    
    # Get open positions
    positions = mt5.positions_get()
    print("=" * 60)
    print(f"OPEN POSITIONS: {len(positions) if positions else 0}")
    print("=" * 60)
    if positions:
        for pos in positions:
            print(f"Ticket: {pos.ticket}")
            print(f"  Symbol: {pos.symbol}")
            print(f"  Type: {'BUY' if pos.type == 0 else 'SELL'}")
            print(f"  Volume: {pos.volume}")
            print(f"  Open Price: {pos.price_open}")
            print(f"  Current Price: {pos.price_current}")
            print(f"  SL: {pos.sl} | TP: {pos.tp}")
            print(f"  Profit: ${pos.profit:.2f}")
            print(f"  Open Time: {datetime.fromtimestamp(pos.time)}")
            print()
    else:
        print("No open positions")
        print()
    
    # Get today's trade history
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    deals = mt5.history_deals_get(today_start, datetime.now())
    
    print("=" * 60)
    print(f"TODAY'S TRADE HISTORY: {len(deals) if deals else 0} deals")
    print("=" * 60)
    if deals:
        total_profit = 0
        wins = 0
        losses = 0
        for deal in deals:
            if deal.entry == 1:  # Entry deal
                profit = deal.profit
                total_profit += profit
                if profit > 0:
                    wins += 1
                elif profit < 0:
                    losses += 1
                print(f"Ticket: {deal.ticket} | {deal.symbol} | "
                      f"{'BUY' if deal.type == 0 else 'SELL'} | "
                      f"Vol: {deal.volume} | Price: {deal.price} | "
                      f"Profit: ${profit:.2f}")
        
        print()
        print(f"Total Profit: ${total_profit:.2f}")
        print(f"Wins: {wins} | Losses: {losses}")
        if wins + losses > 0:
            print(f"Win Rate: {(wins/(wins+losses)*100):.1f}%")
    else:
        print("No trades today")
    
    print()
    
    # Get last 7 days history
    week_start = datetime.now() - timedelta(days=7)
    history_deals = mt5.history_deals_get(week_start, datetime.now())
    
    print("=" * 60)
    print(f"LAST 7 DAYS PERFORMANCE")
    print("=" * 60)
    if history_deals:
        total_profit = 0
        wins = 0
        losses = 0
        by_symbol = {}
        
        for deal in history_deals:
            if deal.entry == 1:  # Exit deals
                profit = deal.profit
                total_profit += profit
                if profit > 0:
                    wins += 1
                elif profit < 0:
                    losses += 1
                
                if deal.symbol not in by_symbol:
                    by_symbol[deal.symbol] = {'profit': 0, 'count': 0}
                by_symbol[deal.symbol]['profit'] += profit
                by_symbol[deal.symbol]['count'] += 1
        
        print(f"Total Trades: {wins + losses}")
        print(f"Wins: {wins} | Losses: {losses}")
        if wins + losses > 0:
            print(f"Win Rate: {(wins/(wins+losses)*100):.1f}%")
        print(f"Total P&L: ${total_profit:.2f}")
        print(f"Avg per trade: ${total_profit/(wins+losses) if wins+losses > 0 else 0:.2f}")
        print()
        print("Performance by Symbol:")
        for symbol, data in sorted(by_symbol.items(), key=lambda x: x[1]['profit'], reverse=True):
            print(f"  {symbol}: ${data['profit']:.2f} ({data['count']} trades)")
    else:
        print("No trade history available")
    
    mt5.shutdown()

if __name__ == "__main__":
    main()
