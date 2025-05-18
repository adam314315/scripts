#!/bin/bash

# System Functions
# Contains OS detection and system dependency installation functions

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to get OS version
get_os_version() {
    local os=$(detect_os)
    case $os in
        "debian")
            lsb_release -cs 2>/dev/null || echo "unknown"
            ;;
        "redhat")
            cat /etc/redhat-release | sed 's/.*release \([0-9]*\).*/\1/'
            ;;
        "macos")
            sw_vers -productVersion
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to check if running as root
is_root() {
    [ "$EUID" -eq 0 ]
}

# Function to check available package manager
get_package_manager() {
    local os=$(detect_os)
    case $os in
        "debian")
            if command_exists apt; then
                echo "apt"
            elif command_exists apt-get; then
                echo "apt-get"
            fi
            ;;
        "redhat")
            if command_exists dnf; then
                echo "dnf"
            elif command_exists yum; then
                echo "yum"
            fi
            ;;
        "macos")
            if command_exists brew; then
                echo "brew"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to update package lists
update_packages() {
    local pm=$(get_package_manager)
    local os=$(detect_os)
    
    print_status "Updating package lists..."
    
    case $pm in
        "apt"|"apt-get")
            sudo $pm update
            ;;
        "dnf"|"yum")
            sudo $pm update -y
            ;;
        "brew")
            brew update
            ;;
        *)
            print_warning "Unknown package manager. Skipping package update."
            ;;
    esac
}

# Function to install a package
install_package() {
    local package="$1"
    local pm=$(get_package_manager)
    
    print_status "Installing $package..."
    
    case $pm in
        "apt"|"apt-get")
            sudo $pm install -y "$package"
            ;;
        "dnf"|"yum")
            sudo $pm install -y "$package"
            ;;
        "brew")
            brew install "$package"
            ;;
        *)
            print_error "Cannot install $package. Unknown package manager."
            return 1
            ;;
    esac
}

# Function to check system requirements
check_system_requirements() {
    print_status "Checking system requirements..."
    
    # Check available disk space (need at least 1GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=1048576  # 1GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        print_warning "Low disk space. Available: $(($available_space/1024))MB, Recommended: 1GB+"
    fi
    
    # Check memory (need at least 512MB)
    local total_mem=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "unknown")
    if [ "$total_mem" != "unknown" ] && [ "$total_mem" -lt 524288 ]; then
        print_warning "Low memory. Available: $(($total_mem/1024))MB, Recommended: 512MB+"
    fi
    
    print_status "System requirements check completed."
}

# Function to check if firewall is active
is_firewall_active() {
    local os=$(detect_os)
    
    case $os in
        "debian")
            # Check ufw first, then iptables
            if command_exists ufw; then
                ufw status 2>/dev/null | grep -q "Status: active"
                return $?
            elif command_exists iptables; then
                # Check if there are any iptables rules beyond the default
                local rules_count=$(sudo iptables -L 2>/dev/null | wc -l)
                [ "$rules_count" -gt 8 ]  # Default iptables output has ~8 lines
                return $?
            fi
            ;;
        "redhat")
            # Check firewalld first, then iptables
            if command_exists firewall-cmd; then
                systemctl is-active firewalld >/dev/null 2>&1
                return $?
            elif command_exists iptables; then
                local rules_count=$(sudo iptables -L 2>/dev/null | wc -l)
                [ "$rules_count" -gt 8 ]
                return $?
            fi
            ;;
        "macos")
            # Check if pfctl is running (requires sudo but we'll suppress errors)
            sudo pfctl -s info >/dev/null 2>&1
            return $?
            ;;
    esac
    
    return 1  # Assume firewall is not active if we can't detect it
}

