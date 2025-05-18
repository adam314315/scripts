#!/bin/bash

# Utility Functions
# Contains printing functions and common utilities

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt user for yes/no confirmation
confirm() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Created directory: $dir"
    fi
}

# Function to get installation directory with default proposal
get_installation_directory() {
    local software_name="$1"
    local default_dir="$2"
    local description="${3:-installation}"
    
    echo ""
    print_header "Installation Directory Selection"
    echo ""
    print_status "Choose where to install $software_name files:"
    echo ""
    
    while true; do
        read -p "Enter installation directory (default: $default_dir): " install_dir
        
        # Use default if empty
        if [ -z "$install_dir" ]; then
            install_dir="$default_dir"
            print_status "Using default directory: $install_dir"
        fi
        
        # Expand tilde to home directory
        install_dir="${install_dir/#\~/$HOME}"
        
        # Convert to absolute path
        install_dir=$(realpath "$install_dir" 2>/dev/null || echo "$install_dir")
        
        # Check if directory exists or can be created
        if [ -d "$install_dir" ]; then
            if [ -w "$install_dir" ]; then
                print_status "Using existing directory: $install_dir"
                echo "$install_dir"
                return 0
            else
                print_error "Directory exists but is not writable: $install_dir"
                if confirm "Would you like to try with sudo permissions?"; then
                    echo "$install_dir"
                    return 0
                fi
            fi
        else
            # Try to create the directory
            if mkdir -p "$install_dir" 2>/dev/null; then
                print_status "Created directory: $install_dir"
                echo "$install_dir"
                return 0
            else
                print_error "Cannot create directory: $install_dir"
                if confirm "Would you like to try creating it with sudo?"; then
                    if sudo mkdir -p "$install_dir" 2>/dev/null; then
                        sudo chown $USER:$(id -gn) "$install_dir"
                        print_status "Created directory with sudo: $install_dir"
                        echo "$install_dir"
                        return 0
                    else
                        print_error "Failed to create directory even with sudo"
                    fi
                fi
            fi
        fi
        
        echo ""
        print_warning "Please choose a different directory or fix permissions."
        echo "Default option: $default_dir"
        echo ""
    done
}

# Function to validate and create installation directory
setup_installation_directory() {
    local install_dir="$1"
    local software_name="$2"
    
    # Ensure directory exists and is writable
    if [ ! -d "$install_dir" ]; then
        if ! mkdir -p "$install_dir" 2>/dev/null; then
            print_status "Creating directory with sudo..."
            sudo mkdir -p "$install_dir"
            sudo chown $USER:$(id -gn) "$install_dir"
        fi
    fi
    
    # Check write permissions
    if [ ! -w "$install_dir" ]; then
        print_status "Setting permissions for installation directory..."
        sudo chown $USER:$(id -gn) "$install_dir"
        sudo chmod 755 "$install_dir"
    fi
    
    print_status "$software_name will be installed in: $install_dir"
    return 0
}