#!/bin/bash

# n8n Installation Functions
# Description: Workflow Automation Platform
# Contains all n8n-specific installation methods and configurations

# Function to install Node.js and npm for n8n
install_nodejs_for_n8n() {
    local os=$(detect_os)
    print_status "Installing Node.js and npm for n8n..."
    
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

# Function to install Docker for n8n
install_docker_for_n8n() {
    local os=$(detect_os)
    print_status "Installing Docker for n8n..."
    
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
        
        # Apply docker group changes immediately
        print_status "Applying Docker group changes..."
        if newgrp docker <<< 'docker ps >/dev/null 2>&1 && echo "SUCCESS"' 2>/dev/null | grep -q "SUCCESS"; then
            print_status "Docker group changes applied successfully!"
            print_status "You can now run 'docker ps' without sudo."
        else
            print_warning "Could not automatically apply Docker group changes."
            print_warning "IMPORTANT: You need to log out and back in (or restart) for Docker group changes to take effect."
            print_warning "Alternatively, you can run 'newgrp docker' to apply the group changes immediately."
        fi
        
        echo ""
        print_status "Current user groups: $(groups $USER)"
        print_status "To verify Docker access later, try: docker ps"
    fi
    
    print_status "Docker version: $(docker --version)"
}

# Function to display n8n installation menu
n8n_menu() {
    print_header "========================================="
    print_header "          n8n Installation Options      "
    print_header "========================================="
    echo ""
    echo "Choose your preferred installation method:"
    echo ""
    echo "1) Install via npm (Global installation)"
    echo "2) Install via Docker (Single container)"
    echo "3) Install via Docker Compose (Production-ready)"
    echo "4) Back to main menu"
    echo ""
}

# Function to handle n8n installation
n8n_installation() {
    while true; do
        n8n_menu
        read -p "Enter your choice (1-4): " choice
        
        case $choice in
            1)
                install_n8n_npm
                return 0
                ;;
            2)
                install_n8n_docker
                return 0
                ;;
            3)
                install_n8n_docker_compose
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

# Function to install n8n via npm
install_n8n_npm() {
    print_status "Installing n8n via npm..."
    
    # Check system requirements
    check_system_requirements
    
    # Check if Node.js is installed
    if ! command_exists node; then
        print_warning "Node.js not found. Installing Node.js first..."
        install_nodejs_for_n8n
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1)
    
    if [ $NODE_MAJOR -lt 18 ]; then
        print_error "Node.js 18+ is required. Current version: $NODE_VERSION"
        print_status "Updating Node.js..."
        install_nodejs_for_n8n
    fi
    
    # Ask for installation type
    echo ""
    print_header "n8n Installation Type"
    echo ""
    echo "Choose installation type:"
    echo "1) Global installation (system-wide, accessible from anywhere)"
    echo "2) Local installation (specific directory)"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-2): " install_type
        case $install_type in
            1)
                # Global installation
                print_status "Installing n8n globally..."
                npm install -g n8n
                
                print_status "n8n installed globally!"
                print_status "To start n8n, run: n8n"
                break
                ;;
            2)
                # Local installation - ask for directory
                local default_install_dir="./n8n"
                local install_dir=$(get_installation_directory "n8n" "$default_install_dir" "local installation")
                
                setup_installation_directory "$install_dir" "n8n"
                cd "$install_dir"
                
                # Initialize npm project and install n8n locally
                print_status "Installing n8n locally in: $install_dir"
                npm init -y
                npm install n8n
                
                # Create start script
                cat > start-n8n.sh << 'EOF'
