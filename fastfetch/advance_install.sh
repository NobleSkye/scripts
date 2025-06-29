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
check_root_and_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root user detected."
        print_status "The script will run directly without sudo commands."
        USE_SUDO=""
    else
        print_status "Running as regular user."
        # Check if sudo is available
        if ! command_exists sudo; then
            print_error "sudo is required but not installed. Please install sudo first or run as root."
            exit 1
        fi
        
        if ! sudo -n true 2>/dev/null; then
            print_warning "You will need to enter your password for sudo commands."
        fi
        USE_SUDO="sudo"
    fi
}

# Function to detect OS
detect_os() {
    print_status "Detecting operating system..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_ID=$ID
        
        print_success "Detected OS: $OS_NAME $OS_VERSION"
        
        # Check if it's a supported distribution
        case $OS_ID in
            ubuntu|debian|linuxmint|pop|elementary|zorin)
                print_success "Supported Debian/Ubuntu-based distribution detected."
                INSTALL_METHOD="apt"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                print_warning "Red Hat-based distribution detected."
                print_warning "This script is designed for Debian/Ubuntu. You may need to install manually."
                INSTALL_METHOD="dnf"
                ;;
            arch|manjaro|endeavouros)
                print_warning "Arch-based distribution detected."
                print_warning "This script is designed for Debian/Ubuntu. You may need to install manually."
                INSTALL_METHOD="pacman"
                ;;
            opensuse*|sles)
                print_warning "openSUSE-based distribution detected."
                print_warning "This script is designed for Debian/Ubuntu. You may need to install manually."
                INSTALL_METHOD="zypper"
                ;;
            *)
                print_warning "Unknown or unsupported distribution: $OS_NAME"
                print_warning "This script is designed for Debian/Ubuntu systems."
                INSTALL_METHOD="unknown"
                ;;
        esac
        
        if [[ "$INSTALL_METHOD" != "apt" ]]; then
            echo
            read -p "Do you want to continue anyway? This may not work properly (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Installation cancelled by user."
                exit 0
            fi
        fi
        
    else
        print_error "Cannot detect OS. /etc/os-release file not found."
        print_error "This script requires a modern Linux distribution."
        exit 1
    fi
}

# Function to check if FastFetch is already installed
check_existing_installation() {
    if command_exists fastfetch; then
        print_warning "FastFetch is already installed!"
        fastfetch --version 2>/dev/null || echo "Version information not available"
        echo
        read -p "Do you want to reinstall/update FastFetch? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled by user."
            exit 0
        fi
    fi
}

# Function to handle neofetch removal
handle_neofetch_removal() {
    if command_exists neofetch; then
        print_warning "Neofetch is currently installed on your system."
        echo
        read -p "Do you want to remove neofetch? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Removing neofetch..."
            case $INSTALL_METHOD in
                apt)
                    if $USE_SUDO apt remove neofetch -y && $USE_SUDO apt autoremove -y; then
                        print_success "Neofetch removed successfully!"
                    else
                        print_warning "Failed to remove neofetch, but continuing with installation."
                    fi
                    ;;
                dnf)
                    if $USE_SUDO dnf remove neofetch -y; then
                        print_success "Neofetch removed successfully!"
                    else
                        print_warning "Failed to remove neofetch, but continuing with installation."
                    fi
                    ;;
                pacman)
                    if $USE_SUDO pacman -R neofetch --noconfirm; then
                        print_success "Neofetch removed successfully!"
                    else
                        print_warning "Failed to remove neofetch, but continuing with installation."
                    fi
                    ;;
                *)
                    print_warning "Cannot automatically remove neofetch on this system."
                    print_status "Please remove it manually if desired."
                    ;;
            esac
        else
            print_status "Keeping neofetch installed."
        fi
    else
        print_status "Neofetch is not currently installed."
    fi
}

