#!/bin/bash

# PHP Installation Functions
# Description: Web Development Language
# Contains all PHP-specific installation methods and configurations

# Function to install Python for PHP (if needed)
install_python_for_php() {
    local os=$(detect_os)
    print_status "Installing Python for PHP build tools..."
    
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

# Function to install Git for PHP (if needed)
install_git_for_php() {
    local os=$(detect_os)
    print_status "Installing Git for PHP..."
    
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

# Function to display PHP installation menu
php_menu() {
    print_header "========================================="
    print_header "          PHP Installation Options       "
    print_header "========================================="
    echo ""
    echo "Choose your preferred installation method:"
    echo ""
    echo "1) Install PHP with Apache (LAMP Stack)"
    echo "2) Install PHP with Nginx (LEMP Stack)"
    echo "3) Install PHP CLI only"
    echo "4) Install PHP with Composer"
    echo "5) Back to main menu"
    echo ""
}

# Function to handle PHP installation
php_installation() {
    while true; do
        php_menu
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            1)
                install_php_apache
                return 0
                ;;
            2)
                install_php_nginx
                return 0
                ;;
            3)
                install_php_cli
                return 0
                ;;
            4)
                install_php_composer
                return 0
                ;;
            5)
                return 1  # Go back to main menu
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, 3, 4, or 5."
                echo ""
                ;;
        esac
    done
}

# Function to install PHP with Apache (LAMP)
install_php_apache() {
    print_status "Installing PHP with Apache (LAMP Stack)..."
    
    # Check system requirements
    check_system_requirements
    
    # Get web root directory
    local default_webroot="./www"
    local webroot_dir=$(get_installation_directory "web files (Apache document root)" "$default_webroot" "web content")
    
    local os=$(detect_os)
    case $os in
        "debian")
            update_packages
            install_package "apache2"
            install_package "php"
            install_package "libapache2-mod-php"
            install_package "php-mysql"
            install_package "php-curl"
            install_package "php-gd"
            install_package "php-json"
            install_package "php-mbstring"
            install_package "php-xml"
            install_package "php-zip"
            
            # Enable PHP module
            sudo a2enmod php$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
            
            # Configure Apache document root
            print_status "Configuring Apache document root to: $webroot_dir"
            setup_installation_directory "$webroot_dir" "Apache web root"
            
            # Get absolute path for Apache configuration
            local absolute_webroot=$(realpath "$webroot_dir")
            
            # Update Apache configuration
            sudo sed -i "s|DocumentRoot /var/www/html|DocumentRoot $absolute_webroot|g" /etc/apache2/sites-available/000-default.conf
            sudo sed -i "s|<Directory /var/www/>|<Directory $absolute_webroot/>|g" /etc/apache2/apache2.conf
            
            sudo systemctl restart apache2
            ;;
        "redhat")
            update_packages
            install_package "httpd"
            install_package "php"
            install_package "php-mysql"
            install_package "php-curl"
            install_package "php-gd"
            install_package "php-json"
            install_package "php-mbstring"
            install_package "php-xml"
            install_package "php-zip"
            
            # Configure Apache document root
            print_status "Configuring Apache document root to: $webroot_dir"
            setup_installation_directory "$webroot_dir" "Apache web root"
            
            # Get absolute path for Apache configuration
            local absolute_webroot=$(realpath "$webroot_dir")
            
            # Update Apache configuration
            sudo sed -i "s|DocumentRoot \"/var/www/html\"|DocumentRoot \"$absolute_webroot\"|g" /etc/httpd/conf/httpd.conf
            sudo sed -i "s|<Directory \"/var/www\">|<Directory \"$absolute_webroot\">|g" /etc/httpd/conf/httpd.conf
            
            sudo systemctl start httpd
            sudo systemctl enable httpd
            ;;
        "macos")
            if command_exists brew; then
                brew install php
                brew install httpd
                setup_installation_directory "$webroot_dir" "Apache web root"
                print_status "Please configure Apache manually for macOS."
                print_status "Document root will be: $(realpath "$webroot_dir")"
            else
                print_error "Homebrew not found. Please install Homebrew first."
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported operating system for automatic installation."
            exit 1
            ;;
    esac
    
    # Configure firewall for HTTP
    print_status "Configuring firewall for Apache..."
    open_firewall_port 80 tcp "Apache HTTP"
    
    # Create a simple test file
    create_php_info_file "$webroot_dir"
    
    print_status "PHP with Apache installed successfully!"
    print_status "Document root: $webroot_dir"
    print_status "Test PHP: http://localhost/info.php"
    print_status "PHP version: $(php -v | head -n 1)"
    
    # Show firewall status
    if is_firewall_active; then
        show_firewall_status
    fi
}

