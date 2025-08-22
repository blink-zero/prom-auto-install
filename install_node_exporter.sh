#!/bin/bash

# Prometheus Node Exporter Install/Uninstall Script
# Supports Ubuntu and CentOS 7 with comprehensive error checking
# Author: Auto-generated script
# Version: 1.0

set -euo pipefail

# Configuration
NODE_EXPORTER_VERSION="1.9.1"
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_GROUP="node_exporter"
NODE_EXPORTER_HOME="/opt/node_exporter"
NODE_EXPORTER_CONFIG_DIR="/etc/node_exporter"
NODE_EXPORTER_LOG_DIR="/var/log/node_exporter"
NODE_EXPORTER_PORT="9100"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/node_exporter.service"
CRON_UPDATE_FILE="/etc/cron.d/node_exporter_update"
UPDATE_LOG_FILE="/var/log/node_exporter/updates.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect OS and version
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        OS_ID=$ID
        OS_ID_LIKE=$ID_LIKE
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
        OS_ID=$(echo "$OS" | tr '[:upper:]' '[:lower:]')
    elif [[ -f /etc/redhat-release ]]; then
        OS="Red Hat Enterprise Linux"
        VER=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
        OS_ID="rhel"
    elif [[ -f /etc/debian_version ]]; then
        OS="Debian"
        VER=$(cat /etc/debian_version)
        OS_ID="debian"
    else
        error "Cannot detect operating system"
        exit 1
    fi

    info "Detected OS: $OS $VER (ID: $OS_ID)"
    
    # Normalize OS name and determine package manager
    case "$OS_ID" in
        "ubuntu")
            OS_TYPE="debian"
            PKG_MANAGER="apt"
            FIREWALL_CMD="ufw"
            SERVICE_MANAGER="systemd"
            ;;
        "debian")
            OS_TYPE="debian"
            PKG_MANAGER="apt"
            FIREWALL_CMD="ufw"
            SERVICE_MANAGER="systemd"
            ;;
        "centos"|"rhel"|"rocky"|"almalinux"|"ol"|"fedora")
            OS_TYPE="redhat"
            PKG_MANAGER="yum"
            FIREWALL_CMD="firewalld"
            SERVICE_MANAGER="systemd"
            
            # Use dnf for newer versions
            if [[ "$OS_ID" == "fedora" ]] || [[ "${VER%%.*}" -ge 8 ]] 2>/dev/null; then
                PKG_MANAGER="dnf"
            fi
            ;;
        "opensuse-leap"|"opensuse-tumbleweed"|"sles")
            OS_TYPE="suse"
            PKG_MANAGER="zypper"
            FIREWALL_CMD="firewalld"
            SERVICE_MANAGER="systemd"
            ;;
        "arch"|"manjaro")
            OS_TYPE="arch"
            PKG_MANAGER="pacman"
            FIREWALL_CMD="ufw"
            SERVICE_MANAGER="systemd"
            ;;
        "alpine")
            OS_TYPE="alpine"
            PKG_MANAGER="apk"
            FIREWALL_CMD="iptables"
            SERVICE_MANAGER="openrc"
            ;;
        *)
            # Try to detect based on ID_LIKE
            if [[ "$OS_ID_LIKE" == *"debian"* ]]; then
                OS_TYPE="debian"
                PKG_MANAGER="apt"
                FIREWALL_CMD="ufw"
                SERVICE_MANAGER="systemd"
            elif [[ "$OS_ID_LIKE" == *"rhel"* ]] || [[ "$OS_ID_LIKE" == *"fedora"* ]]; then
                OS_TYPE="redhat"
                PKG_MANAGER="dnf"
                FIREWALL_CMD="firewalld"
                SERVICE_MANAGER="systemd"
            elif [[ "$OS_ID_LIKE" == *"suse"* ]]; then
                OS_TYPE="suse"
                PKG_MANAGER="zypper"
                FIREWALL_CMD="firewalld"
                SERVICE_MANAGER="systemd"
            else
                error "Unsupported operating system: $OS (ID: $OS_ID)"
                info "Supported distributions:"
                info "- Ubuntu (16.04+), Debian (9+)"
                info "- RHEL/CentOS/Rocky/AlmaLinux (7+), Fedora (30+)"
                info "- openSUSE Leap/Tumbleweed, SLES"
                info "- Arch Linux, Manjaro"
                info "- Alpine Linux"
                exit 1
            fi
            ;;
    esac
    
    info "Package Manager: $PKG_MANAGER"
    info "Firewall: $FIREWALL_CMD"
    info "Service Manager: $SERVICE_MANAGER"
}

