#!/bin/bash

# Exline Programming Language Portable Installer
# Version: 0.2.0
# Creates a portable installation that doesn't require admin privileges

set -e

# Configuration
EXLINE_VERSION="0.2.0"
BINARY_NAME="exline"
SOURCE_BINARY="./target/release/exline"
PORTABLE_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/exline"
EXAMPLES_DIR="$HOME/.local/share/exline/examples"

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

# Function to check if binary exists
check_binary() {
    if [[ ! -f "$SOURCE_BINARY" ]]; then
        print_error "Exline binary not found at $SOURCE_BINARY"
        print_error "Please build the project first using: cargo build --release"
        exit 1
    fi
}

# Function to create portable directories
create_directories() {
    print_status "Creating portable installation directories..."
    mkdir -p "$PORTABLE_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$EXAMPLES_DIR"
    print_success "Directories created."
}

# Function to install binary
install_binary() {
    print_status "Installing Exline binary to $PORTABLE_DIR..."

    # Backup existing if present
    if [[ -f "$PORTABLE_DIR/$BINARY_NAME" ]]; then
        local backup_file="$PORTABLE_DIR/${BINARY_NAME}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Existing installation found. Creating backup: $backup_file"
        mv "$PORTABLE_DIR/$BINARY_NAME" "$backup_file"
    fi

    cp "$SOURCE_BINARY" "$PORTABLE_DIR/$BINARY_NAME"
    chmod +x "$PORTABLE_DIR/$BINARY_NAME"
    print_success "Binary installed successfully!"
}

# Function to setup PATH
setup_path() {
    local shell_config=""
    local shell_name=$(basename "$SHELL")

    case "$shell_name" in
        bash)
            shell_config="$HOME/.bashrc"
            ;;
        zsh)
            shell_config="$HOME/.zshrc"
            ;;
        fish)
            shell_config="$HOME/.config/fish/config.fish"
            ;;
        *)
            shell_config="$HOME/.profile"
            ;;
    esac

    # Check if PATH already contains our directory
    if [[ ":$PATH:" == *":$PORTABLE_DIR:"* ]]; then
        print_status "PATH already configured correctly."
        return
    fi

    print_status "Configuring PATH in $shell_config..."

    # Create backup of shell config
    if [[ -f "$shell_config" ]]; then
        cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Add PATH configuration
    if [[ "$shell_name" == "fish" ]]; then
        echo "" >> "$shell_config"
        echo "# Added by Exline installer" >> "$shell_config"
        echo "set -gx PATH $PORTABLE_DIR \$PATH" >> "$shell_config"
    else
        echo "" >> "$shell_config"
        echo "# Added by Exline installer" >> "$shell_config"
        echo "export PATH=\"$PORTABLE_DIR:\$PATH\"" >> "$shell_config"
    fi

    print_success "PATH configuration added to $shell_config"
    print_warning "Please restart your terminal or run: source $shell_config"
}

# Function to create example files
create_examples() {
    print_status "Creating example programs..."

    # Hello world example
    cat > "$EXAMPLES_DIR/hello.exl" << 'EOF'
# Simple Hello World in Exline
def greet(name: String) : String
    "Hello, #{name}!"
end

print(greet("World"))
EOF

    # OOP example
    cat > "$EXAMPLES_DIR/person.exl" << 'EOF'
# Object-Oriented Programming Example in Exline

class Person
    String name
    Int age

    def greet() : void
        print("Hello, I'm #{name} and I'm #{age} years old!")
    end

    def set_name(new_name: String) : void
        name = new_name
    end

    def set_age(new_age: Int) : void
        age = new_age
    end
end

# Create and use a Person object
p = Person.new()
p.set_name("Alice")
p.set_age(30)
p.greet()
EOF

    # Advanced example with interfaces
    cat > "$EXAMPLES_DIR/shapes.exl" << 'EOF'
# Interface and inheritance example

interface Drawable
    def draw() : void
    def area() : Int
end

class Rectangle implements Drawable
    Int width
    Int height

    def draw() : void
        print("Drawing a rectangle: #{width}x#{height}")
    end

    def area() : Int
        width * height
    end

    def set_dimensions(w: Int, h: Int) : void
        width = w
        height = h
    end
end

# Create and use shapes
rect = Rectangle.new()
rect.set_dimensions(10, 5)
rect.draw()
print("Area: #{rect.area()}")
EOF

    print_success "Example files created in $EXAMPLES_DIR"
}

# Function to create configuration file
create_config() {
    print_status "Creating configuration file..."

    cat > "$CONFIG_DIR/config.toml" << EOF
# Exline Configuration File
version = "$EXLINE_VERSION"
install_type = "portable"
install_date = "$(date -Iseconds)"
install_path = "$PORTABLE_DIR"
examples_path = "$EXAMPLES_DIR"

[runtime]
# Default settings for the Exline interpreter
debug_mode = false
max_recursion_depth = 1000

[editor]
# Recommended editor settings for .exl files
file_extension = ".exl"
syntax_highlighting = true
EOF

    print_success "Configuration file created at $CONFIG_DIR/config.toml"
}

