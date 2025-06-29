#!/bin/bash

# ============================================================================
# DISCLAIMER: This is a 3rd party installation script and has NO official
# affiliation with FastFetch or its developers. This script is provided
# "AS IS" without warranty. Use at your own discretion and risk.
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Enhanced error handling and debugging output
trap 'print_error "An unexpected error occurred. Exiting..."; exit 1' ERR

# Debugging function
print_debug() {
    echo -e "${YELLOW}[DEBUG]${NC} $1"
}

# Function to check if running as root and set sudo usage
check_root_and_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root user detected."
        print_status "The script will run directly without sudo commands."
        USE_SUDO=""
    else
        print_status "Running as regular user."
        # Check if sudo is available
        if ! command -v sudo >/dev/null 2>&1; then
            print_error "sudo is required but not installed. Please install sudo first or run as root."
            exit 1
        fi
        
        if ! sudo -n true 2>/dev/null; then
            print_warning "You will need to enter your password for sudo commands."
        fi
        USE_SUDO="sudo"
    fi
}

# Main script execution
main() {
    echo "=========================================="
    echo "         FastFetch Installer"
    echo "=========================================="
    echo
    echo "⚠️  DISCLAIMER: This is a 3rd party installation script and has NO official"
    echo "   affiliation with FastFetch or its developers. This script is provided"
    echo "   'AS IS' without warranty. Use at your own discretion and risk!"
    echo
    print_warning "DISCLAIMER: This is a 3rd party script with NO official"
    print_warning "affiliation to FastFetch. Use at your own discretion!"
    echo
    
    print_status "This script will install FastFetch on your system."
    print_warning "Please ensure you have sudo privileges to run this script."
    echo
    
    # Check root/sudo status
    check_root_and_sudo
    echo
    
    # Update system
    print_status "Updating system packages..."
    if $USE_SUDO apt update; then
        print_success "System packages updated successfully."
    else
        print_error "Failed to update system packages."
        exit 1
    fi
    
    # Install dependencies
    print_status "Installing build dependencies..."
    
    # Handle dpkg lock issue
    print_status "Checking for dpkg lock..."
    if lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
        print_warning "Another process is using the dpkg lock. Waiting for it to release..."
        while lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
            sleep 5
        done
        print_success "dpkg lock released. Proceeding with installation."
    else
        print_status "No dpkg lock detected. Proceeding with installation."
    fi
    
    if $USE_SUDO apt install git cmake gcc g++ libpci-dev libwayland-dev libx11-dev libxrandr-dev libxi-dev libgl1-mesa-dev -y; then
        print_success "Build dependencies installed successfully."
    else
        print_error "Failed to install build dependencies."
        exit 1
    fi
    
    # Ensure C++ compiler is installed
    print_status "Checking for C++ compiler..."
    if ! command -v g++ >/dev/null 2>&1; then
        print_warning "C++ compiler not found. Installing g++..."
        if $USE_SUDO apt install g++ -y; then
            print_success "C++ compiler installed successfully."
        else
            print_error "Failed to install C++ compiler. Please check your package manager or install it manually."
            exit 1
        fi
    else
        print_success "C++ compiler is already installed."
    fi
    
    # Clone FastFetch repository
    print_status "Cloning FastFetch repository..."
    
    # Remove existing directory if it exists
    if [[ -d "fastfetch" ]]; then
        print_warning "Existing FastFetch directory found. Removing it..."
        rm -rf fastfetch || { print_error "Failed to remove existing FastFetch directory."; exit 1; }
    fi
    
    if git clone https://github.com/fastfetch-cli/fastfetch.git; then
        print_success "FastFetch repository cloned successfully."
    else
        print_error "Failed to clone FastFetch repository. Check your internet connection or Git configuration."
        exit 1
    fi
    
    # Build FastFetch
    print_status "Building FastFetch from source..."
    cd fastfetch || { print_error "Failed to enter FastFetch directory."; exit 1; }
    if mkdir build && cd build && cmake .. && make -j$(nproc); then
        print_success "FastFetch built successfully."
    else
        print_error "Failed to build FastFetch. Check the output above for errors and ensure all dependencies are installed."
        exit 1
    fi

    # Install FastFetch
    print_status "Installing FastFetch..."
    if $USE_SUDO make install; then
        print_success "FastFetch installed successfully!"
    else
        print_error "Failed to install FastFetch. Ensure you have sufficient permissions and check the output above for errors."
        exit 1
    fi
    
    # Cleanup
    print_status "Cleaning up build files..."
    cd ../.. || { print_error "Failed to return to the parent directory."; exit 1; }
    rm -rf fastfetch || { print_error "Failed to clean up FastFetch directory."; exit 1; }
    print_success "Cleanup completed."
    
    echo
    print_success "FastFetch installation completed successfully!"
    print_status "You can now run 'fastfetch' anytime to display system information."
    echo
    print_status "Running FastFetch for the first time..."
    fastfetch
}

# Run main function
main "$@"