# Function to open firewall port
open_firewall_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    local service_name="${3:-application}"
    local os=$(detect_os)
    
    if ! is_firewall_active; then
        print_status "Firewall is not active, skipping port configuration."
        return 0
    fi
    
    print_status "Opening port $port/$protocol for $service_name..."
    
    case $os in
        "debian")
            if command_exists ufw; then
                if sudo ufw allow $port/$protocol comment "$service_name" 2>/dev/null; then
                    print_status "Port $port/$protocol opened in UFW for $service_name"
                else
                    print_warning "Could not configure UFW. Port may need manual configuration."
                fi
            elif command_exists iptables && [ "$EUID" -eq 0 ]; then
                sudo iptables -A INPUT -p $protocol --dport $port -j ACCEPT
                # Try to save iptables rules
                if command_exists iptables-save; then
                    sudo iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
                fi
                print_status "Port $port/$protocol opened in iptables for $service_name"
            else
                print_warning "Firewall configuration requires elevated privileges. Please manually open port $port/$protocol."
            fi
            ;;
        "redhat")
            if command_exists firewall-cmd && systemctl is-active firewalld >/dev/null 2>&1; then
                if sudo firewall-cmd --permanent --add-port=$port/$protocol 2>/dev/null && \
                   sudo firewall-cmd --reload 2>/dev/null; then
                    print_status "Port $port/$protocol opened in firewalld for $service_name"
                else
                    print_warning "Could not configure firewalld. Port may need manual configuration."
                fi
            elif command_exists iptables && [ "$EUID" -eq 0 ]; then
                sudo iptables -A INPUT -p $protocol --dport $port -j ACCEPT
                # Try to save iptables rules
                if command_exists iptables-save; then
                    sudo iptables-save > /etc/sysconfig/iptables 2>/dev/null || true
                fi
                print_status "Port $port/$protocol opened in iptables for $service_name"
            else
                print_warning "Firewall configuration requires elevated privileges. Please manually open port $port/$protocol."
            fi
            ;;
        "macos")
            print_warning "Please ensure port $port/$protocol is allowed in System Preferences > Security & Privacy > Firewall"
            ;;
        *)
            print_warning "Unknown OS, please manually configure firewall for port $port/$protocol"
            ;;
    esac
}

# Function to check if port is open
check_port_open() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    # Check if port is already in use
    if command_exists netstat; then
        if netstat -ln 2>/dev/null | grep -q ":$port "; then
            return 1  # Port is in use
        fi
    elif command_exists ss; then
        if ss -ln 2>/dev/null | grep -q ":$port "; then
            return 1  # Port is in use
        fi
    elif command_exists lsof; then
        if lsof -i :$port 2>/dev/null | grep -q ":$port"; then
            return 1  # Port is in use
        fi
    else
        # Try to connect to the port to check if it's in use
        if command_exists nc; then
            if nc -z localhost $port 2>/dev/null; then
                return 1  # Port is in use
            fi
        else
            # If we can't check, assume it's available
            return 0
        fi
    fi
    
    return 0  # Port is available
}

# Function to display firewall status
show_firewall_status() {
    local os=$(detect_os)
    
    print_header "Firewall Status"
    
    case $os in
        "debian")
            if command_exists ufw; then
                print_status "UFW Status:"
                ufw status 2>/dev/null || echo "Unable to check UFW status"
            elif command_exists iptables && [ "$EUID" -eq 0 ]; then
                print_status "iptables rules:"
                iptables -L INPUT | grep -E "(ACCEPT|DROP|REJECT)" | head -10
            else
                print_status "Firewall status check requires elevated privileges"
            fi
            ;;
        "redhat")
            if command_exists firewall-cmd; then
                print_status "firewalld Status:"
                systemctl is-active firewalld 2>/dev/null || echo "firewalld not active"
                if systemctl is-active firewalld >/dev/null 2>&1; then
                    print_status "Open ports:"
                    firewall-cmd --list-ports 2>/dev/null || echo "Unable to list ports"
                fi
            elif command_exists iptables && [ "$EUID" -eq 0 ]; then
                print_status "iptables rules:"
                iptables -L INPUT | grep -E "(ACCEPT|DROP|REJECT)" | head -10
            else
                print_status "Firewall status check requires elevated privileges"
            fi
            ;;
        "macos")
            print_status "macOS Firewall status check skipped (requires admin privileges)"
            ;;
        *)
            print_warning "Unknown OS, cannot display firewall status"
            ;;
    esac
    echo ""
}