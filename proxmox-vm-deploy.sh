#!/usr/bin/env bash

# Monn Trading Bot - Proxmox Windows VM Automated Deployment
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/pbezant/Monn/main/proxmox-vm-deploy.sh)"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="1.0.0"
VM_ID=""
VM_NAME="monn-trading-bot"
VM_CORES=2
VM_MEMORY=4096  # 4GB
VM_DISK_SIZE="60G"
VM_STORAGE="local-lvm"
ISO_STORAGE="local"
WINDOWS_ISO=""
VIRTIO_ISO="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
NETWORK_BRIDGE="vmbr0"
GITHUB_REPO="pbezant/Monn"
GITHUB_BRANCH="main"
LOCAL_WINDOWS_ISO=""
PROXMOX_USER="root"
PROXMOX_HOST=""
    # Accepts sizes like "60G" or "60" and returns a number for Proxmox
    local size="$1"
    size="${size%G}"
    size="${size%g}"
    echo "$size"
}

# Helper functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Monn Trading Bot - Proxmox VM Deployment v${SCRIPT_VERSION}  ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (or with sudo)"
        exit 1
    fi
}

check_proxmox() {
    if ! command -v qm &> /dev/null; then
        print_error "Proxmox VE not detected. This script must be run on a Proxmox host."
        exit 1
    fi
    print_success "Proxmox VE detected"
}

get_next_vmid() {
    local next_id=100
    while pvesh get /cluster/resources --type vm | grep -q "vmid.*$next_id"; do
        ((next_id++))
    done
    echo "$next_id"
}

prompt_user() {
    print_header
    
    # VM ID
    local default_vmid=$(get_next_vmid)
    read -p "Enter VM ID [${default_vmid}]: " VM_ID
    VM_ID=${VM_ID:-$default_vmid}
    
    # VM Name
    read -p "Enter VM name [${VM_NAME}]: " input
    VM_NAME=${input:-$VM_NAME}
    
    # CPU Cores
    read -p "Enter number of CPU cores [${VM_CORES}]: " input
    VM_CORES=${input:-$VM_CORES}
    
    # Memory
    read -p "Enter memory in MB [${VM_MEMORY}]: " input
    VM_MEMORY=${input:-$VM_MEMORY}
    
    # Disk Size
    read -p "Enter disk size (e.g., 60G) [${VM_DISK_SIZE}]: " input
    VM_DISK_SIZE=${input:-$VM_DISK_SIZE}
    
    # Storage
    print_info "Available storage pools:"
    pvesm status | awk 'NR>1 {print "  - " $1 " (" $2 ")"}'
    read -p "Enter storage pool name [${VM_STORAGE}]: " input
    VM_STORAGE=${input:-$VM_STORAGE}
    
    # ISO Storage
    read -p "Enter ISO storage location [${ISO_STORAGE}]: " input
    ISO_STORAGE=${input:-$ISO_STORAGE}
    
    # Windows ISO (local path)
    read -p "Enter path to Windows ISO file (leave blank to use existing): " LOCAL_WINDOWS_ISO
    
    # Display available ISOs if no local path provided
    if [[ -z "$LOCAL_WINDOWS_ISO" ]]; then
        print_info "Available ISOs on Proxmox:"
        pvesm list $ISO_STORAGE --content iso 2>/dev/null | grep -i ".iso" | awk '{print "  - " $1}' || echo "  No ISOs found"
        read -p "Enter Windows ISO filename on Proxmox (e.g., Win10_22H2_English_x64.iso): " WINDOWS_ISO
        if [[ -z "$WINDOWS_ISO" ]]; then
            print_warning "No Windows ISO specified. You'll need to add it manually later."
        fi
    else
        # Extract filename from path
        WINDOWS_ISO=$(basename "$LOCAL_WINDOWS_ISO")
    fi
    
    # Network Bridge
    print_info "Available network bridges:"
    ip link show | grep "^[0-9]" | grep -o "vmbr[0-9]*" | while read -r bridge; do
        echo "  - $bridge"
    done
    read -p "Enter network bridge [${NETWORK_BRIDGE}]: " input
    NETWORK_BRIDGE=${input:-$NETWORK_BRIDGE}
    
    echo ""
    print_info "Configuration Summary:"
    echo "  VM ID: ${VM_ID}"
    echo "  VM Name: ${VM_NAME}"
    echo "  CPU Cores: ${VM_CORES}"
    echo "  Memory: ${VM_MEMORY}MB"
    echo "  Disk Size: ${VM_DISK_SIZE}"
    echo "  Storage: ${VM_STORAGE}"
    echo "  Windows ISO: ${WINDOWS_ISO:-'(not set)'}"
    echo "  Network: ${NETWORK_BRIDGE}"
    echo ""
    
    read -p "Continue with this configuration? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
}