#!/bin/bash
echo "Starting n8n..."
npx n8n
EOF
                chmod +x start-n8n.sh
                
                print_status "n8n installed locally in: $install_dir"
                print_status "To start n8n, run: cd \"$install_dir\" && ./start-n8n.sh"
                print_status "Or run: cd \"$install_dir\" && npx n8n"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
    
    # Get data directory for n8n
    local default_data_dir="./n8n-data"
    echo ""
    print_status "n8n also needs a data directory for workflows and settings."
    local n8n_data_dir=$(get_installation_directory "n8n data" "$default_data_dir" "data storage")
    setup_installation_directory "$n8n_data_dir" "n8n data"
    
    # Set N8N_USER_FOLDER environment variable if not default
    local expanded_data_dir=$(realpath "$n8n_data_dir")
    local default_expanded=$(realpath "$HOME/.n8n" 2>/dev/null || echo "$HOME/.n8n")
    
    if [ "$expanded_data_dir" != "$default_expanded" ]; then
        echo ""
        print_status "Setting n8n data directory to: $n8n_data_dir"
        print_status "You may want to add this to your shell profile:"
        echo "export N8N_USER_FOLDER=\"$expanded_data_dir\""
        
        if confirm "Would you like to add this environment variable to your ~/.bashrc?"; then
            echo "export N8N_USER_FOLDER=\"$expanded_data_dir\"" >> ~/.bashrc
            print_status "Added N8N_USER_FOLDER to ~/.bashrc"
            print_warning "Please run 'source ~/.bashrc' or restart your terminal for changes to take effect."
        fi
    fi
    
    # Configure firewall for n8n port
    print_status "Configuring firewall for n8n..."
    open_firewall_port 5678 tcp "n8n"
    
    print_status "n8n will be available at: http://localhost:5678"
    print_status "Data directory: $n8n_data_dir"
    
    # Check if port is available
    if check_port_open 5678; then
        print_status "Port 5678 is ready for n8n"
    else
        print_warning "Port 5678 may be in use. n8n might need a different port."
    fi
    
    # Create systemd service (Linux only)
    if [[ "$(detect_os)" != "macos" ]] && [[ "$(detect_os)" != "windows" ]]; then
        if confirm "Would you like to create a systemd service for n8n?"; then
            create_n8n_service "$install_dir" "$n8n_data_dir"
        fi
    fi
    
    # Show firewall status
    if is_firewall_active; then
        show_firewall_status
    fi
}

# Function to install n8n via Docker
install_n8n_docker() {
    print_status "Setting up n8n with Docker..."
    
    # Check system requirements
    check_system_requirements
    
    # Check if Docker is installed
    if ! command_exists docker; then
        print_warning "Docker not found. Installing Docker first..."
        install_docker_for_n8n
    else
        # Docker is installed, ensure user has proper permissions
        if ! docker ps >/dev/null 2>&1; then
            print_warning "Docker requires sudo to run. Checking group membership..."
            if ! groups $USER | grep -q docker; then
                print_status "Adding user to docker group..."
                sudo usermod -aG docker $USER
            fi
            
            # Try to apply group changes
            print_status "Attempting to apply Docker group changes..."
            if newgrp docker <<< 'docker ps >/dev/null 2>&1 && echo "SUCCESS"' 2>/dev/null | grep -q "SUCCESS"; then
                print_status "Docker group changes applied successfully!"
            else
                print_warning "Please run 'newgrp docker' or restart your terminal to enable Docker without sudo."
            fi
        fi
    fi
    
    # Get installation directory
    local default_data_dir="./n8n-data"
    local n8n_data_dir=$(get_installation_directory "n8n data" "$default_data_dir" "data storage")
    
    # Create n8n data directory
    setup_installation_directory "$n8n_data_dir" "n8n data"
    
    # Configure firewall for n8n port
    print_status "Configuring firewall for n8n..."
    open_firewall_port 5678 tcp "n8n"
    
    # Create a simple start script in current directory
    local current_dir=$(pwd)
    local absolute_data_dir=$(realpath "$n8n_data_dir")
    
    cat > "$current_dir/n8n-docker-start.sh" << EOF
#!/bin/bash
echo "Starting n8n with Docker..."

# Check if user can run docker without sudo
if docker ps >/dev/null 2>&1; then
    echo "Using Docker without sudo..."
    DOCKER_CMD="docker"
else
    echo "Docker requires sudo. Checking if user is in docker group..."
    if groups \$USER | grep -q docker; then
        echo "User is in docker group. Trying 'newgrp docker'..."
        echo "Note: If this fails, please run 'newgrp docker' manually or restart your terminal."
        exec newgrp docker << 'DOCKERCMD'
docker run -it --rm \\
    --name n8n \\
    -p 5678:5678 \\
    -v "$absolute_data_dir:/home/node/.n8n" \\
    n8nio/n8n
DOCKERCMD
    else
        echo "User not in docker group. Using sudo..."
        DOCKER_CMD="sudo docker"
    fi
fi

if [ -n "\$DOCKER_CMD" ]; then
    \$DOCKER_CMD run -it --rm \\
        --name n8n \\
        -p 5678:5678 \\
        -v "$absolute_data_dir:/home/node/.n8n" \\
        n8nio/n8n
fi
EOF
    
    chmod +x "$current_dir/n8n-docker-start.sh"
    
    print_status "n8n Docker setup complete!"
    print_status "Data directory: $n8n_data_dir"
    print_status "Start script: $current_dir/n8n-docker-start.sh"
    print_status "To start n8n with Docker, run: ./n8n-docker-start.sh"
    print_status "Or use: docker run -it --rm --name n8n -p 5678:5678 -v \"$absolute_data_dir:/home/node/.n8n\" n8nio/n8n"
    print_status "n8n will be available at: http://localhost:5678"
    
    # Check if port is available
    if check_port_open 5678; then
        print_status "Port 5678 is ready for n8n"
    else
        print_warning "Port 5678 may be in use. You may need to stop other services or use a different port."
    fi
    
    # Show firewall status
    if is_firewall_active; then
        show_firewall_status
    fi
}

