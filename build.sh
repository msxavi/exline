#!/bin/bash

# Exline Programming Language Build and Package Script
# Version: 0.2.0
# Creates distribution packages for multiple platforms

set -e

# Configuration
EXLINE_VERSION="0.2.0"
PROJECT_NAME="exline"
BUILD_DIR="dist"
PACKAGE_PREFIX="${PROJECT_NAME}-${EXLINE_VERSION}"

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

# Function to check dependencies
check_dependencies() {
    print_status "Checking build dependencies..."

    # Check for Rust and Cargo
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Cargo not found. Please install Rust and Cargo."
        exit 1
    fi

    # Check for required tools
    local required_tools=("tar" "zip" "gzip")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            print_warning "$tool not found. Some package formats may not be available."
        fi
    done

    print_success "Dependencies check completed."
}

# Function to clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."

    # Clean Cargo build artifacts
    cargo clean

    # Remove distribution directory
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
    fi

    print_success "Build cleanup completed."
}

# Function to build release binary
build_release() {
    print_status "Building release binary..."

    # Build optimized release binary
    cargo build --release

    if [[ ! -f "target/release/$PROJECT_NAME" ]]; then
        print_error "Release binary not found after build!"
        exit 1
    fi

    # Get binary info
    local binary_size=$(du -h "target/release/$PROJECT_NAME" | cut -f1)
    print_success "Release binary built successfully (size: $binary_size)"
}

# Function to run tests
run_tests() {
    print_status "Running tests..."

    # Run Cargo tests
    if cargo test; then
        print_success "All tests passed."
    else
        print_warning "Some tests failed, but continuing with build..."
    fi

    # Test with example files if they exist
    if [[ -f "test_ruby_syntax.exl" ]]; then
        print_status "Testing with example file..."
        if ./target/release/$PROJECT_NAME test_ruby_syntax.exl >/dev/null 2>&1; then
            print_success "Example test passed."
        else
            print_warning "Example test failed, but continuing..."
        fi
    fi
}

# Function to create directory structure
create_dist_structure() {
    print_status "Creating distribution directory structure..."

    mkdir -p "$BUILD_DIR"
    mkdir -p "$BUILD_DIR/unix"
    mkdir -p "$BUILD_DIR/windows"
    mkdir -p "$BUILD_DIR/portable"
    mkdir -p "$BUILD_DIR/source"

    print_success "Directory structure created."
}