# Check system architecture
check_architecture() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        armv6l)
            ARCH="armv6"
            ;;
        armv5*)
            ARCH="armv5"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        mips)
            ARCH="mips"
            ;;
        mips64)
            ARCH="mips64"
            ;;
        mipsel)
            ARCH="mipsle"
            ;;
        mips64el)
            ARCH="mips64le"
            ;;
        ppc64)
            ARCH="ppc64"
            ;;
        ppc64le)
            ARCH="ppc64le"
            ;;
        s390x)
            ARCH="s390x"
            ;;
        riscv64)
            ARCH="riscv64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            info "Supported architectures: amd64, arm64, armv7, armv6, armv5, 386, mips, mips64, mipsle, mips64le, ppc64, ppc64le, s390x, riscv64"
            exit 1
            ;;
    esac
    info "Architecture: $ARCH (detected from $(uname -m))"
}

# Install required packages
install_dependencies() {
    log "Installing dependencies..."
    
    case "$PKG_MANAGER" in
        apt)
            if ! command -v wget &> /dev/null; then
                apt-get update
                apt-get install -y wget curl tar
            fi
            ;;
        yum)
            if ! command -v wget &> /dev/null; then
                yum install -y wget curl tar
            fi
            ;;
        dnf)
            if ! command -v wget &> /dev/null; then
                dnf install -y wget curl tar
            fi
            ;;
        zypper)
            if ! command -v wget &> /dev/null; then
                zypper install -y wget curl tar
            fi
            ;;
        pacman)
            if ! command -v wget &> /dev/null; then
                pacman -Sy --noconfirm wget curl tar
            fi
            ;;
        apk)
            if ! command -v wget &> /dev/null; then
                apk update
                apk add wget curl tar
            fi
            ;;
        *)
            error "Unsupported package manager: $PKG_MANAGER"
            exit 1
            ;;
    esac
}

# Check if Node Exporter is already installed
check_existing_installation() {
    if systemctl is-active --quiet node_exporter 2>/dev/null; then
        warn "Node Exporter service is currently running"
        return 0
    fi
    
    if [[ -f "$SYSTEMD_SERVICE_FILE" ]]; then
        warn "Node Exporter service file exists"
        return 0
    fi
    
    if id "$NODE_EXPORTER_USER" &>/dev/null; then
        warn "Node Exporter user already exists"
        return 0
    fi
    
    return 1
}

# Create system user and group
create_user() {
    if ! getent group "$NODE_EXPORTER_GROUP" > /dev/null 2>&1; then
        log "Creating group: $NODE_EXPORTER_GROUP"
        case "$OS_TYPE" in
            alpine)
                addgroup -S "$NODE_EXPORTER_GROUP"
                ;;
            *)
                groupadd --system "$NODE_EXPORTER_GROUP"
                ;;
        esac
    else
        info "Group $NODE_EXPORTER_GROUP already exists"
    fi

    if ! getent passwd "$NODE_EXPORTER_USER" > /dev/null 2>&1; then
        log "Creating user: $NODE_EXPORTER_USER"
        case "$OS_TYPE" in
            alpine)
                adduser -S -D -H -s /bin/false -G "$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_USER"
                ;;
            *)
                useradd --system --no-create-home --shell /bin/false -g "$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_USER"
                ;;
        esac
    else
        info "User $NODE_EXPORTER_USER already exists"
    fi
}

