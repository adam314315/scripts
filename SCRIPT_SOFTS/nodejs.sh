#!/bin/bash

# Node.js Installation Functions
# Description: JavaScript Runtime Environment
# Contains all Node.js-specific installation methods and configurations

# Alternative approach: Description function
nodejs_description() {
    echo "JavaScript Runtime Environment"
}

# Function to display Node.js installation menu
nodejs_menu() {
    print_header "========================================="
    print_header "        Node.js Installation Options     "
    print_header "========================================="
    echo ""
    echo "Choose your preferred installation method:"
    echo ""
    echo "1) Install via Node Version Manager (nvm)"
    echo "2) Install via package manager"
    echo "3) Install specific version"
    echo "4) Back to main menu"
    echo ""
}

# Function to handle Node.js installation
nodejs_installation() {
    while true; do
        nodejs_menu
        read -p "Enter your choice (1-4): " choice
        
        case $choice in
            1)
                install_nodejs_nvm
                return 0
                ;;
            2)
                install_nodejs_package_manager
                return 0
                ;;
            3)
                install_nodejs_specific_version
                return 0
                ;;
            4)
                return 1  # Go back to main menu
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, 3, or 4."
                echo ""
                ;;
        esac
    done
}

# Function to install Node.js via NVM
install_nodejs_nvm() {
    print_status "Installing Node.js via Node Version Manager (nvm)..."
    
    # Check system requirements
    check_system_requirements
    
    # Install curl if not available
    if ! command_exists curl; then
        print_status "Installing curl..."
        install_package "curl"
    fi
    
    # Download and install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS Node.js
    nvm install --lts
    nvm use --lts
    nvm alias default node
    
    print_status "Node.js installed successfully via nvm!"
    print_status "Node.js version: $(node --version)"
    print_status "npm version: $(npm --version)"
    print_status "To use nvm in new terminals, run: source ~/.bashrc"
}

# Function to install Node.js via package manager
install_nodejs_package_manager() {
    print_status "Installing Node.js via package manager..."
    install_nodejs  # This calls the function from installers.sh
}

# Function to install specific Node.js version
install_nodejs_specific_version() {
    print_status "Installing specific Node.js version..."
    
    echo "Available Node.js versions:"
    echo "1) Latest LTS (Recommended)"
    echo "2) Latest Current"
    echo "3) Node.js 18.x LTS"
    echo "4) Node.js 16.x LTS"
    echo "5) Custom version"
    
    read -p "Choose version (1-5): " version_choice
    
    case $version_choice in
        1)
            install_nodejs_nvm
            nvm install --lts
            ;;
        2)
            install_nodejs_nvm
            nvm install node
            ;;
        3)
            install_nodejs_nvm
            nvm install 18
            ;;
        4)
            install_nodejs_nvm
            nvm install 16
            ;;
        5)
            read -p "Enter Node.js version (e.g., 14.17.0): " custom_version
            install_nodejs_nvm
            nvm install "$custom_version"
            ;;
        *)
            print_error "Invalid choice. Installing latest LTS..."
            install_nodejs_nvm
            nvm install --lts
            ;;
    esac
}

# Function to show Node.js information and resources
show_nodejs_info() {
    print_header "Node.js Resources and Information"
    echo ""
    print_status "Official Documentation: https://nodejs.org/docs/"
    print_status "npm Registry: https://www.npmjs.com/"
    print_status "Node Version Manager: https://github.com/nvm-sh/nvm"
    print_status "Express.js Framework: https://expressjs.com/"
    echo ""
    print_status "Useful npm commands:"
    print_status "  - npm init (Initialize new project)"
    print_status "  - npm install <package> (Install package)"
    print_status "  - npm install -g <package> (Install globally)"
    print_status "  - npm list (List installed packages)"
    print_status "  - npm update (Update packages)"
    echo ""
}