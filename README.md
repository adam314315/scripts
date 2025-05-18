# Multi-Software Installation Script

A modular installation script system that supports installing various software packages with different installation methods.

## Directory Structure

```
installation-script/
├── script_setup.sh              # Main installation script
├── setup_directories.sh         # Script to create directory structure
├── README.md                     # This file
├── SCRIPT_LIBS/                  # Library functions
│   ├── README.md
│   ├── utils.sh                  # Utility functions (colors, confirmations, etc.)
│   └── system.sh                 # System detection and management
└── SCRIPT_SOFTS/                 # Software installation modules
    ├── README.md
    ├── n8n.sh                    # n8n workflow automation
    ├── php.sh                    # PHP programming language
    └── nodejs.sh                 # Node.js runtime (example)
```

## Quick Start

1. **Set up the directory structure:**
   ```bash
   chmod +x setup_directories.sh
   ./setup_directories.sh
   ```

2. **Move files to their appropriate directories:**
   - Move `utils.sh`, `system.sh` to `SCRIPT_LIBS/`
   - Move `n8n.sh`, `php.sh` to `SCRIPT_SOFTS/`
   - Note: `installers.sh` is no longer needed

3. **Run the installation script:**
   ```bash
   chmod +x script_setup.sh
   ./script_setup.sh
   ```

## Supported Software

### n8n (Workflow Automation)
- **npm installation** - Global installation via npm
- **Docker installation** - Single container setup
- **Docker Compose** - Production-ready with PostgreSQL

### PHP (Web Development Language)
- **LAMP Stack** - PHP with Apache
- **LEMP Stack** - PHP with Nginx  
- **CLI Only** - Command-line PHP
- **With Composer** - PHP with dependency manager

## Adding New Software

To add support for a new software package:

1. **Create a new file** in `SCRIPT_SOFTS/{software}.sh`

2. **Implement required functions:**
   ```bash
   # Display installation menu
   {software}_menu() {
       # Menu implementation
   }
   
   # Handle installation flow
   {software}_installation() {
       # Installation handler
   }
   
   # Specific installation methods
   install_{software}_{method}() {
       # Method implementation
   }
   ```

3. **Source the file** in `script_setup.sh`:
   ```bash
   source "${SCRIPT_SOFTS}/{software}.sh"
   ```

4. **Update the main menu** in `show_software_menu()` function

5. **Add case handler** in the main script loop

## Library Functions

### utils.sh
- `print_status()` - Print info messages
- `print_warning()` - Print warning messages  
- `print_error()` - Print error messages
- `print_header()` - Print header text
- `command_exists()` - Check if command exists
- `confirm()` - User confirmation prompts
- `ensure_directory()` - Create directory if needed

### system.sh
- `detect_os()` - Detect operating system
- `get_os_version()` - Get OS version
- `get_package_manager()` - Detect package manager
- `update_packages()` - Update package lists
- `install_package()` - Install system packages
- `check_system_requirements()` - Check system specs
- `is_firewall_active()` - Check firewall status
- `open_firewall_port()` - Configure firewall ports
- `check_port_open()` - Check if port is available
- `show_firewall_status()` - Display firewall info

## Features

- **Cross-platform support** - Linux (Debian/RedHat), macOS
- **Modular design** - Easy to add new software
- **Self-contained modules** - Each software handles its own dependencies
- **Error handling** - Graceful error management
- **User-friendly** - Colored output and confirmations
- **Production-ready** - Includes service creation and configuration
- **Firewall management** - Automatic port configuration
- **Flexible installation** - Custom directory selection

## Requirements

- Bash 4.0+
- sudo privileges (for system package installation)
- Internet connection (for downloading packages)

## License

This project is open source and available under the MIT License.