# Download and extract Node Exporter
download_node_exporter() {
    local download_url="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"
    local temp_dir="/tmp/node_exporter_install"
    
    log "Downloading Node Exporter v${NODE_EXPORTER_VERSION}..."
    info "Download URL: $download_url"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Check if file already exists in current directory or parent directory
    local archive_name="node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz"
    if [[ -f "../$archive_name" ]]; then
        info "Found existing download in parent directory, copying..."
        cp "../$archive_name" "node_exporter.tar.gz"
    elif [[ -f "/root/$archive_name" ]]; then
        info "Found existing download in /root, copying..."
        cp "/root/$archive_name" "node_exporter.tar.gz"
    elif [[ -f "$archive_name" ]]; then
        info "Found existing download in current directory, copying..."
        cp "$archive_name" "node_exporter.tar.gz"
    else
        # Need to download the file
        info "No existing download found, downloading from GitHub..."
        
        # Test URL accessibility first
        if command -v curl &> /dev/null; then
            if ! curl -I -f -s "$download_url" > /dev/null; then
                error "Download URL is not accessible: $download_url"
                error "This could indicate:"
                error "- Invalid version number: $NODE_EXPORTER_VERSION"
                error "- Unsupported architecture: $ARCH"
                error "- Network connectivity issues"
                exit 1
            fi
        fi
        
        # Download with error checking (without --show-progress for older wget)
        if command -v wget &> /dev/null; then
            # Check wget version to determine available options
            if wget --help 2>&1 | grep -q "show-progress"; then
                WGET_PROGRESS="--show-progress"
            else
                WGET_PROGRESS=""
                info "Using older wget without progress display"
            fi
            
            if ! wget -T 30 -t 3 -q $WGET_PROGRESS "$download_url" -O "node_exporter.tar.gz"; then
                error "Failed to download Node Exporter from $download_url"
                error "Please check:"
                error "- Internet connectivity"
                error "- Version availability: $NODE_EXPORTER_VERSION"
                error "- Architecture support: $ARCH"
                exit 1
            fi
        elif command -v curl &> /dev/null; then
            if ! curl -L --fail --connect-timeout 30 --max-time 300 --progress-bar "$download_url" -o "node_exporter.tar.gz"; then
                error "Failed to download Node Exporter from $download_url"
                error "Please check:"
                error "- Internet connectivity" 
                error "- Version availability: $NODE_EXPORTER_VERSION"
                error "- Architecture support: $ARCH"
                exit 1
            fi
        else
            error "Neither wget nor curl is available for downloading"
            exit 1
        fi
    fi
    
    # Verify download
    if [[ ! -f "node_exporter.tar.gz" ]] || [[ ! -s "node_exporter.tar.gz" ]]; then
        error "Downloaded file is empty or missing"
        exit 1
    fi
    
    # Check if file is actually a tar.gz (basic check)
    if ! file node_exporter.tar.gz | grep -q "gzip compressed"; then
        error "Downloaded file doesn't appear to be a valid gzip archive"
        info "File type: $(file node_exporter.tar.gz)"
        exit 1
    fi
    
    # Optional: Verify SHA256 checksum if sha256sum is available
    if command -v sha256sum &> /dev/null; then
        info "Verifying SHA256 checksum..."
        local checksum_url="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/sha256sums.txt"
        if wget -q -T 10 "$checksum_url" -O sha256sums.txt 2>/dev/null || curl -s --connect-timeout 10 "$checksum_url" -o sha256sums.txt 2>/dev/null; then
            local expected_checksum=$(grep "node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz" sha256sums.txt | awk '{print $1}')
            if [[ -n "$expected_checksum" ]]; then
                local actual_checksum=$(sha256sum node_exporter.tar.gz | awk '{print $1}')
                if [[ "$expected_checksum" == "$actual_checksum" ]]; then
                    info "✓ SHA256 checksum verified"
                else
                    error "SHA256 checksum verification failed!"
                    error "Expected: $expected_checksum"
                    error "Actual:   $actual_checksum"
                    exit 1
                fi
            else
                warn "Could not find checksum for this architecture in sha256sums.txt"
            fi
        else
            warn "Could not download checksums file (continuing anyway)"
        fi
    fi
    
    log "Extracting Node Exporter..."
    if ! tar xzf node_exporter.tar.gz --strip-components=1; then
        error "Failed to extract Node Exporter archive"
        error "The downloaded file may be corrupted"
        exit 1
    fi
    
    # Verify binary exists
    if [[ ! -f "node_exporter" ]]; then
        error "Node Exporter binary not found in archive"
        error "Archive contents:"
        ls -la
        exit 1
    fi
    
    # Verify binary is executable
    if ! file node_exporter | grep -q "executable"; then
        error "Node Exporter binary is not a valid executable"
        info "Binary type: $(file node_exporter)"
        exit 1
    fi
    
    # Make binary executable
    chmod +x node_exporter
    
    info "Successfully downloaded and extracted Node Exporter v${NODE_EXPORTER_VERSION}"
}

