#!/bin/bash

# Exline Programming Language Uninstaller
# Version: 0.2.0
# Removes all Exline installations from the system

set -e

# Configuration
EXLINE_VERSION="0.2.0"
BINARY_NAME="exline"
SYSTEM_INSTALL_DIR="/usr/local/bin"
PORTABLE_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/exline"
EXAMPLES_DIR="$HOME/.local/share/exline/examples"
USER_EXAMPLES_DIR="$HOME/.exline"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check for sudo when needed
check_sudo() {
    if [[ ! -w "$SYSTEM_INSTALL_DIR" ]] && [[ -f "$SYSTEM_INSTALL_DIR/$BINARY_NAME" ]]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO_PREFIX="sudo"
            print_status "System uninstallation requires sudo privileges"
        else
            print_error "Cannot remove system installation: sudo not available"
            return 1
        fi
    else
        SUDO_PREFIX=""
    fi
}

# Function to remove system installation
remove_system_install() {
    if [[ -f "$SYSTEM_INSTALL_DIR/$BINARY_NAME" ]]; then
        print_status "Found system installation: $SYSTEM_INSTALL_DIR/$BINARY_NAME"

        if [[ -n "$SUDO_PREFIX" ]]; then
            print_status "Removing system installation (requires sudo)..."
        else
            print_status "Removing system installation..."
        fi

        $SUDO_PREFIX rm -f "$SYSTEM_INSTALL_DIR/$BINARY_NAME"

        if [[ $? -eq 0 ]]; then
            print_success "System installation removed successfully"
            return 0
        else
            print_error "Failed to remove system installation"
            return 1
        fi
    else
        print_status "No system installation found"
        return 1
    fi
}

# Function to remove portable installation
remove_portable_install() {
    local found_portable=0

    if [[ -f "$PORTABLE_DIR/$BINARY_NAME" ]]; then
        print_status "Found portable installation: $PORTABLE_DIR/$BINARY_NAME"
        rm -f "$PORTABLE_DIR/$BINARY_NAME"
        print_success "Portable binary removed"
        found_portable=1
    fi

    # Remove portable configuration
    if [[ -d "$CONFIG_DIR" ]]; then
        print_status "Found portable configuration: $CONFIG_DIR"
        echo
        read -p "Remove portable configuration directory? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            rm -rf "$CONFIG_DIR"
            print_success "Portable configuration removed"
        fi
        found_portable=1
    fi

    # Remove portable examples
    if [[ -d "$EXAMPLES_DIR" ]]; then
        print_status "Found portable examples: $EXAMPLES_DIR"
        echo
        read -p "Remove portable examples directory? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            rm -rf "$EXAMPLES_DIR"
            print_success "Portable examples removed"
        fi
        found_portable=1
    fi

    if [[ $found_portable -eq 1 ]]; then
        return 0
    else
        print_status "No portable installation found"
        return 1
    fi
}

# Function to remove legacy examples
remove_legacy_examples() {
    if [[ -d "$USER_EXAMPLES_DIR" ]]; then
        print_status "Found legacy examples: $USER_EXAMPLES_DIR"
        echo
        read -p "Remove legacy examples directory? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            rm -rf "$USER_EXAMPLES_DIR"
            print_success "Legacy examples removed"
        fi
        return 0
    else
        return 1
    fi
}

# Function to clean up PATH modifications
cleanup_path() {
    print_status "Checking for PATH modifications..."

    local shell_configs=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.config/fish/config.fish"
    )

    local found_modifications=0

    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]] && grep -q "Added by Exline installer" "$config"; then
            print_warning "Found Exline PATH modifications in: $config"
            found_modifications=1
        fi
    done

    if [[ $found_modifications -eq 1 ]]; then
        echo
        print_warning "PATH modifications were found in your shell configuration files."
        print_status "These modifications add Exline to your PATH environment variable."
        echo
        read -p "Would you like to remove these PATH modifications? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for config in "${shell_configs[@]}"; do
                if [[ -f "$config" ]] && grep -q "Added by Exline installer" "$config"; then
                    print_status "Cleaning up PATH in: $config"

                    # Create backup
                    cp "$config" "${config}.backup.$(date +%Y%m%d_%H%M%S)"

                    # Remove Exline-related lines
                    if command -v sed >/dev/null 2>&1; then
                        sed -i '/# Added by Exline installer/,+2d' "$config"
                    else
                        grep -v -A2 "# Added by Exline installer" "$config" > "${config}.tmp" && mv "${config}.tmp" "$config"
                    fi

                    print_success "PATH cleaned up in: $config"
                fi
            done
            print_status "Please restart your terminal for PATH changes to take effect."
        else
            print_status "PATH modifications left unchanged."
            print_status "You can manually remove lines containing 'Added by Exline installer' from your shell config files."
        fi
    else
        print_status "No PATH modifications found."
    fi
}

