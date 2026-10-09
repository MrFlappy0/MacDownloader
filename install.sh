#!/bin/bash

# MacDownloader - Installation Script
# This script installs all necessary dependencies and builds the MacDownloader CLI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version
VERSION="1.0.0"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check macOS version
check_macOS_version() {
    local required_version="13.0"
    local current_version
    current_version=$(sw_vers -productVersion)
    
    if [[ "$current_version" < "$required_version" ]]; then
        print_error "macOS version $required_version or higher is required. You have $current_version."
        exit 1
    fi
    
    print_info "macOS version: $current_version"
}

# Function to check Swift version
check_swift_version() {
    if ! command_exists swift; then
        print_error "Swift is not installed. Please install Xcode command line tools."
        exit 1
    fi
    
    local swift_version
    swift_version=$(swift --version | head -n1 | awk '{print $4}')
    local required_version="5.9"
    
    if [[ "$swift_version" < "$required_version" ]]; then
        print_error "Swift $required_version or higher is required. You have $swift_version."
        exit 1
    fi
    
    print_info "Swift version: $swift_version"
}

# Function to check Xcode command line tools
check_xcode_tools() {
    if ! command_exists xcode-select; then
        print_error "Xcode command line tools are not installed."
        print_info "Install them with: xcode-select --install"
        exit 1
    fi
    
    if ! xcode-select -p >/dev/null 2>&1; then
        print_warning "Xcode command line tools are not configured."
        print_info "Run: xcode-select --install"
        print_info "Then: sudo xcode-select -s /Library/Developer/CommandLineTools"
        exit 1
    fi
    
    print_info "Xcode command line tools: OK"
}

# Function to install Homebrew (if not installed)
install_homebrew() {
    if ! command_exists brew; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ "$SHELL" == *"zsh"* ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            source ~/.zshrc
        else
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
            source ~/.bash_profile
        fi
        
        print_success "Homebrew installed successfully"
    else
        print_info "Homebrew is already installed"
    fi
}

# Function to install dependencies with Homebrew
install_dependencies() {
    print_info "Checking and installing dependencies..."
    
    # Update Homebrew
    brew update
    
    # Install required packages
    local packages=(
        "git"
        "curl"
        "wget"
    )
    
    for package in "${packages[@]}"; do
        if brew list "$package" >/dev/null 2>&1; then
            print_info "$package is already installed"
        else
            print_info "Installing $package..."
            brew install "$package"
            print_success "$package installed"
        fi
    done
}

# Function to clone or update the repository
clone_or_update_repo() {
    local repo_dir="$HOME/MacDownloader"
    
    if [[ -d "$repo_dir/.git" ]]; then
        print_info "Repository already exists. Updating..."
        cd "$repo_dir"
        git pull origin main
        print_success "Repository updated"
    else
        print_info "Cloning repository..."
        git clone https://github.com/MrFlappy0/MacDownloader.git "$repo_dir"
        print_success "Repository cloned"
    fi
    
    cd "$repo_dir"
}

# Function to build the CLI
build_cli() {
    print_info "Building MacDownloader CLI..."
    
    # Resolve dependencies
    print_info "Resolving Swift Package dependencies..."
    swift package resolve
    
    # Build in release mode
    print_info "Building in release mode..."
    swift build -c release --arch x86_64 --arch arm64
    
    # Create universal binary
    print_info "Creating universal binary..."
    mkdir -p .build/universal
    
    # Combine x86_64 and arm64 binaries
    lipo -create \
        .build/x86_64-apple-macosx/release/macdownloader \
        .build/arm64-apple-macosx/release/macdownloader \
        -output .build/universal/macdownloader
    
    print_success "CLI built successfully"
}

# Function to install the CLI
install_cli() {
    local install_dir="/usr/local/bin"
    
    if [[ ! -d "$install_dir" ]]; then
        print_info "Creating $install_dir directory..."
        sudo mkdir -p "$install_dir"
    fi
    
    print_info "Installing macdownloader to $install_dir..."
    sudo cp .build/universal/macdownloader "$install_dir/macdownloader"
    sudo chmod +x "$install_dir/macdownloader"
    
    print_success "CLI installed to $install_dir/macdownloader"
}

# Function to create symlink in /usr/bin if needed
create_symlink() {
    if [[ ! -f "/usr/bin/macdownloader" ]]; then
        print_info "Creating symlink in /usr/bin..."
        sudo ln -sf /usr/local/bin/macdownloader /usr/bin/macdownloader
        print_success "Symlink created"
    fi
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    if command_exists macdownloader; then
        local version
        version=$(macdownloader --help 2>&1 | head -n1 || true)
        print_success "MacDownloader CLI is installed and working!"
        print_info "Version: $version"
    else
        print_error "Installation failed. macdownloader command not found."
        exit 1
    fi
}