# Install Node Exporter binary and create directories
install_node_exporter() {
    log "Installing Node Exporter..."
    
    # Create directories
    mkdir -p "$NODE_EXPORTER_HOME"
    mkdir -p "$NODE_EXPORTER_CONFIG_DIR"
    mkdir -p "$NODE_EXPORTER_LOG_DIR"
    
    # Copy binary
    cp node_exporter "$NODE_EXPORTER_HOME/"
    
    # Set ownership and permissions
    chown -R "$NODE_EXPORTER_USER:$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_HOME"
    chown -R "$NODE_EXPORTER_USER:$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_CONFIG_DIR"
    chown -R "$NODE_EXPORTER_USER:$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_LOG_DIR"
    
    chmod 755 "$NODE_EXPORTER_HOME/node_exporter"
    
    info "Node Exporter installed to $NODE_EXPORTER_HOME"
}

# Create systemd service file
create_systemd_service() {
    log "Creating systemd service..."
    
    # Check if we're using systemd
    if [[ "$SERVICE_MANAGER" != "systemd" ]]; then
        if [[ "$OS_TYPE" == "alpine" ]]; then
            create_openrc_service
            return
        else
            error "Unsupported service manager: $SERVICE_MANAGER"
            exit 1
        fi
    fi
    
    cat > "$SYSTEMD_SERVICE_FILE" << EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_GROUP
ExecStart=$NODE_EXPORTER_HOME/node_exporter \\
    --path.procfs=/proc \\
    --path.sysfs=/sys \\
    --path.rootfs=/ \\
    --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)(\$|/)" \\
    --web.listen-address=0.0.0.0:$NODE_EXPORTER_PORT \\
    --log.level=info
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=node_exporter

[Install]
WantedBy=multi-user.target
EOF

    # Set proper permissions
    chmod 644 "$SYSTEMD_SERVICE_FILE"
    
    # Reload systemd
    systemctl daemon-reload
    
    info "Systemd service created"
}