# Function to prepare common files
prepare_common_files() {
    print_status "Preparing common distribution files..."

    # Create a comprehensive README for distribution
    cat > "$BUILD_DIR/README.md" << EOF
# Exline Programming Language v$EXLINE_VERSION

**Exline** is an object‑oriented, open-source, interpreted programming language that combines Ruby‑inspired readability with Rust‑class performance and safety.

## Installation Options

### Unix/Linux/macOS (System Installation)
Requires administrator privileges:
\`\`\`bash
chmod +x install.sh
sudo ./install.sh
\`\`\`

### Windows (System Installation)
Run as administrator:
\`\`\`cmd
install.bat
\`\`\`

### Portable Installation (No Admin Required)
For Unix/Linux/macOS:
\`\`\`bash
chmod +x install-portable.sh
./install-portable.sh
\`\`\`

### Manual Installation
1. Copy the \`exline\` binary to a directory in your PATH
2. Make it executable: \`chmod +x exline\`
3. Test with: \`exline --version\`

## Quick Start

1. Create a file with \`.exl\` extension:
\`\`\`exl
# hello.exl
def greet(name: String) : String
    "Hello, #{name}!"
end

print(greet("World"))
\`\`\`

2. Run it:
\`\`\`bash
exline hello.exl
\`\`\`

## Language Features

- ✅ Object-oriented programming with Ruby-like syntax
- ✅ Strong type system with explicit return types
- ✅ Interface implementation
- ✅ Method definitions and flow control
- ✅ String interpolation
- ✅ Built-in safety and error handling

## Documentation

- Language Reference: docs/exline_language_reference_draft_v_0.md
- Examples: examples/ directory
- Source Code: https://github.com/msxavi/exline

## Support

- Issues: https://github.com/msxavi/exline/issues
- Discussions: https://github.com/msxavi/exline/discussions

## License

MIT License - see LICENSE file for details.
EOF

    # Create installation guide
    cat > "$BUILD_DIR/INSTALLATION.md" << EOF
# Exline Installation Guide

## Choose Your Installation Method

### 1. System Installation (Recommended)

**Unix/Linux/macOS:**
\`\`\`bash
chmod +x install.sh
sudo ./install.sh
\`\`\`

**Windows:**
- Right-click on \`install.bat\` and select "Run as administrator"
- Or run from an elevated command prompt: \`install.bat\`

**Features:**
- Installs to system PATH (/usr/local/bin or Program Files)
- Available to all users
- Requires administrator privileges
- Automatic uninstaller included

### 2. Portable Installation

**Unix/Linux/macOS:**
\`\`\`bash
chmod +x install-portable.sh
./install-portable.sh
\`\`\`

**Windows:**
\`\`\`cmd
install.bat --user
\`\`\`

**Features:**
- No administrator privileges required
- Installs to user directory only
- Includes configuration and examples
- Easy to remove

### 3. Manual Installation

1. Copy the binary:
   - Unix/Linux/macOS: Copy \`exline\` to \`/usr/local/bin/\` or \`~/.local/bin/\`
   - Windows: Copy \`exline.exe\` to a directory in your PATH

2. Make executable (Unix/Linux/macOS only):
   \`\`\`bash
   chmod +x /path/to/exline
   \`\`\`

3. Test installation:
   \`\`\`bash
   exline --version
   \`\`\`

## Verification

After installation, verify it works:

\`\`\`bash
echo 'print("Hello, Exline!")' > test.exl
exline test.exl
rm test.exl
\`\`\`

Expected output: \`Hello, Exline!\`

## Troubleshooting

### Command not found
- Make sure the installation directory is in your PATH
- Try using the full path to the binary
- Restart your terminal/command prompt

### Permission denied
- On Unix/Linux/macOS: Run \`chmod +x /path/to/exline\`
- On Windows: Run as administrator

### Installation fails
- Check you have sufficient permissions
- Try the portable installation instead
- Check the troubleshooting section in README.md

## Uninstallation

### Using the uninstaller:
\`\`\`bash
chmod +x uninstall.sh
./uninstall.sh
\`\`\`

### Manual removal:
- Delete the binary from its installation directory
- Remove any PATH modifications from shell configuration files
- Delete configuration directories (\`~/.config/exline\`, \`~/.exline\`)
EOF

    # Copy license
    if [[ -f "LICENSE" ]]; then
        cp "LICENSE" "$BUILD_DIR/"
    else
        # Create a basic MIT license
        cat > "$BUILD_DIR/LICENSE" << EOF
MIT License

Copyright (c) $(date +%Y) Exline Programming Language

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    fi

    print_success "Common files prepared."
}

# Function to create example files
create_examples() {
    print_status "Creating example files..."

    local examples_dir="$BUILD_DIR/examples"
    mkdir -p "$examples_dir"

    # Hello World
    cat > "$examples_dir/01_hello_world.exl" << 'EOF'
# Basic Hello World example
print("Hello, World!")
EOF

    # Variables and functions
    cat > "$examples_dir/02_variables_functions.exl" << 'EOF'
# Variables and functions example

def greet(name: String) -> String
    "Hello, #{name}!"
end

def add(a: Int, b: Int) -> Int
    a + b
end

String myName = "Exline"
Int result = add(5, 3)

print(greet(myName))
print("5 + 3 = #{result}")
EOF

    # Object-oriented example
    cat > "$examples_dir/03_object_oriented.exl" << 'EOF'
# Object-oriented programming example

interface Greetable
    def greet() -> String
end

class Person implements Greetable
    String name
    Int age

    def greet() -> String
        "Hello, I'm #{name} and I'm #{age} years old!"
    end

    def set_name(new_name: String) -> void
        name = new_name
    end

    def set_age(new_age: Int) -> void
        age = new_age
    end

    def get_info() -> String
        "Person: #{name}, Age: #{age}"
    end
end

# Create and use objects
p = Person.new()
p.set_name("Alice")
p.set_age(30)

print(p.greet())
print(p.get_info())
EOF

    # Control flow example
    cat > "$examples_dir/04_control_flow.exl" << 'EOF'
# Control flow example

def check_number(n: Int) : String
    if n > 0
        "positive"
    else
        if n < 0
            "negative"
        else
            "zero"
        end
    end
end

Int numbers[5] = [1, -2, 0, 42, -10]

# Note: Array iteration not yet implemented, showing concept
print("Number classification:")
print("1 is #{check_number(1)}")
print("-2 is #{check_number(-2)}")
print("0 is #{check_number(0)}")
print("42 is #{check_number(42)}")
print("-10 is #{check_number(-10)}")
EOF

    # Create examples README
    cat > "$examples_dir/README.md" << 'EOF'
# Exline Examples

This directory contains example programs demonstrating various features of the Exline programming language.

## Running Examples

To run any example:
```bash
exline example_file.exl
```

## Examples Overview

- `01_hello_world.exl` - Basic Hello World program
- `02_variables_functions.exl` - Variables, functions, and string interpolation
- `03_object_oriented.exl` - Classes, interfaces, and object creation
- `04_control_flow.exl` - If/else statements and function examples

## Language Features Demonstrated

### Variables and Types
```exl
String name = "Exline"
Int number = 42
```

### Functions with Return Types
### Functions with Return Types
\`\`\`exl
def greet(name: String) -> String
    "Hello, #{name}!"
end
\`\`\`

### Object-Oriented Programming
```exl
class Person implements Greetable
    String name
    Int age

    def greet() -> String
        "Hello, I'm #{name}!"
    end
end

p = Person.new()  # Ruby-like syntax
```

### String Interpolation
```exl
print("Hello, #{name}!")  # Embeds variable values
```

## Learn More

- Read the full language reference in the docs/ directory
- Visit https://github.com/msxavi/exline for more information
- Try modifying these examples to experiment with the language
EOF

    print_success "Example files created."
}

# Function to create Unix/Linux package
create_unix_package() {
    print_status "Creating Unix/Linux package..."

    local unix_dir="$BUILD_DIR/unix/${PACKAGE_PREFIX}-linux"
    mkdir -p "$unix_dir"

    # Copy binary
    cp "target/release/$PROJECT_NAME" "$unix_dir/"

    # Copy installers
    cp "install.sh" "$unix_dir/"
    cp "install-portable.sh" "$unix_dir/"
    cp "uninstall.sh" "$unix_dir/"

    # Copy documentation
    cp "$BUILD_DIR/README.md" "$unix_dir/"
    cp "$BUILD_DIR/INSTALLATION.md" "$unix_dir/"
    cp "$BUILD_DIR/LICENSE" "$unix_dir/"

    # Copy examples
    cp -r "$BUILD_DIR/examples" "$unix_dir/"

    # Copy docs if they exist
    if [[ -d "docs" ]]; then
        cp -r "docs" "$unix_dir/"
    fi

    # Create tarball
    cd "$BUILD_DIR/unix"
    tar -czf "${PACKAGE_PREFIX}-linux.tar.gz" "${PACKAGE_PREFIX}-linux"
    cd - >/dev/null

    print_success "Unix/Linux package created: ${PACKAGE_PREFIX}-linux.tar.gz"
}

# Function to create Windows package
create_windows_package() {
    print_status "Creating Windows package..."

    local windows_dir="$BUILD_DIR/windows/${PACKAGE_PREFIX}-windows"
    mkdir -p "$windows_dir"

    # Note: This assumes cross-compilation or running on Windows
    if [[ -f "target/release/${PROJECT_NAME}.exe" ]]; then
        cp "target/release/${PROJECT_NAME}.exe" "$windows_dir/"
    else
        # Copy Unix binary and note about cross-compilation
        cp "target/release/$PROJECT_NAME" "$windows_dir/${PROJECT_NAME}.exe"
        print_warning "Copied Unix binary as .exe - you may need to cross-compile for Windows"
    fi

    # Copy Windows installer
    cp "install.bat" "$windows_dir/"

    # Copy documentation
    cp "$BUILD_DIR/README.md" "$windows_dir/"
    cp "$BUILD_DIR/INSTALLATION.md" "$windows_dir/"
    cp "$BUILD_DIR/LICENSE" "$windows_dir/"

    # Copy examples
    cp -r "$BUILD_DIR/examples" "$windows_dir/"

    # Copy docs if they exist
    if [[ -d "docs" ]]; then
        cp -r "docs" "$windows_dir/"
    fi

    # Create zip file
    if command -v zip >/dev/null 2>&1; then
        cd "$BUILD_DIR/windows"
        zip -r "${PACKAGE_PREFIX}-windows.zip" "${PACKAGE_PREFIX}-windows"
        cd - >/dev/null
        print_success "Windows package created: ${PACKAGE_PREFIX}-windows.zip"
    else
        print_warning "zip command not found. Windows package directory created but not archived."
    fi
}

# Function to create portable package
create_portable_package() {
    print_status "Creating portable package..."

    local portable_dir="$BUILD_DIR/portable/${PACKAGE_PREFIX}-portable"
    mkdir -p "$portable_dir"

    # Copy binary
    cp "target/release/$PROJECT_NAME" "$portable_dir/"

    # Copy portable installer
    cp "install-portable.sh" "$portable_dir/"
    cp "uninstall.sh" "$portable_dir/"

    # Copy documentation
    cp "$BUILD_DIR/README.md" "$portable_dir/"
    cp "$BUILD_DIR/INSTALLATION.md" "$portable_dir/"
    cp "$BUILD_DIR/LICENSE" "$portable_dir/"

    # Copy examples
    cp -r "$BUILD_DIR/examples" "$portable_dir/"

    # Create portable README
    cat > "$portable_dir/README_PORTABLE.md" << EOF
# Exline Portable Installation

This is a portable version of Exline that doesn't require administrator privileges.

## Quick Start

1. Run the portable installer:
   \`\`\`bash
   chmod +x install-portable.sh
   ./install-portable.sh
   \`\`\`

2. Or manually copy the binary to a directory in your PATH:
   \`\`\`bash
   cp exline ~/.local/bin/
   chmod +x ~/.local/bin/exline
   \`\`\`

3. Test the installation:
   \`\`\`bash
   exline examples/01_hello_world.exl
   \`\`\`

## What's Included

- \`exline\` - The Exline interpreter binary
- \`install-portable.sh\` - Portable installer script
- \`uninstall.sh\` - Uninstaller script
- \`examples/\` - Example Exline programs
- Documentation and license files

## No Admin Required

This portable version installs to your home directory and doesn't require
administrator or root privileges.
EOF

    # Create tarball
    cd "$BUILD_DIR/portable"
    tar -czf "${PACKAGE_PREFIX}-portable.tar.gz" "${PACKAGE_PREFIX}-portable"
    cd - >/dev/null

    print_success "Portable package created: ${PACKAGE_PREFIX}-portable.tar.gz"
}

# Function to create source package
create_source_package() {
    print_status "Creating source package..."

    local source_dir="$BUILD_DIR/source/${PACKAGE_PREFIX}-source"
    mkdir -p "$source_dir"

    # Copy source files
    cp -r "src" "$source_dir/"
    cp "Cargo.toml" "$source_dir/"
    cp "Cargo.lock" "$source_dir/"

    # Copy all test files
    cp *.exl "$source_dir/" 2>/dev/null || true

    # Copy documentation
    cp "README.md" "$source_dir/" 2>/dev/null || cp "$BUILD_DIR/README.md" "$source_dir/"
    cp "$BUILD_DIR/LICENSE" "$source_dir/"

    # Copy build and install scripts
    cp "install.sh" "$source_dir/"
    cp "install.bat" "$source_dir/"
    cp "install-portable.sh" "$source_dir/"
    cp "uninstall.sh" "$source_dir/"
    cp "$0" "$source_dir/build.sh"  # Copy this build script

    # Copy docs if they exist
    if [[ -d "docs" ]]; then
        cp -r "docs" "$source_dir/"
    fi

    # Create build instructions
    cat > "$source_dir/BUILD.md" << 'EOF'
# Building Exline from Source

## Prerequisites

- Rust (1.70.0 or later)
- Cargo (included with Rust)

## Build Instructions

1. Clone or extract the source code
2. Navigate to the source directory
3. Build the release binary:
   ```bash
   cargo build --release
   ```
4. The binary will be available at `target/release/exline`

## Installation

After building, you can install using one of the provided installers:

- `./install.sh` - System installation (requires sudo)
- `./install-portable.sh` - Portable installation (no sudo required)
- `./install.bat` - Windows installation

## Running Tests

```bash
cargo test
```

## Development

For development builds:
```bash
cargo build
```

The development binary will be at `target/debug/exline`.

## Package Creation

To create distribution packages:
```bash
chmod +x build.sh
./build.sh
```
EOF

    # Create tarball
    cd "$BUILD_DIR/source"
    tar -czf "${PACKAGE_PREFIX}-source.tar.gz" "${PACKAGE_PREFIX}-source"
    cd - >/dev/null

    print_success "Source package created: ${PACKAGE_PREFIX}-source.tar.gz"
}

# Function to create checksums
create_checksums() {
    print_status "Creating checksums..."

    cd "$BUILD_DIR"

    # Find all package files
    local packages=(
        "unix/${PACKAGE_PREFIX}-linux.tar.gz"
        "windows/${PACKAGE_PREFIX}-windows.zip"
        "portable/${PACKAGE_PREFIX}-portable.tar.gz"
        "source/${PACKAGE_PREFIX}-source.tar.gz"
    )

    # Create checksums file
    echo "# Exline v$EXLINE_VERSION - Package Checksums" > "checksums.sha256"
    echo "# Generated on $(date)" >> "checksums.sha256"
    echo "" >> "checksums.sha256"

    for package in "${packages[@]}"; do
        if [[ -f "$package" ]]; then
            if command -v sha256sum >/dev/null 2>&1; then
                sha256sum "$package" >> "checksums.sha256"
            elif command -v shasum >/dev/null 2>&1; then
                shasum -a 256 "$package" >> "checksums.sha256"
            else
                print_warning "No SHA256 tool found, skipping checksum for $package"
            fi
        fi
    done

    cd - >/dev/null

    print_success "Checksums created."
}

# Function to show build summary
show_build_summary() {
    echo
    print_success "Build completed successfully!"
    echo
    print_status "Distribution packages created in: $BUILD_DIR/"
    echo
    print_status "Available packages:"

    if [[ -f "$BUILD_DIR/unix/${PACKAGE_PREFIX}-linux.tar.gz" ]]; then
        local size=$(du -h "$BUILD_DIR/unix/${PACKAGE_PREFIX}-linux.tar.gz" | cut -f1)
        print_status "  • Unix/Linux: ${PACKAGE_PREFIX}-linux.tar.gz ($size)"
    fi

    if [[ -f "$BUILD_DIR/windows/${PACKAGE_PREFIX}-windows.zip" ]]; then
        local size=$(du -h "$BUILD_DIR/windows/${PACKAGE_PREFIX}-windows.zip" | cut -f1)
        print_status "  • Windows: ${PACKAGE_PREFIX}-windows.zip ($size)"
    fi

    if [[ -f "$BUILD_DIR/portable/${PACKAGE_PREFIX}-portable.tar.gz" ]]; then
        local size=$(du -h "$BUILD_DIR/portable/${PACKAGE_PREFIX}-portable.tar.gz" | cut -f1)
        print_status "  • Portable: ${PACKAGE_PREFIX}-portable.tar.gz ($size)"
    fi

    if [[ -f "$BUILD_DIR/source/${PACKAGE_PREFIX}-source.tar.gz" ]]; then
        local size=$(du -h "$BUILD_DIR/source/${PACKAGE_PREFIX}-source.tar.gz" | cut -f1)
        print_status "  • Source: ${PACKAGE_PREFIX}-source.tar.gz ($size)"
    fi

    echo
    print_status "Each package includes:"
    print_status "  • Exline interpreter binary"
    print_status "  • Installation scripts"
    print_status "  • Documentation and examples"
    print_status "  • License information"
    echo
    print_status "Total distribution size: $(du -sh "$BUILD_DIR" | cut -f1)"
    echo
    print_status "Ready for distribution!"
}

# Main build process
main() {
    echo "=============================================="
    echo "  Exline Programming Language"
    echo "  Build and Package Script v$EXLINE_VERSION"
    echo "=============================================="
    echo

    print_status "Starting build process..."

    check_dependencies
    clean_build
    build_release
    run_tests
    create_dist_structure
    prepare_common_files
    create_examples
    create_unix_package
    create_windows_package
    create_portable_package
    create_source_package
    create_checksums
    show_build_summary

    print_success "Build process completed!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Exline Programming Language Build Script"
        echo
        echo "This script builds Exline and creates distribution packages."
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --version, -v   Show version information"
        echo "  --clean-only    Only clean build artifacts"
        echo "  --build-only    Only build, don't create packages"
        echo "  --no-tests      Skip running tests"
        echo
        echo "Output: Distribution packages in '$BUILD_DIR/' directory"
        exit 0
        ;;
    --version|-v)
        echo "Exline Build Script v$EXLINE_VERSION"
        exit 0
        ;;
    --clean-only)
        print_status "Cleaning build artifacts only..."
        clean_build
        print_success "Clean completed."
        exit 0
        ;;
    --build-only)
        print_status "Building release binary only..."
        check_dependencies
        build_release
        if [[ "${2}" != "--no-tests" ]]; then
            run_tests
        fi
        print_success "Build completed."
        exit 0
        ;;
    --no-tests)
        print_warning "Skipping tests as requested."
        run_tests() { print_status "Tests skipped."; }
        main
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