download_virtio_iso() {
    print_info "Checking for VirtIO drivers ISO..."
    
    local iso_path="/var/lib/vz/template/iso/virtio-win.iso"
    
    if [[ -f "$iso_path" ]]; then
        print_success "VirtIO ISO already exists"
        return 0
    fi
    
    print_info "Downloading VirtIO drivers ISO..."
    wget -q --show-progress -O "$iso_path" "$VIRTIO_ISO" || {
        print_error "Failed to download VirtIO ISO"
        return 1
    }
    
    print_success "VirtIO ISO downloaded"
}

upload_windows_iso() {
    if [[ -z "$LOCAL_WINDOWS_ISO" ]] || [[ ! -f "$LOCAL_WINDOWS_ISO" ]]; then
        return 0
    fi
    
    local iso_filename=$(basename "$LOCAL_WINDOWS_ISO")
    local remote_path="/var/lib/vz/template/iso/$iso_filename"
    
    print_info "Uploading Windows ISO ($iso_filename)..."
    print_warning "This may take several minutes..."
    
    # Get Proxmox host info (fallback to localhost if running on Proxmox)
    local proxmox_host="${PROXMOX_HOST:-localhost}"
    
    if [[ "$proxmox_host" == "localhost" ]] || [[ "$proxmox_host" == "127.0.0.1" ]]; then
        # Running on Proxmox host directly
        cp "$LOCAL_WINDOWS_ISO" "$remote_path" || {
            print_error "Failed to copy ISO file"
            return 1
        }
    else
        # Upload via SCP from remote machine
        scp -q "$LOCAL_WINDOWS_ISO" "${PROXMOX_USER}@${proxmox_host}:$remote_path" || {
            print_error "Failed to upload ISO via SCP"
            return 1
        }
    fi
    
    print_success "Windows ISO uploaded to Proxmox"
}

download_virtio_iso() {
    print_info "Checking for VirtIO drivers ISO..."
    
    local iso_path="/var/lib/vz/template/iso/virtio-win.iso"
    
    if [[ -f "$iso_path" ]]; then
        print_success "VirtIO ISO already exists"
        return 0
    fi
    
    print_info "Downloading VirtIO drivers ISO..."
    wget -q --show-progress -O "$iso_path" "$VIRTIO_ISO" || {
        print_error "Failed to download VirtIO ISO"
        return 1
    }
    
    print_success "VirtIO ISO downloaded"
}

create_vm() {
    print_info "Creating VM ${VM_ID} (${VM_NAME})..."
    
    # Create VM
    qm create ${VM_ID} \
        --name "${VM_NAME}" \
        --ostype win11 \
        --cores ${VM_CORES} \
        --memory ${VM_MEMORY} \
        --bios ovmf \
        --machine q35 \
        --cpu host \
        --scsihw virtio-scsi-single \
        --net0 virtio,bridge=${NETWORK_BRIDGE},firewall=1 \
        --agent enabled=1,fstrim_cloned_disks=1 \
        || { print_error "Failed to create VM"; exit 1; }
    
    print_success "VM created"
    
    # Add EFI disk
    print_info "Adding EFI disk..."
    qm set ${VM_ID} --efidisk0 ${VM_STORAGE}:1,efitype=4m,pre-enrolled-keys=0
    
    # Add main disk
    print_info "Adding main disk (${VM_DISK_SIZE})..."
    local disk_size
    disk_size=$(normalize_disk_size "${VM_DISK_SIZE}")
    qm set ${VM_ID} --scsi0 ${VM_STORAGE}:${disk_size},iothread=1,cache=writeback,discard=on
    
    # Add TPM (for Windows 11)
    print_info "Adding TPM state..."
    qm set ${VM_ID} --tpmstate0 ${VM_STORAGE}:1,version=v2.0
    
    # Add CD-ROM drives
    if [[ -n "$WINDOWS_ISO" ]]; then
        print_info "Attaching Windows ISO..."
        qm set ${VM_ID} --ide0 ${ISO_STORAGE}:iso/${WINDOWS_ISO},media=cdrom
    fi
    
    print_info "Attaching VirtIO drivers ISO..."
    qm set ${VM_ID} --ide2 ${ISO_STORAGE}:iso/virtio-win.iso,media=cdrom
    
    # Boot order (Windows ISO first)
    qm set ${VM_ID} --boot order=ide0;scsi0;net0
    
    print_success "VM ${VM_ID} configured successfully"
}

