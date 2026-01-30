# Trading Bot using MetaTrader5 API

This repository contains a trading bot that utilizes the MetaTrader5 API for automated trading in the financial markets. The bot is designed to execute trades based on pre-defined strategies and market conditions.

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Local Installation](#local-installation)
  - [Proxmox VM Deployment](#proxmox-vm-deployment)
- [Configuration](#configuration)
- [Usage](#usage)
- [Disclaimer](#disclaimer)

## Features
  1. Multiple Strategies: You can configure and run multiple strategies simultaneously. Each strategy will be analyzed independently, and the bot will make trading decisions accordingly.
  2. Multiple Timeframes: The bot can analyze multiple timeframes simultaneously. By specifying different timeframes in the config file, the bot will gather data from those timeframes to make more informed trading decisions.
  3. Backtesting: You can backtest a strategy before running it live. The bot provides a backtesting module that allows you to test your strategies against historical data and evaluate their performance(using MT5 notebook to download historical data).
  4. Parameter Tuning: The bot provides flexibility in tuning strategy parameters. You can tuning the parameters to optimize your strategies based on market conditions and historical performance.
  5. Custom Strategy: The bot is designed to make it easy to add custom strategies. You can create your own strategy and adding it to the config file.

## Prerequisites
  Before using the trading bot, make sure you have the following:
  - MetaTrader 5 platform installed on your computer
  - Active trading account with a broker that supports MetaTrader 5
  - Basic knowledge of trading concepts and strategies

## Installation

### Local Installation
  1. Clone the repository to your local machine:
     ```bash
     git clone https://github.com/Zsunflower/MetaTrader5-auto-trading-bot
     ```
  2. Install the required dependencies:
     ```bash
     pip install -r requirements.txt
     ```
  3. Install the TA-Lib library by following the installation guide provided on the [TA-Lib GitHub repository](https://github.com/TA-Lib/ta-lib-python).

### Proxmox VM Deployment

Deploy this trading bot on a Proxmox Windows VM with full automation:

#### Quick Deploy (One-Line Installation)

On your Proxmox host, run:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/pbezant/Monn/main/proxmox-vm-deploy.sh)"
```

This script will:
- Create a Windows 11 VM with optimal settings
- Configure VirtIO drivers for best performance
- Set up networking and storage
- Provide a Windows setup script for post-installation

#### After Windows Installation

Once Windows is installed on the VM, run the **automated quick-setup script** in PowerShell (as Administrator):

```powershell
# One-line installation - Run this in PowerShell as Administrator
iex (irm 'https://raw.githubusercontent.com/pbezant/Monn/main/quick-setup.ps1')
```

**Alternative:** Download and run manually:
```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/pbezant/Monn/main/quick-setup.ps1' -OutFile setup.ps1
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup.ps1
```

The automated setup script will:
- ✅ Install Chocolatey, Python 3.11, Git, Visual Studio Build Tools
- ✅ Install OpenSSH Server for remote access
- ✅ Clone this repository to `C:\Users\YourName\Developement\Monn`
- ✅ Install all Python dependencies including TA-Lib
- ✅ Install MetaTrader 5
- ✅ Create desktop shortcuts: "Start Monn Trading Bot" & "Stop Monn Trading Bot"
- ✅ Set up logging and config directories

**After setup completes:**
1. Open MetaTrader 5 → File → Open an Account → Create demo account
2. Edit `C:\Users\YourName\Developement\Monn\configs\exchange_config.json` with your MT5 credentials
3. Double-click "Start Monn Trading Bot" on your desktop!

#### Windows Install (One-Time Checklist)

1. Boot the VM from the Windows ISO.
2. When asked **Where do you want to install Windows?** and no disks appear:
  - Click **Load driver**
  - Browse the VirtIO CD (usually `D:`)
  - Select: `vioscsi\w10\amd64`
  - Click **Next** to load the driver
3. The disk will appear. Select it and continue the installation.
4. After installation completes, remove the Windows ISO (optional) and reboot.
5. If Windows has **no network access**, install the VirtIO **network driver**:
  - Open **Device Manager** → right-click **Ethernet Controller** → **Update driver**
  - Browse the VirtIO CD (usually `D:`)
  - Select: `NetKVM\\w10\\amd64`
  - Click **Next** to install
6. (Recommended) Run `D:\\virtio-win-guest-tools.exe` to install all VirtIO tools.
7. Run the Windows setup script from this repo (see above).

#### Manual Proxmox Setup

If you prefer manual setup:

1. **Create Windows VM** with these specs:
   - OS: Windows 10/11 Pro
   - CPU: 2+ cores (host CPU type)
   - RAM: 4GB minimum
   - Disk: 60GB (VirtIO SCSI)
   - Network: VirtIO adapter
   - Enable QEMU Guest Agent

2. **After Windows installation**, follow the [Local Installation](#local-installation) steps above.

For detailed deployment architecture and agent information, see [DEPLOYMENT_AGENTS.md](DEPLOYMENT_AGENTS.md).


## Configuration
  1. Log in to your MetaTrader 5 account using the MetaTrader 5 platform.
  2. Edit the 'configs/exchange_config.json' file and update the following:
     - account: Your MetaTrader 5 account number.
     - server: The server name for your MetaTrader 5 account.

## Usage
  1. Edit all strategies's parameters in 'configs/symbols_trading_config.json' file.
  2. Start the trading bot in live mode by running the following command:
     ```bash
     python main.py --mode live --exch mt5 --exch_cfg_file configs/exchange_config.json --sym_cfg_file configs/symbols_trading_config.json

  3. For backtesting a strategy, use the following command:
     ```bash
     python main.py --mode test --exch mt5 --exch_cfg_file configs/exchange_config.json --sym_cfg_file <configs/break_strategy_config.json> --data_dir <path to historical candle data>

   Backtest result of each strategy will be output like this:
    ![Screenshot 1](debug/test.jpg)
    ![Screenshot 1](debug/test2.jpg)

   The bot will generate an HTML file that visualizes the generated orders in 'debug' folder. [View example](https://1drv.ms/f/s!AtOy_2VZv2ojo3CdJpdBvbBtZBdP?e=7eyLd4)
   
  4. For tuning a strategy's parameters, use the following command:
     ```bash
     python tuning.py --sym_cfg_file <tuning_configs/break_strategy_tuning_config.json> --data_dir <path to historical candle data>

## Disclaimer
  Trading in financial markets involves risks, and the trading bot provided in this project is for educational and informational purposes only. The use of this bot is at your own risk, and the developers cannot be held responsible for any financial losses incurred.
