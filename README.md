# Prometheus Node Exporter Auto-Install Script

A comprehensive, production-ready installation and management script for Prometheus Node Exporter on Ubuntu and CentOS 7 systems. This script provides intelligent installation, automatic updates, and complete lifecycle management with extensive error checking and logging.

## 🚀 Features

### ✅ **Multi-Platform Support**
- **Ubuntu** (16.04+), **Debian** (9+)
- **RHEL/CentOS/Rocky/AlmaLinux** (7, 8, 9), **Fedora** (30+)
- **openSUSE** (Leap/Tumbleweed), **SLES**
- **Arch Linux**, **Manjaro**
- **Alpine Linux**
- **Architecture Support**: AMD64, ARM64, ARMv7, ARMv6, ARMv5, 386, MIPS, PowerPC, S390X, RISC-V

### 🔧 **Installation Features**
- Automatic OS and architecture detection
- Dependency installation (wget, curl, tar)
- System user/group creation (`node_exporter`)
- Proper directory structure setup
- Systemd service configuration
- Firewall configuration (UFW/firewalld)
- Service validation and testing

### 🔄 **Auto-Update System**
- **Weekly automatic updates** (Sundays at 3:00 AM)
- GitHub API integration for version checking
- Safe update process with rollback capability
- Comprehensive update logging
- Manual update commands with confirmation prompts

### 🛡️ **Security & Reliability**
- Root privilege checking
- Comprehensive error handling
- Service health validation
- Proper file permissions and ownership
- Non-interactive installation support

### 📊 **Monitoring Integration**
- Same collector configuration as Docker deployments
- Filesystem mount point exclusions
- Standard Prometheus metrics on port 9100
- Compatible with existing monitoring stacks

## 📋 Prerequisites

- Root or sudo access
- Internet connectivity for downloads
- Supported operating system (see compatibility matrix below)
- systemd or OpenRC init system

## 🔧 Compatibility Matrix

| Distribution | Versions | Package Manager | Service Manager | Firewall | Auto-Updates | Status |
|-------------|----------|----------------|-----------------|----------|--------------|---------|
| **Ubuntu** | 16.04, 18.04, 20.04, 22.04, 24.04+ | apt | systemd | ufw | ✅ | ✅ Fully Supported |
| **Debian** | 9 (Stretch), 10 (Buster), 11 (Bullseye), 12 (Bookworm)+ | apt | systemd | ufw | ✅ | ✅ Fully Supported |
| **RHEL** | 7, 8, 9 | yum/dnf | systemd | firewalld | ✅ | ✅ Fully Supported |
| **CentOS** | 7, 8, Stream | yum/dnf | systemd | firewalld | ✅ | ✅ Fully Supported |
| **Rocky Linux** | 8, 9 | dnf | systemd | firewalld | ✅ | ✅ Fully Supported |
| **AlmaLinux** | 8, 9 | dnf | systemd | firewalld | ✅ | ✅ Fully Supported |
| **Oracle Linux** | 7, 8, 9 | yum/dnf | systemd | firewalld | ✅ | ✅ Fully Supported |
| **Fedora** | 30, 35, 38, 39+ | dnf | systemd | firewalld | ✅ | ✅ Fully Supported |
| **openSUSE Leap** | 15.2, 15.3, 15.4+ | zypper | systemd | firewalld | ✅ | ✅ Fully Supported |
| **openSUSE Tumbleweed** | Rolling | zypper | systemd | firewalld | ✅ | ✅ Fully Supported |
| **SLES** | 15+ | zypper | systemd | firewalld | ✅ | ✅ Fully Supported |
| **Arch Linux** | Rolling | pacman | systemd | ufw/iptables | ✅ | ✅ Fully Supported |
| **Manjaro** | Current | pacman | systemd | ufw/iptables | ✅ | ✅ Fully Supported |
| **Alpine Linux** | 3.15, 3.16, 3.17, 3.18+ | apk | OpenRC | iptables | ⚠️ Manual | ⚠️ Basic Support |