# Function to install PHP with Nginx (LEMP)
install_php_nginx() {
    print_status "Installing PHP with Nginx (LEMP Stack)..."
    
    # Check system requirements
    check_system_requirements
    
    # Get web root directory
    local default_webroot="./www"
    local webroot_dir=$(get_installation_directory "web files (Nginx document root)" "$default_webroot" "web content")
    
    local os=$(detect_os)
    case $os in
        "debian")
            update_packages
            install_package "nginx"
            install_package "php-fpm"
            install_package "php-mysql"
            install_package "php-curl"
            install_package "php-gd"
            install_package "php-json"
            install_package "php-mbstring"
            install_package "php-xml"
            install_package "php-zip"
            
            # Configure Nginx for PHP
            configure_nginx_php "$webroot_dir"
            
            sudo systemctl start nginx
            sudo systemctl enable nginx
            sudo systemctl start php*-fpm
            sudo systemctl enable php*-fpm
            ;;
        "redhat")
            update_packages
            install_package "nginx"
            install_package "php-fpm"
            install_package "php-mysql"
            install_package "php-curl"
            install_package "php-gd"
            install_package "php-json"
            install_package "php-mbstring"
            install_package "php-xml"
            install_package "php-zip"
            
            # Configure Nginx for PHP
            configure_nginx_php "$webroot_dir"
            
            sudo systemctl start nginx
            sudo systemctl enable nginx
            sudo systemctl start php-fpm
            sudo systemctl enable php-fpm
            ;;
        "macos")
            if command_exists brew; then
                brew install php
                brew install nginx
                setup_installation_directory "$webroot_dir" "Nginx web root"
                print_status "Please configure Nginx manually for macOS."
                print_status "Document root will be: $(realpath "$webroot_dir")"
            else
                print_error "Homebrew not found. Please install Homebrew first."
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported operating system for automatic installation."
            exit 1
            ;;
    esac
    
    # Configure firewall for HTTP
    print_status "Configuring firewall for Nginx..."
    open_firewall_port 80 tcp "Nginx HTTP"
    
    # Create a simple test file
    create_php_info_file "$webroot_dir"
    
    print_status "PHP with Nginx installed successfully!"
    print_status "Document root: $webroot_dir"
    print_status "Test PHP: http://localhost/info.php"
    print_status "PHP version: $(php -v | head -n 1)"
    
    # Show firewall status
    if is_firewall_active; then
        show_firewall_status
    fi
}

# Function to install PHP CLI only
install_php_cli() {
    print_status "Installing PHP CLI..."
    
    # Check system requirements
    check_system_requirements
    
    local os=$(detect_os)
    case $os in
        "debian")
            update_packages
            install_package "php-cli"
            install_package "php-curl"
            install_package "php-json"
            install_package "php-mbstring"
            install_package "php-xml"
            install_package "php-zip"
            ;;
        "redhat")
            update_packages
            install_package "php-cli"
            install_package "php-curl"
            install_package "php-json"
            install_package "php-mbstring"
            install_package "php-xml"
            install_package "php-zip"
            ;;
        "macos")
            if command_exists brew; then
                brew install php
            else
                print_error "Homebrew not found. Please install Homebrew first."
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported operating system for automatic installation."
            exit 1
            ;;
    esac
    
    print_status "PHP CLI installed successfully!"
    print_status "PHP version: $(php -v | head -n 1)"
    print_status "Usage: php script.php"
}

# Function to install PHP with Composer
install_php_composer() {
    print_status "Installing PHP with Composer..."
    
    # First install PHP CLI
    install_php_cli
    
    # Install Composer
    print_status "Installing Composer..."
    
    # Download and install Composer
    cd /tmp
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    
    # Verify installer
    HASH="$(curl -sS https://composer.github.io/installer.sig)"
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    
    # Install Composer globally
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    
    # Clean up
    rm composer-setup.php
    
    print_status "PHP with Composer installed successfully!"
    print_status "PHP version: $(php -v | head -n 1)"
    print_status "Composer version: $(composer --version)"
    print_status "Usage: composer init"
}

# Function to configure Nginx for PHP
configure_nginx_php() {
    local webroot_dir="${1:-./www}"
    print_status "Configuring Nginx for PHP..."
    
    # Setup web root directory
    setup_installation_directory "$webroot_dir" "Nginx web root"
    
    # Get absolute path for Nginx configuration
    local absolute_webroot=$(realpath "$webroot_dir")
    
    # Create a simple Nginx configuration for PHP
    cat > /tmp/default.conf << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root $absolute_webroot;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Backup existing configuration
    if [ -f /etc/nginx/sites-available/default ]; then
        sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    fi
    
    # Install new configuration
    sudo cp /tmp/default.conf /etc/nginx/sites-available/default
    rm /tmp/default.conf
    
    # Test Nginx configuration
    sudo nginx -t
}

# Function to create PHP info file
create_php_info_file() {
    local doc_root="${1:-/var/www/html}"
    
    print_status "Creating PHP info file..."
    
    # Ensure directory exists
    ensure_directory "$doc_root"
    
    # Create info.php file
    cat > /tmp/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

    sudo cp /tmp/info.php "$doc_root/info.php"
    rm /tmp/info.php
    
    # Set proper permissions
    sudo chown www-data:www-data "$doc_root/info.php" 2>/dev/null || true
    sudo chmod 644 "$doc_root/info.php"
    
    print_status "PHP info file created at: $doc_root/info.php"
}

# Function to show PHP information and resources
show_php_info() {
    print_header "PHP Resources and Information"
    echo ""
    print_status "Official Documentation: https://www.php.net/docs.php"
    print_status "Package Repository: https://packagist.org/"
    print_status "Laravel Framework: https://laravel.com/"
    print_status "Symfony Framework: https://symfony.com/"
    print_status "WordPress: https://wordpress.org/"
    echo ""
    print_status "Common PHP Extensions:"
    print_status "  - php-mysql (MySQL support)"
    print_status "  - php-curl (cURL support)"
    print_status "  - php-gd (Image processing)"
    print_status "  - php-mbstring (Multibyte string support)"
    print_status "  - php-xml (XML support)"
    print_status "  - php-zip (ZIP archive support)"
    echo ""
    print_status "Configuration files:"
    print_status "  - CLI: $(php --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)"
    print_status "  - Apache/Nginx: Check phpinfo() for paths"
    echo ""
}