# Installation Functions
# Contains general installation methods for dependencies

# Function to install Node.js and npm
install_nodejs() {
    local os=$(detect_os)
    print_status "Installing Node.js and npm..."
    
    case $os in
        "debian")
            update_packages
            install_package "curl"
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            install_package "nodejs"
            ;;
        "redhat")
            update_packages
            install_package "curl"
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            install_package "nodejs"
            install_package "npm"
            ;;
        "macos")
            if command_exists brew; then
                brew install node
            else
                print_error "Homebrew not found. Please install Homebrew first or install Node.js manually."
                exit 1
            fi
            ;;
        *)
            print_error "Please install Node.js 18+ and npm manually for your operating system."
            exit 1
            ;;
    esac
    
    print_status "Node.js version: $(node --version)"
    print_status "npm version: $(npm --version)"
}

# Function to install Docker
install_docker() {
    local os=$(detect_os)
    print_status "Installing Docker..."
    
    case $os in
        "debian")
            update_packages
            install_package "apt-transport-https"
            install_package "ca-certificates"
            install_package "curl"
            install_package "gnupg"
            install_package "lsb-release"
            
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Set up the stable repository
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            update_packages
            install_package "docker-ce"
            install_package "docker-ce-cli"
            install_package "containerd.io"
            install_package "docker-compose-plugin"
            ;;
        "redhat")
            update_packages
            install_package "yum-utils"
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            install_package "docker-ce"
            install_package "docker-ce-cli"
            install_package "containerd.io"
            install_package "docker-compose-plugin"
            ;;
        "macos")
            print_status "Please install Docker Desktop for Mac manually from: https://docs.docker.com/desktop/mac/install/"
            if confirm "Have you installed Docker Desktop for Mac?"; then
                print_status "Continuing with Docker installation..."
            else
                exit 1
            fi
            ;;
        *)
            print_error "Please install Docker manually for your operating system."
            exit 1
            ;;
    esac
    
    # Start and enable Docker service (Linux only)
    if [[ "$os" != "macos" ]]; then
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Add current user to docker group
        print_status "Adding user '$USER' to docker group..."
        sudo usermod -aG docker $USER
        
        # Check if docker group was added successfully
        if groups $USER | grep -q docker; then
            print_status "User '$USER' successfully added to docker group."
        else
            print_warning "There might have been an issue adding user to docker group."
        fi
        
        print_warning "IMPORTANT: You need to log out and back in (or restart) for Docker group changes to take effect."
        print_warning "Alternatively, you can run 'newgrp docker' to apply the group changes immediately."
        echo ""
        
        # Provide option to test docker without sudo
        if confirm "Would you like to test Docker access now? (This will try 'newgrp docker' first)"; then
            echo "Testing Docker access..."
            
            # Try newgrp docker and then test
            if newgrp docker <<< 'docker ps >/dev/null 2>&1 && echo "SUCCESS"' | grep -q "SUCCESS"; then
                print_status "Docker is working correctly! You can now run 'docker ps' without sudo."
            else
                print_warning "Docker still requires sudo or a re-login to work properly."
                print_status "Please either:"
                print_status "  1. Log out and back in to your system"
                print_status "  2. Run: newgrp docker"
                print_status "  3. Restart your terminal/session"
                print_status "After that, you should be able to run 'docker ps' without sudo."
            fi
        fi
        
        # Show current docker permissions status
        echo ""
        print_status "Current user groups: $(groups $USER)"
        print_status "To verify Docker access later, try: docker ps"
    fi
    
    print_status "Docker version: $(docker --version)"
}

# Function to install Python
install_python() {
    local os=$(detect_os)
    print_status "Installing Python..."
    
    case $os in
        "debian")
            update_packages
            install_package "python3"
            install_package "python3-pip"
            install_package "python3-venv"
            ;;
        "redhat")
            update_packages
            install_package "python3"
            install_package "python3-pip"
            ;;
        "macos")
            if command_exists brew; then
                brew install python3
            else
                print_error "Homebrew not found. Please install Homebrew first or install Python manually."
                exit 1
            fi
            ;;
        *)
            print_error "Please install Python 3 manually for your operating system."
            exit 1
            ;;
    esac
    
    print_status "Python version: $(python3 --version)"
    print_status "pip version: $(pip3 --version)"
}

# Function to install Git
install_git() {
    local os=$(detect_os)
    print_status "Installing Git..."
    
    case $os in
        "debian")
            update_packages
            install_package "git"
            ;;
        "redhat")
            update_packages
            install_package "git"
            ;;
        "macos")
            if command_exists brew; then
                brew install git
            else
                # Git comes with macOS, check if it's already available
                if command_exists git; then
                    print_status "Git is already installed with macOS."
                else
                    print_error "Please install Git manually or install Homebrew first."
                    exit 1
                fi
            fi
            ;;
        *)
            print_error "Please install Git manually for your operating system."
            exit 1
            ;;
    esac
    
    print_status "Git version: $(git --version)"
}