# Function to create neofetch alias
create_neofetch_alias() {
    print_status "Creating neofetch alias for FastFetch..."
    
    # Determine shell configuration file
    local shell_config=""
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        shell_config="$HOME/.bashrc"
    elif [[ "$SHELL" == *"fish"* ]]; then
        shell_config="$HOME/.config/fish/config.fish"
        print_status "Fish shell detected. Creating Fish alias..."
    else
        shell_config="$HOME/.bashrc"  # Default fallback
    fi
    
    # Create config directory if it doesn't exist (for fish)
    if [[ "$shell_config" == *"fish"* ]]; then
        mkdir -p "$(dirname "$shell_config")"
    fi
    
    # Check if alias already exists
    if [[ -f "$shell_config" ]] && grep -q "neofetch" "$shell_config" 2>/dev/null; then
        print_warning "Neofetch alias/function already exists in $shell_config"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Remove existing alias/function
            if [[ "$shell_config" == *"fish"* ]]; then
                sed -i '/function neofetch/,/end/d' "$shell_config" 2>/dev/null || true
            else
                sed -i '/alias neofetch=/d' "$shell_config"
            fi
        else
            print_status "Keeping existing neofetch alias."
            return
        fi
    fi
    
    # Add new alias/function
    if [[ "$shell_config" == *"fish"* ]]; then
        echo "function neofetch" >> "$shell_config"
        echo "    fastfetch \$argv" >> "$shell_config"
        echo "end" >> "$shell_config"
        print_success "Neofetch function added to $shell_config"
    else
        echo "alias neofetch='fastfetch'" >> "$shell_config"
        print_success "Neofetch alias added to $shell_config"
    fi
    
    # Ask about system-wide command
    echo
    read -p "Do you want to create a system-wide neofetch command? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if $USE_SUDO ln -sf "$(which fastfetch)" /usr/local/bin/neofetch 2>/dev/null; then
            print_success "System-wide neofetch command created!"
        else
            print_warning "Failed to create system-wide neofetch command, but shell alias was created."
        fi
    fi
    
    print_status "You may need to restart your terminal or run 'source $shell_config' for the alias to take effect."
}

# Function to handle neofetch alias creation
handle_neofetch_alias() {
    echo
    read -p "Do you want to create an alias so 'neofetch' command runs FastFetch? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        create_neofetch_alias
    else
        print_status "Skipping neofetch alias creation."
    fi
}

# Function to install FastFetch
install_fastfetch() {
    print_status "Starting FastFetch installation process..."
    
    case $INSTALL_METHOD in
        apt)
            # Check if we can update system packages
            print_status "Checking system update permissions..."
            
            # Test if we can run apt update
            if $USE_SUDO apt list --upgradable >/dev/null 2>&1; then
                print_success "System update permissions verified."
                echo
                read -p "Do you want to update system packages before installing FastFetch? (Y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    print_status "Updating system packages..."
                    if $USE_SUDO apt update && $USE_SUDO apt upgrade -y; then
                        print_success "System updated successfully."
                    else
                        print_warning "System update failed, but continuing with FastFetch installation..."
                    fi
                else
                    print_status "Skipping system update."
                fi
            else
                print_warning "Cannot update system packages due to insufficient permissions or repository issues."
                print_status "Continuing with FastFetch installation without system update..."
            fi
            
            echo
            
            # Add FastFetch PPA
            print_status "Adding FastFetch PPA repository..."
            if $USE_SUDO add-apt-repository ppa:fastfetch/stable -y; then
                print_success "FastFetch PPA added successfully."
            else
                print_error "Failed to add FastFetch PPA."
                exit 1
            fi
            
            # Update package list
            print_status "Updating package list..."
            if $USE_SUDO apt update; then
                print_success "Package list updated successfully."
            else
                print_error "Failed to update package list."
                exit 1
            fi
            
            # Install FastFetch
            print_status "Installing FastFetch..."
            if $USE_SUDO apt install fastfetch -y; then
                print_success "FastFetch installed successfully!"
            else
                print_error "Failed to install FastFetch."
                exit 1
            fi
            ;;
        *)
            print_error "Automatic installation not supported for this distribution."
            print_status "Please visit https://github.com/fastfetch-cli/fastfetch for manual installation instructions."
            exit 1
            ;;
    esac
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
    echo "       Advanced FastFetch Installer"
    echo "=========================================="
    echo
    echo "⚠️  DISCLAIMER: This is a 3rd party installation script and has NO official"
    echo "   affiliation with FastFetch or its developers. This script is provided"
    echo "   'AS IS' without warranty. Use at your own discretion and risk!"
    echo
    print_warning "DISCLAIMER: This is a 3rd party script with NO official"
    print_warning "affiliation to FastFetch. Use at your own discretion!"
    echo
    
    print_status "This advanced script will install FastFetch with additional options."
    print_warning "Please ensure you have sudo privileges to run this script."
    echo
    
    # Pre-installation checks
    check_root_and_sudo
    detect_os
    
    echo
    check_existing_installation
    
    # User options
    echo
    print_status "Configuration Options:"
    handle_neofetch_removal
    handle_neofetch_alias
    
    # Confirm installation
    echo
    read -p "Do you want to proceed with the FastFetch installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "Installation cancelled by user."
        exit 0
    fi
    
    # Install FastFetch
    echo
    install_fastfetch
    
    # Verify installation
    echo
    verify_installation
    
    echo
    print_success "Advanced FastFetch installation completed successfully!"
    print_status "You can now run 'fastfetch' anytime to display system information."
    
    if command_exists neofetch && [[ -L /usr/local/bin/neofetch || -f "$HOME/.bashrc" && $(grep -c "neofetch" "$HOME/.bashrc") -gt 0 ]]; then
        print_status "You can also use 'neofetch' command to run FastFetch."
    fi
}

# Run main function
main "$@"