# Create OpenRC service file (for Alpine Linux)
create_openrc_service() {
    log "Creating OpenRC service..."
    
    local openrc_service_file="/etc/init.d/node_exporter"
    
    cat > "$openrc_service_file" << EOF
#!/sbin/openrc-run

name="node_exporter"
description="Prometheus Node Exporter"

command="$NODE_EXPORTER_HOME/node_exporter"
command_args="--path.procfs=/proc --path.sysfs=/sys --path.rootfs=/ --collector.filesystem.mount-points-exclude='^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)(\$|/)' --web.listen-address=0.0.0.0:$NODE_EXPORTER_PORT --log.level=info"
command_user="$NODE_EXPORTER_USER:$NODE_EXPORTER_GROUP"
command_background="yes"
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/var/log/node_exporter/node_exporter.log"
error_log="/var/log/node_exporter/node_exporter.log"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --owner \$command_user --mode 0755 \\
        /var/log/node_exporter
}
EOF

    # Set proper permissions
    chmod 755 "$openrc_service_file"
    
    info "OpenRC service created"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    case "$FIREWALL_CMD" in
        ufw)
            if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
                ufw allow "$NODE_EXPORTER_PORT/tcp"
                info "UFW rule added for port $NODE_EXPORTER_PORT"
            fi
            ;;
        firewalld)
            if systemctl is-active --quiet firewalld 2>/dev/null; then
                firewall-cmd --permanent --add-port="$NODE_EXPORTER_PORT/tcp"
                firewall-cmd --reload
                info "Firewalld rule added for port $NODE_EXPORTER_PORT"
            fi
            ;;
        iptables)
            # Basic iptables rule for Alpine/systems without firewalld/ufw
            if command -v iptables &> /dev/null; then
                # Check if rule already exists
                if ! iptables -C INPUT -p tcp --dport "$NODE_EXPORTER_PORT" -j ACCEPT 2>/dev/null; then
                    iptables -I INPUT -p tcp --dport "$NODE_EXPORTER_PORT" -j ACCEPT
                    info "Iptables rule added for port $NODE_EXPORTER_PORT"
                    warn "Note: iptables rule is temporary. Consider using a firewall management tool."
                fi
            fi
            ;;
        *)
            warn "Unknown firewall system: $FIREWALL_CMD"
            info "Please manually configure firewall to allow port $NODE_EXPORTER_PORT"
            ;;
    esac
}

# Start and enable service
start_service() {
    log "Starting Node Exporter service..."
    
    case "$SERVICE_MANAGER" in
        systemd)
            # Enable service
            systemctl enable node_exporter
            
            # Start service
            systemctl start node_exporter
            
            # Wait a moment and check status
            sleep 2
            
            if systemctl is-active --quiet node_exporter; then
                log "Node Exporter service started successfully"
                info "Node Exporter is running on port $NODE_EXPORTER_PORT"
                info "Metrics available at: http://$(hostname -I | awk '{print $1}'):$NODE_EXPORTER_PORT/metrics"
            else
                error "Failed to start Node Exporter service"
                info "Check service status with: systemctl status node_exporter"
                info "Check logs with: journalctl -u node_exporter"
                exit 1
            fi
            ;;
        openrc)
            # Enable service
            rc-update add node_exporter default
            
            # Start service
            rc-service node_exporter start
            
            # Wait a moment and check status
            sleep 2
            
            if rc-service node_exporter status | grep -q "started"; then
                log "Node Exporter service started successfully"
                info "Node Exporter is running on port $NODE_EXPORTER_PORT"
                info "Metrics available at: http://$(hostname -I | awk '{print $1}'):$NODE_EXPORTER_PORT/metrics"
            else
                error "Failed to start Node Exporter service"
                info "Check service status with: rc-service node_exporter status"
                info "Check logs in: /var/log/node_exporter/node_exporter.log"
                exit 1
            fi
            ;;
        *)
            error "Unsupported service manager: $SERVICE_MANAGER"
            exit 1
            ;;
    esac
}

