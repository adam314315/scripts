#!/bin/bash

# Main Installation Script
# Supports installation of various software packages

set -e  # Exit on any error

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define library and software directories
SCRIPT_LIBS="${SCRIPT_DIR}/SCRIPT_LIBS"
SCRIPT_SOFTS="${SCRIPT_DIR}/SCRIPT_SOFTS"

# Source library files
source "${SCRIPT_LIBS}/utils.sh"
source "${SCRIPT_LIBS}/system.sh"
source "${SCRIPT_LIBS}/installers.sh"

# Note: Software modules are sourced dynamically in main()

# Function to get available software modules
get_available_software() {
    local software_list=()
    local counter=1
    
    # Find all .sh files in SCRIPT_SOFTS directory
    for file in "${SCRIPT_SOFTS}"/*.sh; do
        if [ -f "$file" ]; then
            # Extract filename without path and extension
            local software_name=$(basename "$file" .sh)
            
            # Check if the required functions exist
            if declare -f "${software_name}_menu" >/dev/null 2>&1 && \
               declare -f "${software_name}_installation" >/dev/null 2>&1; then
                software_list+=("$software_name")
            fi
        fi
    done
    
    echo "${software_list[@]}"
}

# Function to get software description
get_software_description() {
    local software="$1"
    local software_file="${SCRIPT_SOFTS}/${software}.sh"
    
    # Try to extract description from the software file
    if [ -f "$software_file" ]; then
        # Look for a comment line with "Description:" or "DESC:" in the file
        local description=$(grep -i "^# Description:\|^# DESC:" "$software_file" 2>/dev/null | head -n1 | sed 's/^# [Dd]escription: *//i' | sed 's/^# [Dd]esc: *//i')
        
        if [ -n "$description" ]; then
            echo "$description"
            return
        fi
        
        # Alternative: Look for a description function
        if declare -f "${software}_description" >/dev/null 2>&1; then
            "${software}_description"
            return
        fi
    fi
    
    # Fallback: Use filename with capitalized first letter
    echo "$(echo "${software^}" | sed 's/[_-]/ /g') Package"
}

# Function to display dynamic software menu
show_software_menu() {
    print_header "========================================="
    print_header "        Software Installation Script    "
    print_header "========================================="
    echo ""
    echo "Which software do you want to install?"
    echo ""
    
    # Get available software
    local software_array=($(get_available_software))
    local counter=1
    
    # Display available software options
    for software in "${software_array[@]}"; do
        local description=$(get_software_description "$software")
        echo "$counter) $software ($description)"
        ((counter++))
    done
    
    echo "$counter) Exit"
    echo ""
    
    # Store the software array for use in main function
    AVAILABLE_SOFTWARE=("${software_array[@]}")
    MAX_CHOICE=$counter
}

# Function to call software installation dynamically
call_software_installation() {
    local software="$1"
    local func_name="${software}_installation"
    
    if declare -f "$func_name" >/dev/null 2>&1; then
        "$func_name"
    else
        print_error "Installation function '$func_name' not found for software '$software'"
        return 1
    fi
}

# Main script execution
main() {
    print_header "Welcome to the Software Installation Script!"
    echo ""
    
    # Source all available software modules
    for file in "${SCRIPT_SOFTS}"/*.sh; do
        if [ -f "$file" ]; then
            source "$file"
        fi
    done
    
    while true; do
        show_software_menu
        read -p "Enter your choice (1-$MAX_CHOICE): " choice
        
        # Validate input
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$MAX_CHOICE" ]; then
            print_error "Invalid choice. Please enter a number between 1 and $MAX_CHOICE."
            echo ""
            continue
        fi
        
        # Handle exit choice
        if [ "$choice" -eq "$MAX_CHOICE" ]; then
            print_status "Installation cancelled."
            exit 0
        fi
        
        # Get selected software
        local selected_software="${AVAILABLE_SOFTWARE[$((choice-1))]}"
        
        # Call installation function
        if call_software_installation "$selected_software"; then
            print_status "Installation completed successfully!"
            print_status "Visit the documentation for more information."
            break
        fi
        # If function returns 1, continue to main menu
    done
}

# Run the main function
main "$@"