### Architecture Support
- **x86**: 386 (i386/i686)
- **x86-64**: amd64 (x86_64) 
- **ARM**: armv5, armv6, armv7, arm64 (aarch64)
- **MIPS**: mips, mips64, mipsle, mips64le
- **PowerPC**: ppc64, ppc64le
- **IBM**: s390x
- **RISC-V**: riscv64

## 🚀 Quick Start

### Download and Install
```bash
# Download the script
wget https://raw.githubusercontent.com/blink-zero/node-exporter-installer/main/install_node_exporter.sh

# Make executable
chmod +x install_node_exporter.sh

# Install Node Exporter
sudo ./install_node_exporter.sh install
```

### One-Liner Installation
```bash
curl -sSL https://raw.githubusercontent.com/blink-zero/node-exporter-installer/main/install_node_exporter.sh | sudo bash -s -- install
```

## 📖 Usage

### Basic Commands
```bash
# Install Node Exporter with auto-updates
sudo ./install_node_exporter.sh install

# Check service status
sudo ./install_node_exporter.sh status

# Test installation
sudo ./install_node_exporter.sh test

# Uninstall completely
sudo ./install_node_exporter.sh uninstall
```

### Update Management
```bash
# Check for available updates
sudo ./install_node_exporter.sh check-update

# Manual update (with confirmation prompt)
sudo ./install_node_exporter.sh update

# Force automatic update (no prompts)
sudo ./install_node_exporter.sh auto-update
```

### Monitoring Commands
```bash
# View service logs
sudo journalctl -u node_exporter -f

# View update logs
sudo tail -f /var/log/node_exporter/updates.log

# Check metrics endpoint
curl http://localhost:9100/metrics

# Service management
sudo systemctl status node_exporter
sudo systemctl restart node_exporter
```

## 📁 Directory Structure

After installation, the following structure is created:

```
/opt/node_exporter/          # Binary installation directory
├── node_exporter            # Main executable
└── node_exporter.backup     # Backup binary (after updates)

/etc/node_exporter/          # Configuration directory
└── version_backup.txt       # Version backup file

/var/log/node_exporter/      # Log directory
└── updates.log              # Auto-update log file

/etc/systemd/system/
└── node_exporter.service    # Systemd service file

/etc/cron.d/
└── node_exporter_update     # Weekly update cron job
```

## ⚙️ Configuration

### Default Configuration
- **Port**: 9100
- **User/Group**: node_exporter
- **Service**: Enabled and auto-starting
- **Auto-Updates**: Enabled (weekly, systemd systems only)
- **Update Schedule**: Sundays at 3:00 AM

### Service Manager Support
- **systemd**: Ubuntu, Debian, RHEL, CentOS, Fedora, SUSE, Arch
- **OpenRC**: Alpine Linux

### Package Manager Integration
- **APT** (apt-get): Ubuntu, Debian
- **YUM**: RHEL 7, CentOS 7
- **DNF**: RHEL 8+, CentOS 8+, Fedora, Rocky, AlmaLinux
- **Zypper**: openSUSE, SLES
- **Pacman**: Arch Linux, Manjaro
- **APK**: Alpine Linux

