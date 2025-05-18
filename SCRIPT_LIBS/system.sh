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