create_setup_script() {
    print_info "Creating Windows post-install script..."
    
    cat > /tmp/monn-setup.ps1 << 'PSEOF'
# Monn Trading Bot - Windows Setup Script
# Run this script after Windows installation

$ErrorActionPreference = "Stop"

Write-Host "=== Monn Trading Bot Windows Setup ===" -ForegroundColor Cyan

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Python
Write-Host "Installing Python 3.11..." -ForegroundColor Yellow
choco install python311 -y
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Git
Write-Host "Installing Git..." -ForegroundColor Yellow
choco install git -y

# Refresh environment
refreshenv

# Create working directory
$WorkDir = "C:\TradingBot"
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
Set-Location $WorkDir

# Clone repository
Write-Host "Cloning Monn repository..." -ForegroundColor Yellow
$RepoUrl = "https://github.com/GITHUB_REPO.git"
git clone $RepoUrl monn
Set-Location "$WorkDir\monn"

# Install TA-Lib
Write-Host "Installing TA-Lib..." -ForegroundColor Yellow
$pythonVersion = python -c "import sys; print(f'{sys.version_info.major}{sys.version_info.minor}')"
$taLibUrl = "https://github.com/cgohlke/talib-build/releases/download/v0.4.19/TA_Lib-0.4.19-cp${pythonVersion}-cp${pythonVersion}-win_amd64.whl"
Invoke-WebRequest -Uri $taLibUrl -OutFile "talib.whl"
python -m pip install --upgrade pip
python -m pip install talib.whl
Remove-Item talib.whl

# Install Python dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
python -m pip install -r requirements.txt

# Create logs directory
New-Item -ItemType Directory -Path "$WorkDir\monn\logs" -Force | Out-Null
$env:LOG_DIR = "$WorkDir\monn\logs"
[System.Environment]::SetEnvironmentVariable("LOG_DIR", "$WorkDir\monn\logs", "Machine")

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Install MetaTrader 5 from your broker"
Write-Host "2. Configure configs/exchange_config.json with your MT5 credentials"
Write-Host "3. Configure configs/symbols_trading_config.json with your trading strategies"
Write-Host "4. Test with: python main.py --mode test --exch mt5 --exch_cfg_file configs/exchange_config.json --sym_cfg_file configs/symbols_trading_config.json --data_dir <path>"
Write-Host "5. Run live: python main.py --mode live --exch mt5 --exch_cfg_file configs/exchange_config.json --sym_cfg_file configs/symbols_trading_config.json"
Write-Host "`nScript location: $WorkDir\monn" -ForegroundColor Yellow
PSEOF
    
    # Replace GitHub repo placeholder
    sed -i "s|GITHUB_REPO|${GITHUB_REPO}|g" /tmp/monn-setup.ps1
    
    print_success "Setup script created at /tmp/monn-setup.ps1"
    print_info "Copy this script to your Windows VM and run it after installation"
}

print_instructions() {
    echo ""
    print_success "VM deployment complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Start the VM: ${GREEN}qm start ${VM_ID}${NC}"
    echo "  2. Open the VM console: ${GREEN}Access via Proxmox web UI${NC}"
    echo "  3. Install Windows (use VirtIO drivers from the second CD)"
    echo "     - When disks are missing: Load driver -> vioscsi\\w10\\amd64"
    echo "  4. After Windows installation, download and run the setup script:"
    echo "     ${YELLOW}Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/windows-setup.ps1' -OutFile setup.ps1${NC}"
    echo "     ${YELLOW}powershell -ExecutionPolicy Bypass -File setup.ps1${NC}"
    echo ""
    print_info "Configuration files location:"
    echo "  Setup script: ${GREEN}/tmp/monn-setup.ps1${NC}"
    echo "  VM Config: ${GREEN}/etc/pve/qemu-server/${VM_ID}.conf${NC}"
    echo ""
    print_info "VM Details:"
    echo "  VM ID: ${VM_ID}"
    echo "  Name: ${VM_NAME}"
    echo "  Cores: ${VM_CORES}"
    echo "  Memory: ${VM_MEMORY}MB"
    echo "  Disk: ${VM_DISK_SIZE}"
    echo ""
    print_warning "Remember to:"
    echo "  - Update ${YELLOW}configs/exchange_config.json${NC} with MT5 credentials"
    echo "  - Update ${YELLOW}configs/symbols_trading_config.json${NC} with strategies"
    echo "  - Install MetaTrader 5 from your broker"
    echo ""
}

# Main execution
main() {
    print_header
    check_root
    check_proxmox
    prompt_user
    download_virtio_iso
    upload_windows_iso
    create_vm
    create_setup_script
    print_instructions
}

main "$@"
