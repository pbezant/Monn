# Monn Trading Bot - Windows Setup Script
# This script automates the installation of Python, dependencies, and configuration
# Run this script with Administrator privileges after Windows installation

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Configuration
$GITHUB_REPO = "pbezant/Monn"
$GITHUB_BRANCH = "main"
$WORK_DIR = "C:\TradingBot"
$PYTHON_VERSION = "3.11.9"

# Color functions
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║  Monn Trading Bot - Windows Automated Setup         ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Chocolatey {
    Write-Info "Checking for Chocolatey..."
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Success "Chocolatey is already installed"
        return
    }
    
    Write-Info "Installing Chocolatey package manager..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Success "Chocolatey installed successfully"
}

function Install-Python {
    Write-Info "Checking for Python..."
    
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $installedVersion = python --version 2>&1 | Select-String -Pattern "\d+\.\d+\.\d+" | ForEach-Object { $_.Matches.Value }
        Write-Success "Python $installedVersion is already installed"
        return
    }
    
    Write-Info "Installing Python $PYTHON_VERSION..."
    choco install python --version=$PYTHON_VERSION -y --force
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Wait for PATH update
    Start-Sleep -Seconds 3
    
    Write-Success "Python installed successfully"
}

function Install-Git {
    Write-Info "Checking for Git..."
    
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Success "Git is already installed"
        return
    }
    
    Write-Info "Installing Git..."
    choco install git -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Success "Git installed successfully"
}

function Install-VisualStudioBuildTools {
    Write-Info "Checking for Visual Studio Build Tools..."
    
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        Write-Success "Visual Studio Build Tools already installed"
        return
    }
    
    Write-Info "Installing Visual Studio Build Tools (required for TA-Lib)..."
    Write-Warning "This may take several minutes..."
    
    choco install visualstudio2022buildtools --package-parameters "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --includeOptional --passive" -y
    
    Write-Success "Visual Studio Build Tools installed"
}

function Clone-Repository {
    Write-Info "Setting up working directory..."
    
    if (!(Test-Path $WORK_DIR)) {
        New-Item -ItemType Directory -Path $WORK_DIR -Force | Out-Null
        Write-Success "Created working directory: $WORK_DIR"
    }
    
    Set-Location $WORK_DIR
    
    $repoPath = Join-Path $WORK_DIR "monn"
    
    if (Test-Path $repoPath) {
        Write-Warning "Repository already exists. Updating..."
        Set-Location $repoPath
        git pull origin $GITHUB_BRANCH
    } else {
        Write-Info "Cloning Monn repository..."
        $repoUrl = "https://github.com/$GITHUB_REPO.git"
        git clone $repoUrl monn
        Set-Location $repoPath
    }
    
    Write-Success "Repository ready at: $repoPath"
}

function Install-TALib {
    Write-Info "Installing TA-Lib..."
    
    # Get Python version
    $pythonVersion = python -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor}')"
    
    # Download pre-built wheel (match requirements.txt)
    $taLibUrl = "https://github.com/cgohlke/talib-build/releases/download/v0.4.19/TA_Lib-0.4.19-cp${pythonVersion}-cp${pythonVersion}-win_amd64.whl"
    $taLibFile = "talib.whl"
    
    Write-Info "Downloading TA-Lib wheel for Python $pythonVersion..."
    
    try {
        Invoke-WebRequest -Uri $taLibUrl -OutFile $taLibFile -UseBasicParsing
        python -m pip install $taLibFile
        Remove-Item $taLibFile -ErrorAction SilentlyContinue
        Write-Success "TA-Lib installed successfully"
    } catch {
        Write-Warning "Failed to download pre-built TA-Lib wheel"
        Write-Info "Attempting to install via pip (may require compilation)..."
        python -m pip install TA-Lib
    }
}

function Install-PythonDependencies {
    Write-Info "Upgrading pip..."
    python -m pip install --upgrade pip
    
    Write-Info "Installing Python dependencies from requirements.txt..."
    python -m pip install -r requirements.txt
    
    Write-Success "Python dependencies installed"
}

