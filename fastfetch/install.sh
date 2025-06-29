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
    
    # Update and upgrade system
    print_status "Updating and upgrading system packages..."
    if sudo apt update && sudo apt upgrade -y; then
        print_success "System updated and upgraded successfully."
    else
        print_error "Failed to update and upgrade system packages."
        exit 1
    fi
    
    # Add FastFetch PPA
    print_status "Adding FastFetch PPA repository..."
    if sudo add-apt-repository ppa:fastfetch/stable -y; then
        print_success "FastFetch PPA added successfully."
    else
        print_error "Failed to add FastFetch PPA."
        exit 1
    fi
    
    # Update package list
    print_status "Updating package list..."
    if sudo apt update; then
        print_success "Package list updated successfully."
    else
        print_error "Failed to update package list."
        exit 1
    fi
    
    # Install FastFetch
    print_status "Installing FastFetch..."
    if sudo apt install fastfetch -y; then
        print_success "FastFetch installed successfully!"
    else
        print_error "Failed to install FastFetch."
        exit 1
    fi
    
    echo
    print_success "FastFetch installation completed successfully!"
    print_status "You can now run 'fastfetch' anytime to display system information."
    echo
    print_status "Running FastFetch for the first time..."
    fastfetch
}

# Run main function
main "$@"