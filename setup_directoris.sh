#!/bin/bash

# Setup Script - Creates the directory structure for the installation script
# Run this script first to set up the proper directory structure

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define directories
SCRIPT_LIBS="${SCRIPT_DIR}/SCRIPT_LIBS"
SCRIPT_SOFTS="${SCRIPT_DIR}/SCRIPT_SOFTS"

echo "Setting up installation script directory structure..."

# Create directories
mkdir -p "${SCRIPT_LIBS}"
mkdir -p "${SCRIPT_SOFTS}"

echo "Directory structure created:"
echo "  ${SCRIPT_LIBS}/    - Library functions (utils, system, installers)"
echo "  ${SCRIPT_SOFTS}/   - Software installation modules"
echo ""

# Create a simple README for each directory
cat > "${SCRIPT_LIBS}/README.md" << 'EOF'
# SCRIPT_LIBS Directory

This directory contains library functions used across all software installations:

- **utils.sh** - Utility functions (printing, confirmation, directory management)
- **system.sh** - System detection and management functions
- **installers.sh** - General dependency installation functions (Node.js, Docker, Python, Git)

These files provide core functionality that can be reused by any software installation module.
EOF

cat > "${SCRIPT_SOFTS}/README.md" << 'EOF'
# SCRIPT_SOFTS Directory

This directory contains software-specific installation modules:

- **n8n.sh** - n8n workflow automation installation
- **php.sh** - PHP programming language installation

Each software module should follow the naming convention:
- `{software}_menu()` - Display installation options
- `{software}_installation()` - Handle installation flow
- `install_{software}_{method}()` - Specific installation methods

To add a new software:
1. Create `{software}.sh` in this directory
2. Implement the required functions following the established patterns
3. Source the file in the main `script_setup.sh`
4. Add the software option to the main menu
EOF

echo "Setup complete! You can now organize your files as follows:"
echo ""
echo "Move to SCRIPT_LIBS/:"
echo "  - utils.sh"
echo "  - system.sh" 
echo "  - installers.sh"
echo ""
echo "Move to SCRIPT_SOFTS/:"
echo "  - n8n.sh"
echo "  - php.sh"
echo ""
echo "Keep in main directory:"
echo "  - script_setup.sh (main script)"
echo "  - setup_directories.sh (this script)"
echo ""
echo "After moving files, run: ./script_setup.sh"