# Function to install n8n via Docker Compose
install_n8n_docker_compose() {
    print_status "Creating n8n Docker Compose setup..."
    
    # Check system requirements
    check_system_requirements
    
    # Check if Docker is installed
    if ! command_exists docker; then
        print_warning "Docker not found. Installing Docker first..."
        install_docker_for_n8n
    else
        # Docker is installed, ensure user has proper permissions
        if ! docker ps >/dev/null 2>&1; then
            print_warning "Docker requires sudo to run. Checking group membership..."
            if ! groups $USER | grep -q docker; then
                print_status "Adding user to docker group..."
                sudo usermod -aG docker $USER
            fi
            
            # Try to apply group changes
            print_status "Attempting to apply Docker group changes..."
            if newgrp docker <<< 'docker ps >/dev/null 2>&1 && echo "SUCCESS"' 2>/dev/null | grep -q "SUCCESS"; then
                print_status "Docker group changes applied successfully!"
            else
                print_warning "Please run 'newgrp docker' or restart your terminal to enable Docker without sudo."
            fi
        fi
    fi
    
    # Get installation directory for Docker Compose project
    local default_project_dir="./n8n-docker"
    local project_dir=$(get_installation_directory "n8n Docker Compose project" "$default_project_dir" "project files")
    
    # Configure firewall for n8n port
    print_status "Configuring firewall for n8n..."
    open_firewall_port 5678 tcp "n8n"
    
    # Create project directory
    setup_installation_directory "$project_dir" "n8n Docker Compose"
    cd "$project_dir"
    
    # Create docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER:-admin}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD:-changeme}
      - N8N_HOST=${N8N_HOST:-localhost}
      - N8N_PORT=${N8N_PORT:-5678}
      - N8N_PROTOCOL=${N8N_PROTOCOL:-http}
      - NODE_ENV=production
      - WEBHOOK_URL=${WEBHOOK_URL:-http://localhost:5678/}
      - EXECUTIONS_PROCESS=main
      - EXECUTIONS_MODE=regular
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network
    depends_on:
      - postgres

  postgres:
    image: postgres:13
    restart: always
    environment:
      POSTGRES_USER: ${DB_POSTGRESDB_USER:-n8n}
      POSTGRES_PASSWORD: ${DB_POSTGRESDB_PASSWORD:-n8npassword}
      POSTGRES_DB: ${DB_POSTGRESDB_DATABASE:-n8n}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - n8n-network

volumes:
  n8n_data:
  postgres_data:

networks:
  n8n-network:
    driver: bridge
EOF

    # Create .env file for environment variables
    cat > .env << 'EOF'
# n8n Configuration
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/

# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=n8npassword
EOF

    # Create management scripts
    cat > start.sh << 'EOF'
#!/bin/bash
echo "Starting n8n with Docker Compose..."
docker-compose up -d
echo "n8n is starting up. Please wait a few moments..."
sleep 5
echo "n8n should be available at: http://localhost:5678"
EOF

    cat > stop.sh << 'EOF'
#!/bin/bash
echo "Stopping n8n..."
docker-compose down
EOF

    cat > logs.sh << 'EOF'
#!/bin/bash
echo "Showing n8n logs..."
docker-compose logs -f n8n
EOF

    cat > backup.sh << 'EOF'
#!/bin/bash
echo "Creating backup of n8n data..."
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
docker-compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/postgres_backup.sql"
echo "Backup created in: $BACKUP_DIR"
EOF

    chmod +x start.sh stop.sh logs.sh backup.sh
    
    print_status "Docker Compose setup created in: $project_dir"
    print_status "Configuration files created:"
    print_status "  - docker-compose.yml (Main configuration)"
    print_status "  - .env (Environment variables)"
    print_status "  - start.sh (Start n8n)"
    print_status "  - stop.sh (Stop n8n)"
    print_status "  - logs.sh (View logs)"
    print_status "  - backup.sh (Backup database)"
    echo ""
    print_status "To start n8n:"
    echo "  cd \"$project_dir\" && ./start.sh"
    print_status "To stop n8n:"
    echo "  cd \"$project_dir\" && ./stop.sh"
    print_status "n8n will be available at: http://localhost:5678"
    print_warning "Default credentials: admin/changeme (change in .env file)"
    
    # Check if port is available
    if check_port_open 5678; then
        print_status "Port 5678 is ready for n8n"
    else
        print_warning "Port 5678 may be in use. You may need to stop other services or configure a different port."
    fi
    
    # Show firewall status
    if is_firewall_active; then
        show_firewall_status
    fi
}

# Function to create systemd service for n8n
create_n8n_service() {
    local install_dir="${1:-}"
    local data_dir="${2:-$HOME/.n8n}"
    local service_file="/etc/systemd/system/n8n.service"
    local user=$(whoami)
    
    print_status "Creating systemd service for n8n..."
    
    # Determine the ExecStart command based on installation type
    local exec_start
    if [ -n "$install_dir" ] && [ -f "$install_dir/node_modules/.bin/n8n" ]; then
        # Local installation
        exec_start="$install_dir/node_modules/.bin/n8n"
    else
        # Global installation
        local n8n_path=$(which n8n)
        if [ -z "$n8n_path" ]; then
            print_error "Cannot find n8n executable. Please check your installation."
            return 1
        fi
        exec_start="$n8n_path"
    fi
    
    # Create the service file
    sudo tee "$service_file" > /dev/null << EOF
[Unit]
Description=n8n workflow automation
After=network.target

[Service]
Type=simple
User=$user
WorkingDirectory=$HOME
ExecStart=$exec_start
Restart=always
RestartSec=3
Environment=NODE_ENV=production
Environment=N8N_LOG_LEVEL=info
Environment=N8N_USER_FOLDER=$data_dir

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable n8n
    
    print_status "Systemd service created successfully!"
    print_status "Service configuration:"
    print_status "  - Executable: $exec_start"
    print_status "  - Data directory: $data_dir"
    print_status "  - User: $user"
    echo ""
    print_status "To start n8n service: sudo systemctl start n8n"
    print_status "To check status: sudo systemctl status n8n"
    print_status "To view logs: sudo journalctl -u n8n -f"
}

# Function to show n8n information and resources
show_n8n_info() {
    print_header "n8n Resources and Information"
    echo ""
    print_status "Official Documentation: https://docs.n8n.io/"
    print_status "Community Forum: https://community.n8n.io/"
    print_status "GitHub Repository: https://github.com/n8n-io/n8n"
    print_status "Templates: https://n8n.io/workflows/"
    echo ""
    print_status "Default Port: 5678"
    print_status "Default URL: http://localhost:5678"
    print_status "Config Location: ~/.n8n/"
    echo ""
}