function Setup-Environment {
    Write-Info "Configuring environment variables..."
    
    # Create logs directory
    $logsDir = Join-Path (Get-Location) "logs"
    if (!(Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    
    # Set LOG_DIR environment variable
    [System.Environment]::SetEnvironmentVariable("LOG_DIR", $logsDir, "Machine")
    $env:LOG_DIR = $logsDir
    
    Write-Success "Environment configured (LOG_DIR: $logsDir)"
}

function Create-ServiceScript {
    Write-Info "Creating Windows service installation script..."
    
    $serviceScript = @"
# Install Monn Trading Bot as Windows Service
# Run this script with Administrator privileges

`$serviceName = "MonnTradingBot"
`$serviceDisplayName = "Monn Trading Bot"
`$serviceDescription = "Automated trading bot using MetaTrader 5"
`$pythonPath = (Get-Command python).Path
`$scriptPath = Join-Path `$PSScriptRoot "main.py"
`$workingDir = `$PSScriptRoot

# Service arguments (modify as needed)
`$arguments = @(
    "`$scriptPath",
    "--mode", "live",
    "--exch", "mt5",
    "--exch_cfg_file", "configs/exchange_config.json",
    "--sym_cfg_file", "configs/symbols_trading_config.json"
)

# Check if service exists
if (Get-Service `$serviceName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping and removing existing service..." -ForegroundColor Yellow
    Stop-Service `$serviceName -Force
    sc.exe delete `$serviceName
    Start-Sleep -Seconds 2
}

# Create service using NSSM (Non-Sucking Service Manager)
Write-Host "Installing NSSM..." -ForegroundColor Cyan
choco install nssm -y

# Install service
Write-Host "Creating service..." -ForegroundColor Cyan
nssm install `$serviceName `$pythonPath (`$arguments -join ' ')
nssm set `$serviceName AppDirectory `$workingDir
nssm set `$serviceName DisplayName `$serviceDisplayName
nssm set `$serviceName Description `$serviceDescription
nssm set `$serviceName Start SERVICE_AUTO_START
nssm set `$serviceName AppStdout "`$workingDir\logs\service_stdout.log"
nssm set `$serviceName AppStderr "`$workingDir\logs\service_stderr.log"

Write-Host "Service installed successfully!" -ForegroundColor Green
Write-Host "Start service with: Start-Service `$serviceName" -ForegroundColor Yellow
Write-Host "Check status with: Get-Service `$serviceName" -ForegroundColor Yellow
"@
    
    $serviceScript | Out-File -FilePath "install-service.ps1" -Encoding UTF8
    Write-Success "Service script created: install-service.ps1"
}

function Create-ConfigTemplates {
    Write-Info "Checking configuration files..."
    
    $exchangeConfig = "configs/exchange_config.json"
    
    if (!(Test-Path $exchangeConfig)) {
        Write-Warning "Exchange config not found, creating template..."
        
        $template = @{
            account = 12345678
            server = "YourBroker-Server"
            password = "your_password"
        } | ConvertTo-Json
        
        $template | Out-File -FilePath $exchangeConfig -Encoding UTF8
        Write-Info "Created template: $exchangeConfig (EDIT THIS FILE)"
    }
    
    Write-Success "Configuration files ready"
}

function Show-NextSteps {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║            Setup Completed Successfully!             ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Install MetaTrader 5:" -ForegroundColor Yellow
    Write-Host "   - Download from your broker's website"
    Write-Host "   - Install and login to your MT5 account"
    Write-Host ""
    Write-Host "2. Configure the bot:" -ForegroundColor Yellow
    Write-Host "   - Edit: configs/exchange_config.json (MT5 credentials)"
    Write-Host "   - Edit: configs/symbols_trading_config.json (trading strategies)"
    Write-Host ""
    Write-Host "3. Test the configuration:" -ForegroundColor Yellow
    Write-Host "   python main.py --mode test --exch mt5 --exch_cfg_file configs/exchange_config.json --sym_cfg_file configs/symbols_trading_config.json --data_dir <path_to_data>"
    Write-Host ""
    Write-Host "4. Run in live mode:" -ForegroundColor Yellow
    Write-Host "   python main.py --mode live --exch mt5 --exch_cfg_file configs/exchange_config.json --sym_cfg_file configs/symbols_trading_config.json"
    Write-Host ""
    Write-Host "5. (Optional) Install as Windows Service:" -ForegroundColor Yellow
    Write-Host "   .\install-service.ps1"
    Write-Host ""
    Write-Host "Installation Path: $(Get-Location)" -ForegroundColor Cyan
    Write-Host "Logs Directory: $env:LOG_DIR" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
function Main {
    Write-Header
    
    # Check administrator
    if (!(Test-Administrator)) {
        Write-Error "This script must be run as Administrator!"
        Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        exit 1
    }
    
    try {
        Install-Chocolatey
        Install-Python
        Install-Git
        Install-VisualStudioBuildTools
        Clone-Repository
        Install-TALib
        Install-PythonDependencies
        Setup-Environment
        Create-ServiceScript
        Create-ConfigTemplates
        Show-NextSteps
        
    } catch {
        Write-Error "Setup failed: $_"
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        exit 1
    }
}

# Run main
Main