### Systemd Service Configuration
```ini
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/opt/node_exporter/node_exporter \
    --path.procfs=/proc \
    --path.sysfs=/sys \
    --path.rootfs=/ \
    --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($|/)" \
    --web.listen-address=0.0.0.0:9100 \
    --log.level=info
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Firewall Configuration
The script automatically configures firewall rules based on your distribution:

**Ubuntu/Debian (UFW):**
```bash
sudo ufw allow 9100/tcp
```

**RHEL/CentOS/Fedora/SUSE (firewalld):**
```bash
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload
```

**Alpine/Basic Systems (iptables):**
```bash
sudo iptables -I INPUT -p tcp --dport 9100 -j ACCEPT
```

**Arch Linux:**
- UFW (if installed) or manual iptables configuration

## 🔄 Auto-Update System

### How It Works
1. **Weekly Check**: Runs every Sunday at 3:00 AM
2. **Version Comparison**: Compares installed version with GitHub releases
3. **Safe Update Process**:
   - Downloads new version
   - Stops service
   - Backs up current binary
   - Installs new version
   - Restarts service
   - Validates functionality
4. **Logging**: All activities logged to `/var/log/node_exporter/updates.log`

### Cron Job Configuration
```bash
# /etc/cron.d/node_exporter_update
0 3 * * 0 root /path/to/install_node_exporter.sh auto-update >/dev/null 2>&1
```

### Manual Update Process
```bash
# Check for updates
sudo ./install_node_exporter.sh check-update

# Output example:
# Current version: 1.7.0
# Latest version: 1.8.0
# Update available: 1.7.0 -> 1.8.0

# Perform manual update
sudo ./install_node_exporter.sh update
# Prompts for confirmation before proceeding
```

### Disable Auto-Updates
```bash
# Remove the cron job
sudo rm /etc/cron.d/node_exporter_update

# Or during uninstall (automatically removed)
sudo ./install_node_exporter.sh uninstall
```

### Script Customization
Key variables at the top of the script:

```bash
NODE_EXPORTER_VERSION="1.9.0"    # Version to install
NODE_EXPORTER_PORT="9100"        # Service port
NODE_EXPORTER_USER="node_exporter" # System user
NODE_EXPORTER_HOME="/opt/node_exporter" # Install directory
```

## 📈 Performance Impact

### Resource Usage
- **CPU**: Minimal (~0.1% on idle systems)
- **Memory**: ~10-15MB RSS
- **Disk**: ~20MB installation
- **Network**: Minimal (metrics scraping only)

### Metrics Collection
- **Default collectors**: Enabled for system metrics
- **Excluded paths**: Docker, system directories
- **Scrape frequency**: Configurable in Prometheus

### Getting Help
1. Check the troubleshooting section above
2. Review service logs: `sudo journalctl -u node_exporter`
3. Review update logs: `sudo cat /var/log/node_exporter/updates.log`
4. Open an issue on [GitHub](https://github.com/blink-zero/node-exporter-installer/issues) with:
   - OS version (`cat /etc/os-release`)
   - Script version
   - Error logs
   - Steps to reproduce

## 📋 Changelog

### v1.0.0 - 2025-08-22
- ✅ Initial release with Node Exporter v1.9.1
- ✅ **Multi-Distribution Support**: Ubuntu, Debian, RHEL, CentOS, Rocky, AlmaLinux, Fedora, openSUSE, SLES, Arch, Manjaro, Alpine
- ✅ **Package Manager Integration**: APT, YUM, DNF, Zypper, Pacman, APK
- ✅ **Service Manager Support**: systemd, OpenRC
- ✅ **Firewall Integration**: UFW, firewalld, iptables
- ✅ Auto-update system with weekly cron scheduling (systemd systems)
- ✅ Comprehensive error checking and SHA256 verification
- ✅ Smart file detection and reuse of existing downloads
- ✅ Extended architecture support (amd64, arm64, armv7, 386, mips, ppc64, s390x, riscv64)
- ✅ Legacy system compatibility (CentOS 7, older wget versions)
- ✅ Distribution-specific optimizations and fallbacks

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/blink-zero/node-exporter-installer/blob/main/LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read the [CONTRIBUTING.md](https://github.com/blink-zero/node-exporter-installer/blob/main/CONTRIBUTING.md) file for guidelines.

## ⭐ Acknowledgments

- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter) - The excellent monitoring tool this script installs
- [Prometheus Community](https://prometheus.io/community/) - For the fantastic monitoring ecosystem

---

**Made with ❤️ for the DevOps community**