# Function to create desktop shortcut for GUI (optional)
create_desktop_shortcut() {
    if [[ "$1" == "--gui" || "$1" == "-g" ]]; then
        print_info "Creating desktop shortcut for GUI application..."
        
        # Build the GUI application
        print_info "Building GUI application..."
        swift build -c release --arch x86_64 --arch arm64
        
        # Create .app bundle (simplified)
        mkdir -p .build/universal/MacDownloader.app/Contents/MacOS
        cp .build/universal/macdownloader .build/universal/MacDownloader.app/Contents/MacOS/
        
        # Create Info.plist for the app
        cat > .build/universal/MacDownloader.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>macdownloader</string>
    <key>CFBundleIdentifier</key>
    <string>com.mrflappy.MacDownloader</string>
    <key>CFBundleName</key>
    <string>MacDownloader</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
        
        print_success "GUI application built"
        print_info "Note: For a full GUI experience, open the project in Xcode and build the MacDownloaderApp target"
    fi
}

# Function to create uninstall script
create_uninstall_script() {
    cat > /tmp/uninstall_macdownloader.sh << 'EOF'
#!/bin/bash

echo "Uninstalling MacDownloader..."

# Remove CLI
if [[ -f "/usr/local/bin/macdownloader" ]]; then
    sudo rm /usr/local/bin/macdownloader
    echo "Removed /usr/local/bin/macdownloader"
fi

if [[ -f "/usr/bin/macdownloader" ]]; then
    sudo rm /usr/bin/macdownloader
    echo "Removed /usr/bin/macdownloader"
fi

# Remove repository
if [[ -d "$HOME/MacDownloader" ]]; then
    rm -rf "$HOME/MacDownloader"
    echo "Removed $HOME/MacDownloader"
fi

# Remove cache
if [[ -d "$HOME/Library/Caches/org.swift.swiftpm" ]]; then
    rm -rf "$HOME/Library/Caches/org.swift.swiftpm"
    echo "Removed Swift Package Manager cache"
fi

echo "MacDownloader has been uninstalled."
EOF
    
    chmod +x /tmp/uninstall_macdownloader.sh
    print_info "Uninstall script created at /tmp/uninstall_macdownloader.sh"
}

# Function to display usage
print_usage() {
    echo ""
    echo "MacDownloader Installation Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo "  --version, -v    Show version"
    echo "  --cli-only, -c   Install CLI only (default)"
    echo "  --gui, -g        Install with GUI support"
    echo "  --uninstall      Uninstall MacDownloader"
    echo ""
    echo "Examples:"
    echo "  $0              Install CLI only"
    echo "  $0 --gui        Install with GUI support"
    echo "  $0 --uninstall   Uninstall MacDownloader"
    echo ""
    exit 0
}

# Function to uninstall
uninstall() {
    print_info "Uninstalling MacDownloader..."
    
    # Remove CLI
    if [[ -f "/usr/local/bin/macdownloader" ]]; then
        sudo rm /usr/local/bin/macdownloader
        print_success "Removed /usr/local/bin/macdownloader"
    fi
    
    if [[ -f "/usr/bin/macdownloader" ]]; then
        sudo rm /usr/bin/macdownloader
        print_success "Removed /usr/bin/macdownloader"
    fi
    
    # Remove repository
    if [[ -d "$HOME/MacDownloader" ]]; then
        rm -rf "$HOME/MacDownloader"
        print_success "Removed $HOME/MacDownloader"
    fi
    
    # Remove cache
    if [[ -d "$HOME/Library/Caches/org.swift.swiftpm" ]]; then
        rm -rf "$HOME/Library/Caches/org.swift.swiftpm"
        print_success "Removed Swift Package Manager cache"
    fi
    
    print_success "MacDownloader has been uninstalled."
    exit 0
}

# Main installation process
main() {
    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                print_usage
                ;;
            --version|-v)
                echo "MacDownloader Installer v$VERSION"
                exit 0
                ;;
            --uninstall)
                uninstall
                ;;
        esac
    done
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        MacDownloader Installation Script v$VERSION            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check system requirements
    print_info "Checking system requirements..."
    check_macOS_version
    check_xcode_tools
    check_swift_version
    echo ""
    
    # Install Homebrew and dependencies
    print_info "Installing dependencies..."
    install_homebrew
    install_dependencies
    echo ""
    
    # Clone or update repository
    print_info "Setting up repository..."
    clone_or_update_repo
    echo ""
    
    # Build and install CLI
    print_info "Building and installing CLI..."
    build_cli
    install_cli
    create_symlink
    echo ""
    
    # Create desktop shortcut for GUI (optional)
    create_desktop_shortcut "$1"
    echo ""
    
    # Create uninstall script
    create_uninstall_script
    echo ""
    
    # Verify installation
    verify_installation
    echo ""
    
    print_success "╔════════════════════════════════════════════════════════════╗"
    print_success "║                    Installation Complete!                     ║"
    print_success "╚════════════════════════════════════════════════════════════╝"
    echo ""
    print_info "You can now use MacDownloader from the command line:"
    print_info "  macdownloader --help"
    echo ""
    print_info "Or for GUI (open in Xcode):"
    print_info "  cd $HOME/MacDownloader"
    print_info "  open MacDownloader.xcodeproj"
    echo ""
}

# Run main function with all arguments
main "$@"