# Get latest version from GitHub API
get_latest_version() {
    local latest_version
    
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    elif command -v wget &> /dev/null; then
        latest_version=$(wget -qO- https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    else
        error "Neither curl nor wget available for version checking"
        return 1
    fi
    
    if [[ -z "$latest_version" ]]; then
        error "Failed to get latest version from GitHub API"
        return 1
    fi
    
    echo "$latest_version"
}

# Get currently installed version
get_installed_version() {
    if [[ -x "$NODE_EXPORTER_HOME/node_exporter" ]]; then
        "$NODE_EXPORTER_HOME/node_exporter" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1
    else
        echo "not_installed"
    fi
}

# Check for updates
check_update() {
    log "Checking for Node Exporter updates..."
    
    local current_version=$(get_installed_version)
    local latest_version=$(get_latest_version)
    
    if [[ "$current_version" == "not_installed" ]]; then
        warn "Node Exporter is not installed"
        return 1
    fi
    
    info "Current version: $current_version"
    info "Latest version: $latest_version"
    
    if [[ "$current_version" != "$latest_version" ]]; then
        log "Update available: $current_version -> $latest_version"
        return 0
    else
        info "Node Exporter is up to date"
        return 1
    fi
}

# Perform automatic update
auto_update() {
    local update_log="$UPDATE_LOG_FILE"
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$update_log")"
    
    {
        echo "=== Node Exporter Auto-Update Check - $(date) ==="
        
        if ! check_update; then
            echo "No update needed or check failed"
            echo ""
            return 0
        fi
        
        local latest_version=$(get_latest_version)
        echo "Updating to version $latest_version..."
        
        # Backup current version info
        local backup_info="$NODE_EXPORTER_CONFIG_DIR/version_backup.txt"
        get_installed_version > "$backup_info" 2>/dev/null || true
        
        # Update NODE_EXPORTER_VERSION for download
        NODE_EXPORTER_VERSION="$latest_version"
        
        # Perform update
        local temp_dir="/tmp/node_exporter_update"
        mkdir -p "$temp_dir"
        cd "$temp_dir"
        
        if download_node_exporter && install_node_exporter_binary; then
            systemctl restart node_exporter
            sleep 3
            
            if systemctl is-active --quiet node_exporter; then
                echo "Update completed successfully to version $latest_version"
                echo "Service restarted and running"
            else
                echo "ERROR: Update completed but service failed to start"
                echo "Check service status: systemctl status node_exporter"
            fi
        else
            echo "ERROR: Update failed during download or installation"
        fi
        
        # Cleanup
        rm -rf "$temp_dir"
        echo ""
        
    } >> "$update_log" 2>&1
    
    # Rotate log if it gets too large (keep last 1000 lines)
    if [[ -f "$update_log" ]] && [[ $(wc -l < "$update_log") -gt 1000 ]]; then
        tail -n 1000 "$update_log" > "${update_log}.tmp" && mv "${update_log}.tmp" "$update_log"
    fi
}

# Install binary only (for updates)
install_node_exporter_binary() {
    log "Updating Node Exporter binary..."
    
    # Verify binary exists
    if [[ ! -f "node_exporter" ]]; then
        error "Node Exporter binary not found in current directory"
        return 1
    fi
    
    # Stop service temporarily
    if systemctl is-active --quiet node_exporter; then
        systemctl stop node_exporter
        local restart_needed=true
    fi
    
    # Backup current binary
    if [[ -f "$NODE_EXPORTER_HOME/node_exporter" ]]; then
        cp "$NODE_EXPORTER_HOME/node_exporter" "$NODE_EXPORTER_HOME/node_exporter.backup"
    fi
    
    # Install new binary
    chmod +x node_exporter
    cp node_exporter "$NODE_EXPORTER_HOME/"
    chown "$NODE_EXPORTER_USER:$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_HOME/node_exporter"
    chmod 755 "$NODE_EXPORTER_HOME/node_exporter"
    
    # Restart service if it was running
    if [[ "${restart_needed:-}" == "true" ]]; then
        systemctl start node_exporter
    fi
    
    info "Node Exporter binary updated"
    return 0
}

# Setup automatic update cron job
setup_auto_update() {
    log "Setting up automatic update checking..."
    
    # Skip cron setup for Alpine Linux (different cron system)
    if [[ "$OS_TYPE" == "alpine" ]]; then
        warn "Auto-update cron not configured for Alpine Linux"
        warn "Please manually set up cron job if needed"
        return 0
    fi
    
    # Create cron job for weekly updates (Sundays at 3 AM)
    cat > "$CRON_UPDATE_FILE" << EOF
# Node Exporter automatic update check
# Runs every Sunday at 3:00 AM
0 3 * * 0 root $0 auto-update >/dev/null 2>&1
EOF
    
    chmod 644 "$CRON_UPDATE_FILE"
    
    # Ensure cron service is running
    case "$PKG_MANAGER" in
        apt)
            systemctl enable cron >/dev/null 2>&1 || true
            systemctl restart cron >/dev/null 2>&1 || true
            ;;
        yum|dnf)
            systemctl enable crond >/dev/null 2>&1 || true
            systemctl restart crond >/dev/null 2>&1 || true
            ;;
        zypper)
            systemctl enable cron >/dev/null 2>&1 || true
            systemctl restart cron >/dev/null 2>&1 || true
            ;;
        pacman)
            systemctl enable cronie >/dev/null 2>&1 || true
            systemctl restart cronie >/dev/null 2>&1 || true
            ;;
    esac
    
    info "Auto-update cron job created: Weekly check on Sundays at 3:00 AM"
    info "Update logs: $UPDATE_LOG_FILE"
}