# Function to verify complete removal
verify_removal() {
    print_status "Verifying complete removal..."

    local installations_found=0

    # Check for any remaining binaries
    if command -v exline >/dev/null 2>&1; then
        local exline_path=$(which exline)
        print_warning "Exline command still available at: $exline_path"
        installations_found=1
    fi

    # Check common installation directories
    local check_dirs=(
        "$SYSTEM_INSTALL_DIR"
        "$PORTABLE_DIR"
        "$HOME/bin"
        "/opt/exline"
        "/usr/bin"
    )

    for dir in "${check_dirs[@]}"; do
        if [[ -f "$dir/$BINARY_NAME" ]]; then
            print_warning "Found remaining binary: $dir/$BINARY_NAME"
            installations_found=1
        fi
    done

    if [[ $installations_found -eq 0 ]]; then
        print_success "Complete removal verified - no Exline installations found"
    else
        print_warning "Some Exline installations may still remain"
        print_status "You may need to manually remove remaining files or restart your terminal"
    fi
}

# Main uninstallation process
main() {
    echo "=========================================="
    echo "  Exline Programming Language"
    echo "  Uninstaller v$EXLINE_VERSION"
    echo "=========================================="
    echo

    print_status "Starting complete uninstallation process..."
    echo

    local found_installations=0

    # Check for system installation
    check_sudo
    if remove_system_install; then
        found_installations=1
    fi

    echo

    # Check for portable installation
    if remove_portable_install; then
        found_installations=1
    fi

    echo

    # Check for legacy examples
    remove_legacy_examples

    echo

    # Clean up PATH modifications
    cleanup_path

    echo

    # Verify removal
    verify_removal

    echo

    if [[ $found_installations -eq 1 ]]; then
        print_success "Exline uninstallation completed!"
        print_status "Thank you for using Exline Programming Language."
    else
        print_warning "No Exline installations were found to remove."
    fi

    echo
    print_status "If you encounter any issues, please visit:"
    print_status "https://github.com/msxavi/exline/issues"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Exline Programming Language Uninstaller"
        echo
        echo "This script completely removes all Exline installations from your system,"
        echo "including system installations, portable installations, and configuration files."
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --version, -v   Show version information"
        echo "  --force         Skip confirmation prompts (use with caution)"
        echo
        echo "What gets removed:"
        echo "  • System installation: $SYSTEM_INSTALL_DIR/$BINARY_NAME"
        echo "  • Portable installation: $PORTABLE_DIR/$BINARY_NAME"
        echo "  • Configuration: $CONFIG_DIR"
        echo "  • Examples: $EXAMPLES_DIR and $USER_EXAMPLES_DIR"
        echo "  • PATH modifications (optional)"
        exit 0
        ;;
    --version|-v)
        echo "Exline Uninstaller v$EXLINE_VERSION"
        exit 0
        ;;
    --force)
        print_warning "Force mode enabled - skipping confirmations"
        # Set non-interactive mode for scripts
        export DEBIAN_FRONTEND=noninteractive
        # Override read function to always return 'y'
        read() { REPLY='y'; }
        main
        ;;
    "")
        echo
        print_warning "This will remove ALL Exline installations from your system."
        print_status "This includes system installations, portable installations, and configuration files."
        echo
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo
            main
        else
            print_status "Uninstallation cancelled."
            exit 0
        fi
        ;;
    *)
        print_error "Unknown option: $1"
        print_status "Use --help for usage information"
        exit 1
        ;;
esac