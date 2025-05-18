#!/bin/bash

# n8n Installation Functions
# Description: Workflow Automation Platform
# Contains all n8n-specific installation methods and configurations

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

    cat > backup.sh << 'EOF'
#!/bin/bash
echo "Creating backup of n8n data..."
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
docker-compose exec -T postgres pg_dump -U n8n n8n > "$BACKUP_DIR/postgres_backup.sql"
echo "Backup created in: $BACKUP_DIR"
EOF

    chmod +x start.sh stop.sh logs.sh backup.sh
    
    print_status "Docker Compose setup created in ./n8n-docker/"
    print_status "Configuration files created:"
    print_status "  - docker-compose.yml (Main configuration)"
    print_status "  - .env (Environment variables)"
    print_status "  - start.sh (Start n8n)"
    print_status "  - stop.sh (Stop n8n)"
    print_status "  - logs.sh (View logs)"
    print_status "  - backup.sh (Backup database)"
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