# Remove automatic update cron job
remove_auto_update() {
    if [[ -f "$CRON_UPDATE_FILE" ]]; then
        rm -f "$CRON_UPDATE_FILE"
        info "Auto-update cron job removed"
    fi
}
test_installation() {
    log "Testing installation..."
    
    # Test if metrics endpoint responds
    if command -v curl &> /dev/null; then
        if curl -s "http://localhost:$NODE_EXPORTER_PORT/metrics" | grep -q "node_"; then
            log "Node Exporter is responding correctly"
        else
            warn "Node Exporter may not be responding correctly"
        fi
    else
        info "curl not available, skipping endpoint test"
    fi
    
    # Display service status
    systemctl status node_exporter --no-pager -l
}

# Uninstall function
uninstall_node_exporter() {
    log "Uninstalling Node Exporter..."
    
    # Stop and disable service
    if systemctl is-active --quiet node_exporter 2>/dev/null; then
        systemctl stop node_exporter
        info "Service stopped"
    fi
    
    if systemctl is-enabled --quiet node_exporter 2>/dev/null; then
        systemctl disable node_exporter
        info "Service disabled"
    fi
    
    # Remove systemd service file
    if [[ -f "$SYSTEMD_SERVICE_FILE" ]]; then
        rm -f "$SYSTEMD_SERVICE_FILE"
        systemctl daemon-reload
        info "Service file removed"
    fi
    
    # Remove directories
    if [[ -d "$NODE_EXPORTER_HOME" ]]; then
        rm -rf "$NODE_EXPORTER_HOME"
        info "Installation directory removed"
    fi
    
    if [[ -d "$NODE_EXPORTER_CONFIG_DIR" ]]; then
        rm -rf "$NODE_EXPORTER_CONFIG_DIR"
        info "Configuration directory removed"
    fi
    
    if [[ -d "$NODE_EXPORTER_LOG_DIR" ]]; then
        rm -rf "$NODE_EXPORTER_LOG_DIR"
        info "Log directory removed"
    fi
    
    # Remove cron job
    remove_auto_update
    
    # Remove user and group
    if getent passwd "$NODE_EXPORTER_USER" > /dev/null 2>&1; then
        userdel "$NODE_EXPORTER_USER"
        info "User removed"
    fi
    
    if getent group "$NODE_EXPORTER_GROUP" > /dev/null 2>&1; then
        groupdel "$NODE_EXPORTER_GROUP" 2>/dev/null || warn "Could not remove group (may be in use)"
    fi
    
    # Clean up temporary files
    rm -rf /tmp/node_exporter_install
    
    log "Node Exporter uninstalled successfully"
}