# Function to create launcher script
create_launcher() {
    local launcher_script="$CONFIG_DIR/launch.sh"

    print_status "Creating launcher script..."

    cat > "$launcher_script" << EOF
#!/bin/bash
# Exline Portable Launcher
# This script ensures the portable installation is properly configured

# Add portable bin to PATH if not already there
if [[ ":\$PATH:" != *":$PORTABLE_DIR:"* ]]; then
    export PATH="$PORTABLE_DIR:\$PATH"
fi

# Set up Exline environment
export EXLINE_HOME="$CONFIG_DIR"
export EXLINE_EXAMPLES="$EXAMPLES_DIR"

# Run exline with all arguments
exec "$PORTABLE_DIR/$BINARY_NAME" "\$@"
EOF

    chmod +x "$launcher_script"
    print_success "Launcher script created at $launcher_script"

    # Create an alias setup script
    cat > "$CONFIG_DIR/setup_alias.sh" << EOF
#!/bin/bash
# Add this to your shell configuration to create an exline alias

# For bash/zsh, add to ~/.bashrc or ~/.zshrc:
alias exline="$launcher_script"

# For fish, add to ~/.config/fish/config.fish:
# alias exline "$launcher_script"
EOF

    chmod +x "$CONFIG_DIR/setup_alias.sh"
    print_status "Alias setup script created at $CONFIG_DIR/setup_alias.sh"
}

# Function to verify installation
verify_installation() {
    # Test if binary works
    if "$PORTABLE_DIR/$BINARY_NAME" --version >/dev/null 2>&1; then
        print_success "Installation verified successfully!"
    else
        print_warning "Installation completed but verification failed."
        print_status "You may need to restart your terminal."
    fi
}

# Function to show post-installation information
show_post_install_info() {
    echo
    print_success "Exline Portable Installation v$EXLINE_VERSION completed!"
    echo
    print_status "Installation Details:"
    print_status "  • Binary location: $PORTABLE_DIR/$BINARY_NAME"
    print_status "  • Configuration: $CONFIG_DIR/"
    print_status "  • Examples: $EXAMPLES_DIR/"
    echo
    print_status "Quick Start:"
    print_status "  1. Restart your terminal or run: source ~/.bashrc (or your shell config)"
    print_status "  2. Test with: exline $EXAMPLES_DIR/hello.exl"
    print_status "  3. Create your own .exl files and run them!"
    echo
    print_status "Alternative Usage (if PATH not working):"
    print_status "  • Use full path: $PORTABLE_DIR/exline your_file.exl"
    print_status "  • Use launcher: $CONFIG_DIR/launch.sh your_file.exl"
    print_status "  • Set up alias: source $CONFIG_DIR/setup_alias.sh"
    echo
    print_status "Documentation: https://github.com/msxavi/exline"
    echo
}

# Main installation process
main() {
    echo "============================================"
    echo "  Exline Programming Language"
    echo "  Portable Installation Script v$EXLINE_VERSION"
    echo "============================================"
    echo

    print_status "Starting portable installation..."
    print_status "No admin privileges required!"
    echo

    check_binary
    create_directories
    install_binary
    setup_path
    create_examples
    create_config
    create_launcher
    verify_installation
    show_post_install_info

    print_success "Portable installation completed!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Exline Programming Language Portable Installer"
        echo
        echo "This installer creates a portable installation in your home directory"
        echo "that doesn't require administrator privileges."
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --version, -v   Show version information"
        echo "  --uninstall     Remove portable installation"
        echo
        echo "Installation locations:"
        echo "  • Binary: $PORTABLE_DIR"
        echo "  • Config: $CONFIG_DIR"
        echo "  • Examples: $EXAMPLES_DIR"
        exit 0
        ;;
    --version|-v)
        echo "Exline Portable Installer v$EXLINE_VERSION"
        exit 0
        ;;
    --uninstall)
        print_status "Removing portable installation..."

        # Remove binary
        if [[ -f "$PORTABLE_DIR/$BINARY_NAME" ]]; then
            rm -f "$PORTABLE_DIR/$BINARY_NAME"
            print_success "Binary removed."
        fi

        # Ask about removing config and examples
        echo
        read -p "Remove configuration directory ($CONFIG_DIR)? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$CONFIG_DIR"
            print_success "Configuration removed."
        fi

        read -p "Remove examples directory ($EXAMPLES_DIR)? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$EXAMPLES_DIR"
            print_success "Examples removed."
        fi

        print_warning "Note: PATH modifications in shell config files were not automatically removed."
        print_status "You may want to manually remove the Exline PATH export from your shell configuration."

        print_success "Portable installation removed."
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        print_status "Use --help for usage information"
        exit 1
        ;;
esac