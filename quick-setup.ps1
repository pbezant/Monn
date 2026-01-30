# Monn Trading Bot - Quick Setup Script (Tested & Working)
# Run this in PowerShell as Administrator after installing Windows

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Monn Trading Bot - Quick Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Please run as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 1. Install Chocolatey
Write-Host "[1/10] Installing Chocolatey..." -ForegroundColor Green
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 2. Install Python 3.11
Write-Host "[2/10] Installing Python 3.11..." -ForegroundColor Green
choco install python311 -y
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 3. Install Git
Write-Host "[3/10] Installing Git..." -ForegroundColor Green
choco install git -y
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 4. Install Visual Studio Build Tools
Write-Host "[4/10] Installing VS Build Tools..." -ForegroundColor Green
choco install visualstudio2022buildtools -y

# 5. Install OpenSSH
Write-Host "[5/10] Installing OpenSSH..." -ForegroundColor Green
choco install openssh -y --params "/SSHServerFeature"
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue

# 6. Clone Repository
Write-Host "[6/10] Cloning repository..." -ForegroundColor Green
$repoPath = "C:\Users\$env:USERNAME\Developement\Monn"
if (Test-Path $repoPath) {
    Set-Location $repoPath
    git pull origin main
} else {
    New-Item -ItemType Directory -Force -Path "C:\Users\$env:USERNAME\Developement" | Out-Null
    git clone https://github.com/pbezant/Monn.git "C:\Users\$env:USERNAME\Developement\Monn"
    Set-Location $repoPath
}

# 7. Install TA-Lib
Write-Host "[7/10] Installing TA-Lib..." -ForegroundColor Green
C:\Python311\python.exe -m pip install --no-cache-dir --index-url=https://pypi.anaconda.org/ranaroussi/simple TA-Lib

# 8. Install Python dependencies
Write-Host "[8/10] Installing Python packages..." -ForegroundColor Green
C:\Python311\python.exe -m pip install MetaTrader5 pandas numpy requests python-dotenv APScheduler plotly tabulate scipy tzlocal

# 9. Install MetaTrader 5
Write-Host "[9/10] Installing MetaTrader 5..." -ForegroundColor Green
$mt5Setup = "$env:TEMP\mt5setup.exe"
Invoke-WebRequest -Uri "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe" -OutFile $mt5Setup
Start-Process -FilePath $mt5Setup -ArgumentList "/auto" -Wait
Remove-Item $mt5Setup -ErrorAction SilentlyContinue

# 10. Create Desktop Shortcuts & Setup
Write-Host "[10/10] Creating shortcuts and configs..." -ForegroundColor Green

# Create directories
New-Item -ItemType Directory -Force -Path "$repoPath\logs\mt5" | Out-Null
New-Item -ItemType Directory -Force -Path "$repoPath\debug" | Out-Null

# Create demo config
$demoConfig = @"
[
    {
        "symbol": "EURUSD",
        "strategies": [
            {
                "name": "break_strategy",
                "params": {
                    "min_num_cuml": 10,
                    "min_zz_pct": 0.5,
                    "zz_dev": 2.5,
                    "ma_vol": 25,
                    "vol_ratio_ma": 1.8,
                    "kline_body_ratio": 2.5,
                    "sl_fix_mode": "ADJ_SL"
                },
                "tfs": {
                    "tf": "15m"
                },
                "max_sl_pct": 0.75,
                "volume": 0.01
            }
        ],
        "months": [1],
        "year": 2026
    }
]
"@
$demoConfig | Out-File -FilePath "$repoPath\configs\demo_config.json" -Encoding UTF8

# Start Bot shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Start Monn Trading Bot.lnk")
$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-NoExit -Command `"cd $repoPath; C:\Python311\python.exe main.py --mode live --exch mt5 --exch_cfg_file configs\exchange_config.json --sym_cfg_file configs\demo_config.json`""
$Shortcut.WorkingDirectory = $repoPath
$Shortcut.Description = "Start Monn Trading Bot"
$Shortcut.Save()

# Stop Bot shortcut
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Stop Monn Trading Bot.lnk")
$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-Command `"Stop-Process -Name python -Force; Write-Host 'Bot stopped!' -ForegroundColor Yellow; Start-Sleep 2`""
$Shortcut.Description = "Stop Monn Trading Bot"
$Shortcut.Save()

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Desktop shortcuts created:" -ForegroundColor Cyan
Write-Host "  ✓ Start Monn Trading Bot" -ForegroundColor White
Write-Host "  ✓ Stop Monn Trading Bot" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open MetaTrader 5 (installed)" -ForegroundColor White
Write-Host "2. Create demo account (File → Open an Account)" -ForegroundColor White
Write-Host "3. Note: Login, Password, Server" -ForegroundColor White
Write-Host "4. Edit: $repoPath\configs\exchange_config.json" -ForegroundColor White
Write-Host "   Format: {`"mt5`":{`"account`":LOGIN,`"password`":`"PASS`",`"server`":`"SERVER`"}}" -ForegroundColor Yellow
Write-Host "5. Double-click 'Start Monn Trading Bot' on desktop" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
