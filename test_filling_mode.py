#!/usr/bin/env python3
"""Test script to verify filling mode detection and place a test order."""
import MetaTrader5 as mt5

# Initialize and login
mt5.initialize()
mt5.login(102128591, server="MetaQuotes-Demo")

print("=" * 60)
print("FILLING MODE TEST")
print("=" * 60)

# Check filling mode for each symbol
symbols = ["EURUSD", "GBPUSD", "USDJPY", "EURJPY", "GBPJPY", "AUDUSD"]

for symbol in symbols:
    si = mt5.symbol_info(symbol)
    if si is None:
        print(f"{symbol}: NOT AVAILABLE")
        continue
    
    fm = si.filling_mode
    print(f"\n{symbol}:")
    print(f"  filling_mode = {fm} (binary: {bin(fm)})")
    print(f"  Bit 0 (FOK): {'YES' if fm & 1 else 'NO'}")
    print(f"  Bit 1 (IOC): {'YES' if fm & 2 else 'NO'}")
    print(f"  Bit 2 (RETURN): {'YES' if fm & 4 else 'NO'}")
    
    # Determine correct filling mode
    if fm & 1:
        correct_mode = mt5.ORDER_FILLING_FOK
        mode_name = "FOK"
    elif fm & 2:
        correct_mode = mt5.ORDER_FILLING_IOC
        mode_name = "IOC"
    elif fm & 4:
        correct_mode = mt5.ORDER_FILLING_RETURN
        mode_name = "RETURN"
    else:
        correct_mode = mt5.ORDER_FILLING_FOK
        mode_name = "FOK (default)"
    
    print(f"  -> Should use: {mode_name} (type_filling={correct_mode})")

print("\n" + "=" * 60)
print("MT5 CONSTANTS:")
print(f"  ORDER_FILLING_FOK = {mt5.ORDER_FILLING_FOK}")
print(f"  ORDER_FILLING_IOC = {mt5.ORDER_FILLING_IOC}")
print(f"  ORDER_FILLING_RETURN = {mt5.ORDER_FILLING_RETURN}")
print("=" * 60)

# Try placing a test order with FOK
print("\nTesting order placement with FOK (type_filling=0)...")
symbol = "EURUSD"
si = mt5.symbol_info(symbol)
price = mt5.symbol_info_tick(symbol).ask

request = {
    "action": mt5.TRADE_ACTION_DEAL,
    "symbol": symbol,
    "volume": 0.01,
    "type": mt5.ORDER_TYPE_BUY,
    "price": price,
    "sl": price - 0.0010,
    "type_filling": mt5.ORDER_FILLING_FOK,  # This is 0
    "type_time": mt5.ORDER_TIME_GTC,
    "comment": "filling_test"
}

print(f"Request: type_filling={request['type_filling']}")

# Check order before sending
check = mt5.order_check(request)
if check is not None:
    print(f"Order check result: retcode={check.retcode}, comment={check.comment}")
else:
    print(f"Order check failed: {mt5.last_error()}")

mt5.shutdown()
print("\nDone!")
