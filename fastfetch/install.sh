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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root directly. Use sudo when prompted."
        exit 1
    fi
}

# Function to check if sudo is available
check_sudo() {
    if ! command_exists sudo; then
        print_error "sudo is required but not installed. Please install sudo first."
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        print_warning "You will need to enter your password for sudo commands."
    fi
}

# Function to detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS. This script requires a Debian/Ubuntu-based system."
        exit 1
    fi
    
    if [[ ! "$OS" =~ (Ubuntu|Debian) ]]; then
        print_error "This script is designed for Ubuntu/Debian systems. Detected: $OS"
        print_warning "You may need to install FastFetch manually for your distribution."
        exit 1
    fi
}

# Function to check if FastFetch is already installed
check_existing_installation() {
    if command_exists fastfetch; then
        print_warning "FastFetch is already installed!"
        fastfetch --version
        echo
        read -p "Do you want to reinstall/update FastFetch? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled by user."
            exit 0
        fi
    fi
}

# Main installation function
install_fastfetch() {
    print_status "Starting FastFetch installation process..."
    
    # Update system
    print_status "Updating system packages..."
    if sudo apt update && sudo apt upgrade -y; then
        print_success "System updated successfully."
    else
        print_error "Failed to update system packages."
        exit 1
    fi
    
    # Add PPA and install FastFetch
    print_status "Adding FastFetch PPA repository..."
    if sudo add-apt-repository ppa:fastfetch/stable -y; then
        print_success "PPA added successfully."
    else
        print_error "Failed to add FastFetch PPA."
        exit 1
    fi
    
    print_status "Updating package list..."
    if sudo apt update; then
        print_success "Package list updated."
    else
        print_error "Failed to update package list."
        exit 1
    fi
    
    print_status "Installing FastFetch..."
    if sudo apt install fastfetch -y; then
        print_success "FastFetch installed successfully!"
    else
        print_error "Failed to install FastFetch."
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    if command_exists fastfetch; then
        print_success "FastFetch installation verified!"
        echo
        print_status "Running FastFetch for the first time..."
        fastfetch
    else
        print_error "FastFetch installation verification failed."
        exit 1
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
    
    # Countdown timer for disclaimer acknowledgment
    echo "Press Ctrl+C to stop this script, Enter to continue immediately, or wait 10 seconds to proceed..."
    for i in {10..1}; do
        echo -ne "\rContinuing in ${i} seconds... (Press Enter to skip countdown)"
        read -t 1 -n 1 key
        if [[ $key == "" ]]; then
            echo -e "\nProceeding with installation..."
            break
        fi
    done
    if [[ $i -eq 0 ]]; then
        echo -e "\nProceeding with installation..."
    fi
    echo
    print_status "This script will install FastFetch on your system."
    print_warning "Please ensure you have sudo privileges to run this script."
    echo
    
    # Pre-installation checks
    check_not_root
    check_sudo
    detect_os
    
    print_status "Detected OS: $OS $VER"
    echo
    
    check_existing_installation
    
    # Confirm installation
    read -p "Do you want to proceed with the installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "Installation cancelled by user."
        exit 0
    fi
    
    # Install FastFetch
    install_fastfetch
    
    # Verify installation
    verify_installation
    
    echo
    print_success "FastFetch installation completed successfully!"
    print_status "You can now run 'fastfetch' anytime to display system information."
}

# Run main function
main "$@"