# Show usage
show_usage() {
    echo "Usage: $0 [install|uninstall|status|test|update|check-update|auto-update]"
    echo ""
    echo "Commands:"
    echo "  install      - Install Prometheus Node Exporter"
    echo "  uninstall    - Remove Prometheus Node Exporter"
    echo "  status       - Show service status"
    echo "  test         - Test current installation"
    echo "  update       - Update to latest version"
    echo "  check-update - Check for available updates"
    echo "  auto-update  - Perform automatic update (used by cron)"
    echo ""
    echo "Configuration:"
    echo "  Port: $NODE_EXPORTER_PORT"
    echo "  User: $NODE_EXPORTER_USER"
    echo "  Home: $NODE_EXPORTER_HOME"
    echo "  Version: $NODE_EXPORTER_VERSION"
    echo "  Auto-update: Weekly (Sundays at 3:00 AM)"
}

# Show service status
show_status() {
    case "$SERVICE_MANAGER" in
        systemd)
            if systemctl is-active --quiet node_exporter 2>/dev/null; then
                log "Node Exporter is running"
                systemctl status node_exporter --no-pager -l
                echo ""
                info "Metrics endpoint: http://$(hostname -I | awk '{print $1}'):$NODE_EXPORTER_PORT/metrics"
            else
                warn "Node Exporter is not running"
                if [[ -f "$SYSTEMD_SERVICE_FILE" ]]; then
                    info "Service file exists but service is not active"
                    systemctl status node_exporter --no-pager -l
                else
                    info "Node Exporter is not installed"
                fi
            fi
            ;;
        openrc)
            if rc-service node_exporter status | grep -q "started"; then
                log "Node Exporter is running"
                rc-service node_exporter status
                echo ""
                info "Metrics endpoint: http://$(hostname -I | awk '{print $1}'):$NODE_EXPORTER_PORT/metrics"
            else
                warn "Node Exporter is not running"
                if [[ -f "/etc/init.d/node_exporter" ]]; then
                    info "Service file exists but service is not active"
                    rc-service node_exporter status
                else
                    info "Node Exporter is not installed"
                fi
            fi
            ;;
        *)
            error "Unsupported service manager for status check: $SERVICE_MANAGER"
            ;;
    esac
}

# Main installation function
install_main() {
    log "Starting Node Exporter installation..."
    
    detect_os
    check_architecture
    install_dependencies
    
    if check_existing_installation; then
        read -p "Node Exporter appears to be already installed. Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Installation cancelled"
            exit 0
        fi
    fi
    
    create_user
    download_node_exporter
    install_node_exporter
    create_systemd_service
    configure_firewall
    setup_auto_update
    start_service
    test_installation
    
    # Cleanup
    rm -rf /tmp/node_exporter_install
    
    log "Node Exporter installation completed successfully!"
    echo ""
    info "Service status: $(systemctl is-active node_exporter)"
    info "Metrics URL: http://$(hostname -I | awk '{print $1}'):$NODE_EXPORTER_PORT/metrics"
    info "Auto-updates: Weekly on Sundays at 3:00 AM"
    info "Update logs: $UPDATE_LOG_FILE"
    info "Manual update: $0 update"
    info "Service logs: journalctl -u node_exporter"
    info "Config: systemctl edit node_exporter"
}

# Main script logic
main() {
    check_root
    
    case "${1:-}" in
        "install")
            install_main
            ;;
        "uninstall")
            uninstall_node_exporter
            ;;
        "status")
            show_status
            ;;
        "test")
            test_installation
            ;;
        "update")
            if check_update; then
                read -p "Update available. Proceed with update? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    auto_update
                    log "Manual update completed"
                else
                    info "Update cancelled"
                fi
            else
                info "No update available or Node Exporter not installed"
            fi
            ;;
        "check-update")
            check_update || info "No update available"
            ;;
        "auto-update")
            auto_update
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Trap for cleanup on script exit
trap 'rm -rf /tmp/node_exporter_install 2>/dev/null || true' EXIT

# Run main function
main "$@"
