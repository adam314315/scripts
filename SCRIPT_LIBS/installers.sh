#!/bin/bash

# Installation Functions
# Contains all installation methods for n8n and its dependencies

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
        sudo usermod -aG docker $USER
        print_warning "Please log out and back in for Docker group changes to take effect."
    fi
    
    print_status "Docker version: $(docker --version)"
}

# Function to install n8n via npm
install_n8n_npm() {
    print_status "Installing n8n via npm..."
    
    # Check system requirements
    check_system_requirements
    
    # Check if Node.js is installed
    if ! command_exists node; then
        print_warning "Node.js not found. Installing Node.js first..."
        install_nodejs
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1)
    
    if [ $NODE_MAJOR -lt 18 ]; then
        print_error "Node.js 18+ is required. Current version: $NODE_VERSION"
        print_status "Updating Node.js..."
        install_nodejs
    fi
    
    # Install n8n globally
    npm install -g n8n
    
    print_status "n8n installed successfully!"
    print_status "To start n8n, run: n8n"
    print_status "n8n will be available at: http://localhost:5678"
    
    # Create systemd service (Linux only)
    if [[ "$(detect_os)" != "macos" ]] && [[ "$(detect_os)" != "windows" ]]; then
        if confirm "Would you like to create a systemd service for n8n?"; then
            create_n8n_service
        fi
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
        install_docker
    fi
    
    # Create n8n data directory
    ensure_directory "$HOME/.n8n"
    
    # Create a simple start script
    cat > n8n-docker-start.sh << 'EOF'
#!/bin/bash
echo "Starting n8n with Docker..."
docker run -it --rm \
    --name n8n \
    -p 5678:5678 \
    -v ~/.n8n:/home/node/.n8n \
    n8nio/n8n
EOF
    
    chmod +x n8n-docker-start.sh
    
    print_status "n8n Docker setup complete!"
    print_status "To start n8n with Docker, run: ./n8n-docker-start.sh"
    print_status "Or use: docker run -it --rm --name n8n -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n"
    print_status "n8n will be available at: http://localhost:5678"
}

# Function to install n8n via Docker Compose
install_n8n_docker_compose() {
    print_status "Creating n8n Docker Compose setup..."
    
    # Check system requirements
    check_system_requirements
    
    # Check if Docker is installed
    if ! command_exists docker; then
        print_warning "Docker not found. Installing Docker first..."
        install_docker
    fi
    
    # Create project directory
    ensure_directory "n8n-docker"
    cd n8n-docker
    
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

    chmod +x start.sh stop.sh logs.sh
    
    print_status "Docker Compose setup created in ./n8n-docker/"
    print_status "Configuration files created:"
    print_status "  - docker-compose.yml (Main configuration)"
    print_status "  - .env (Environment variables)"
    print_status "  - start.sh (Start n8n)"
    print_status "  - stop.sh (Stop n8n)"
    print_status "  - logs.sh (View logs)"
    echo ""
    print_status "To start n8n:"
    echo "  cd n8n-docker && ./start.sh"
    print_status "To stop n8n:"
    echo "  cd n8n-docker && ./stop.sh"
    print_status "n8n will be available at: http://localhost:5678"
    print_warning "Default credentials: admin/changeme (change in .env file)"
}

# Function to create systemd service for n8n
create_n8n_service() {
    local service_file="/etc/systemd/system/n8n.service"
    local n8n_path=$(which n8n)
    local user=$(whoami)
    
    print_status "Creating systemd service for n8n..."
    
    sudo tee "$service_file" > /dev/null << EOF
[Unit]
Description=n8n workflow automation
After=network.target

[Service]
Type=simple
User=$user
ExecStart=$n8n_path
Restart=always
RestartSec=3
Environment=NODE_ENV=production
Environment=N8N_LOG_LEVEL=info

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable n8n
    
    print_status "Systemd service created successfully!"
    print_status "To start n8n service: sudo systemctl start n8n"
    print_status "To check status: sudo systemctl status n8n"
    print_status "To view logs: sudo journalctl -u n8n -f"
}