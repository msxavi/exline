#!/bin/bash

# Exline Programming Language Installer
# Version: 0.2.0
# Compatible with: Linux, macOS, and other Unix-like systems

set -e  # Exit on any error

# Configuration
EXLINE_VERSION="0.2.0"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="exline"
SOURCE_BINARY="./target/release/exline"

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

# Function to check if running as root
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is not recommended for security reasons."
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled."
            exit 1
        fi
    fi
}

# Function to check if sudo is available and needed
check_sudo() {
    if [[ ! -w "$INSTALL_DIR" ]]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO_PREFIX="sudo"
            print_status "Installation requires sudo privileges for writing to $INSTALL_DIR"
        else
            print_error "Cannot write to $INSTALL_DIR and sudo is not available."
            print_error "Please run this script as root or choose a different installation directory."
            exit 1
        fi
    else
        SUDO_PREFIX=""
    fi
}

# Function to check if binary exists
check_binary() {
    if [[ ! -f "$SOURCE_BINARY" ]]; then
        print_error "Exline binary not found at $SOURCE_BINARY"
        print_error "Please build the project first using: cargo build --release"
        exit 1
    fi

    if [[ ! -x "$SOURCE_BINARY" ]]; then
        print_error "Exline binary is not executable: $SOURCE_BINARY"
        exit 1
    fi
}

# Function to backup existing installation
backup_existing() {
    if [[ -f "$INSTALL_DIR/$BINARY_NAME" ]]; then
        local backup_file="$INSTALL_DIR/${BINARY_NAME}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Existing Exline installation found. Creating backup..."
        $SUDO_PREFIX mv "$INSTALL_DIR/$BINARY_NAME" "$backup_file"
        print_status "Backup created: $backup_file"
    fi
}

# Function to install the binary
install_binary() {
    print_status "Installing Exline to $INSTALL_DIR..."
    $SUDO_PREFIX cp "$SOURCE_BINARY" "$INSTALL_DIR/$BINARY_NAME"
    $SUDO_PREFIX chmod +x "$INSTALL_DIR/$BINARY_NAME"
    print_success "Exline binary installed successfully!"
}

# Function to verify installation
verify_installation() {
    if command -v exline >/dev/null 2>&1; then
        local installed_version=$(exline --version 2>/dev/null || echo "unknown")
        print_success "Exline is now available in your PATH!"
        print_status "Installed version: $installed_version"
        print_status "You can now run Exline scripts with: exline your_script.exl"
    else
        print_warning "Exline was installed but is not in your PATH."
        print_status "You may need to restart your terminal or add $INSTALL_DIR to your PATH."
        print_status "To add to PATH, add this line to your shell configuration (~/.bashrc, ~/.zshrc, etc.):"
        print_status "export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
}

# Function to create example files
create_examples() {
    local example_dir="$HOME/.exline/examples"

    read -p "Would you like to install example Exline programs? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return
    fi

    print_status "Creating example directory: $example_dir"
    mkdir -p "$example_dir"

    # Create a simple hello world example
    cat > "$example_dir/hello.exl" << 'EOF'
# Simple Hello World in Exline
def greet(name: String) -> String
    "Hello, #{name}!"
end

print(greet("World"))
EOF

    # Create an OOP example
    cat > "$example_dir/person.exl" << 'EOF'
# Object-Oriented Programming Example in Exline

class Person
    String name
    Int age

    def greet() -> void
        print("Hello, I'm #{name} and I'm #{age} years old!")
    end

    def set_name(new_name: String) -> void
        name = new_name
    end

    def set_age(new_age: Int) -> void
        age = new_age
    end
end

# Create and use a Person object
p = Person.new()
p.set_name("Alice")
p.set_age(30)
p.greet()
EOF

    print_success "Example files created in $example_dir"
    print_status "Try running: exline $example_dir/hello.exl"
}

# Function to show post-installation information
show_post_install_info() {
    echo
    print_success "Exline Programming Language v$EXLINE_VERSION installed successfully!"
    echo
    print_status "Quick Start:"
    print_status "  1. Create a new .exl file with your Exline code"
    print_status "  2. Run it with: exline your_file.exl"
    echo
    print_status "Documentation and examples:"
    print_status "  • Language reference: https://github.com/msxavi/exline"
    print_status "  • Example files: ~/.exline/examples/ (if installed)"
    echo
    print_status "Need help? Visit: https://github.com/msxavi/exline/issues"
    echo
}

# Main installation process
main() {
    echo "=================================="
    echo "  Exline Programming Language"
    echo "  Installation Script v$EXLINE_VERSION"
    echo "=================================="
    echo

    print_status "Starting installation process..."

    # Run all checks and installation steps
    check_permissions
    check_binary
    check_sudo
    backup_existing
    install_binary
    verify_installation
    create_examples
    show_post_install_info

    print_success "Installation completed!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Exline Programming Language Installer"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --version, -v   Show version information"
        echo "  --uninstall     Uninstall Exline"
        echo
        echo "Default behavior: Install Exline to $INSTALL_DIR"
        exit 0
        ;;
    --version|-v)
        echo "Exline Installer v$EXLINE_VERSION"
        exit 0
        ;;
    --uninstall)
        if [[ -f "$INSTALL_DIR/$BINARY_NAME" ]]; then
            check_sudo
            print_status "Uninstalling Exline..."
            $SUDO_PREFIX rm -f "$INSTALL_DIR/$BINARY_NAME"
            print_success "Exline has been uninstalled."

            # Optionally remove examples
            if [[ -d "$HOME/.exline" ]]; then
                read -p "Remove example files from ~/.exline? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -rf "$HOME/.exline"
                    print_success "Example files removed."
                fi
            fi
        else
            print_error "Exline is not installed in $INSTALL_DIR"
            exit 1
        fi
        exit 0
        ;;
    "")
        # No arguments, proceed with installation
        main
        ;;
    *)
        print_error "Unknown option: $1"
        print_status "Use --help for usage information"
        exit 1
        ;;
esac