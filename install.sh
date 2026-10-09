#!/bin/bash

# MacDownloader - Installation Script
# A powerful, open-source video downloader for macOS
# Version: 2.0.0

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

VERSION="2.0.0"
REPO_URL="https://github.com/MrFlappy0/MacDownloader.git"
INSTALL_DIR="/usr/local/bin"

# =============================================================================
# COLORS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

# Print functions
print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║        ⬇️  MacDownloader v${VERSION} - Video Downloader for macOS       ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  $1"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

print_step() {
    echo -e "${CYAN}[→]${NC} $1"
}

print_command() {
    echo -e "  ${WHITE}💻${NC} $1"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check macOS version
check_macOS_version() {
    local required_version="13.0"
    local current_version
    current_version=$(sw_vers -productVersion)
    
    if [[ "$(printf '%s\n%s' "$current_version" "$required_version" | sort -V | head -n1)" != "$required_version" ]]; then
        print_error "macOS ${required_version} or higher is required. You have ${current_version}."
        exit 1
    fi
    
    print_info "macOS Version: ${current_version}"
}

# Check Swift version
check_swift_version() {
    if ! command_exists swift; then
        print_error "Swift is not installed. Please install Xcode command line tools."
        print_info "Install: xcode-select --install"
        exit 1
    fi
    
    local swift_version
    swift_version=$(swift --version 2>/dev/null | head -n1 | awk '{print $4}')
    local required_version="5.9"
    
    if [[ "$swift_version" < "$required_version" ]]; then
        print_error "Swift ${required_version} or higher is required. You have ${swift_version:-unknown}."
        exit 1
    fi
    
    print_info "Swift Version: ${swift_version:-unknown}"
}

# Check Xcode command line tools
check_xcode_tools() {
    if ! command_exists xcode-select; then
        print_error "Xcode command line tools are not installed."
        print_info "Install: xcode-select --install"
        exit 1
    fi
    
    if ! xcode-select -p >/dev/null 2>&1; then
        print_warning "Xcode command line tools are not configured."
        print_info "Run: xcode-select --install"
        print_info "Then: sudo xcode-select -s /Library/Developer/CommandLineTools"
        exit 1
    fi
    
    print_info "Xcode Command Line Tools: Configured"
}

# Check Homebrew
check_homebrew() {
    if ! command_exists brew; then
        print_info "Homebrew not found. Installing..."
        install_homebrew
    else
        print_info "Homebrew: Installed"
    fi
}

# Check Git
check_git() {
    if ! command_exists git; then
        print_info "Git not found. Installing..."
        if command_exists brew; then
            brew install git
        else
            print_error "Git is required. Please install Git first."
            exit 1
        fi
    else
        print_info "Git: Installed"
    fi
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Install Homebrew
install_homebrew() {
    print_step "Installing Homebrew..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    
    # Download and run Homebrew installer
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$temp_dir/install_homebrew.sh"
    chmod +x "$temp_dir/install_homebrew.sh"
    
    # Run installer
    /bin/bash "$temp_dir/install_homebrew.sh" 2>&1
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Add Homebrew to PATH
    if [[ "$SHELL" == *"zsh"* ]]; then
        if ! grep -q 'brew shellenv' ~/.zshrc 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            source ~/.zshrc
        fi
    else
        if ! grep -q 'brew shellenv' ~/.bash_profile 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
            source ~/.bash_profile
        fi
    fi
    
    print_success "Homebrew installed successfully"
}

# Install dependencies
install_dependencies() {
    print_step "Installing dependencies..."
    
    # Update Homebrew
    if command_exists brew; then
        brew update >/dev/null 2>&1
    fi
    
    # List of required packages
    local packages=("git" "curl" "wget")
    
    for package in "${packages[@]}"; do
        if command_exists brew && brew list "$package" >/dev/null 2>&1; then
            print_info "$package: Already installed"
        elif command_exists brew; then
            print_step "Installing $package..."
            brew install "$package" >/dev/null 2>&1
            print_success "$package installed"
        else
            print_warning "$package: Skipped (Homebrew not available)"
        fi
    done
}

# Install FFmpeg
install_ffmpeg() {
    if command_exists ffmpeg; then
        print_info "FFmpeg: Already installed"
        return
    fi
    
    print_step "Installing FFmpeg..."
    
    if command_exists brew; then
        brew install ffmpeg >/dev/null 2>&1
        print_success "FFmpeg installed via Homebrew"
    else
        print_warning "FFmpeg: Homebrew required for automatic installation"
        print_info "To install FFmpeg manually:"
        print_command "1. Download from: https://evermeet.cx/ffmpeg/"
        print_command "2. Or use: curl -o ffmpeg https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
        print_command "3. Extract and add to PATH"
    fi
}

# =============================================================================
# REPOSITORY FUNCTIONS
# =============================================================================

# Clone or update repository
setup_repository() {
    local repo_dir="$HOME/MacDownloader"
    
    if [[ -d "$repo_dir/.git" ]]; then
        print_info "Repository already exists. Updating..."
        cd "$repo_dir"
        git pull origin main >/dev/null 2>&1
        print_success "Repository updated"
    else
        print_step "Cloning repository..."
        git clone --depth 1 "$REPO_URL" "$repo_dir" >/dev/null 2>&1
        print_success "Repository cloned"
    fi
    
    cd "$repo_dir"
}

# =============================================================================
# BUILD FUNCTIONS
# =============================================================================

# Build the CLI
build_cli() {
    print_step "Building MacDownloader CLI..."
    
    # Resolve dependencies
    print_info "Resolving Swift Package dependencies..."
    swift package resolve >/dev/null 2>&1
    
    # Build for both architectures
    print_info "Building for Apple Silicon (arm64)..."
    swift build -c release --arch arm64 >/dev/null 2>&1
    
    print_info "Building for Intel (x86_64)..."
    swift build -c release --arch x86_64 >/dev/null 2>&1
    
    # Create universal binary
    print_info "Creating universal binary..."
    mkdir -p .build/universal
    
    lipo -create \
        .build/arm64-apple-macosx/release/macdownloader \
        .build/x86_64-apple-macosx/release/macdownloader \
        -output .build/universal/macdownloader 2>/dev/null
    
    chmod +x .build/universal/macdownloader
    
    print_success "CLI built successfully"
}

# Install the CLI
install_cli() {
    print_step "Installing MacDownloader CLI..."
    
    # Create install directory if it doesn't exist
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_info "Creating $INSTALL_DIR..."
        sudo mkdir -p "$INSTALL_DIR"
    fi
    
    # Copy binary
    sudo cp .build/universal/macdownloader "$INSTALL_DIR/macdownloader"
    sudo chmod +x "$INSTALL_DIR/macdownloader"
    
    # Create symlink in /usr/bin if needed
    if [[ ! -f "/usr/bin/macdownloader" ]]; then
        sudo ln -sf "$INSTALL_DIR/macdownloader" /usr/bin/macdownloader
    fi
    
    print_success "CLI installed to $INSTALL_DIR/macdownloader"
}

# Install shell completions
install_completions() {
    print_step "Installing shell completions..."
    
    local completions_dir="$HOME/.macdownloader/completions"
    mkdir -p "$completions_dir"
    
    # Copy completion files
    if [[ -f "scripts/completions/macdownloader.bash" ]]; then
        cp scripts/completions/macdownloader.bash "$completions_dir/"
        
        # Install for Bash
        if [[ -f "$HOME/.bashrc" ]]; then
            if ! grep -q "macdownloader.bash" "$HOME/.bashrc" 2>/dev/null; then
                echo "" >> "$HOME/.bashrc"
                echo "# MacDownloader completions" >> "$HOME/.bashrc"
                echo "source $completions_dir/macdownloader.bash" >> "$HOME/.bashrc"
            fi
        fi
        
        print_success "Bash completions installed"
    fi
    
    # Install for Zsh
    if [[ -f "scripts/completions/_macdownloader" ]]; then
        cp scripts/completions/_macdownloader "$completions_dir/"
        
        local zsh_completions="$HOME/.zsh/completions"
        mkdir -p "$zsh_completions"
        
        if ! grep -q "macdownloader" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# MacDownloader completions" >> "$HOME/.zshrc"
            echo "fpath=($completions_dir $fpath)" >> "$HOME/.zshrc"
            echo "autoload -Uz compinit" >> "$HOME/.zshrc"
            echo "compinit" >> "$HOME/.zshrc"
        fi
        
        print_success "Zsh completions installed"
    fi
    
    # Install for Fish
    if [[ -f "scripts/completions/macdownloader.fish" ]]; then
        cp scripts/completions/macdownloader.fish "$completions_dir/"
        
        local fish_completions="$HOME/.config/fish/completions"
        mkdir -p "$fish_completions"
        
        if [[ ! -f "$fish_completions/macdownloader.fish" ]]; then
            ln -sf "$completions_dir/macdownloader.fish" "$fish_completions/macdownloader.fish"
        fi
        
        print_success "Fish completions installed"
    fi
    
    print_info "Shell completions installed to $completions_dir/"
    print_info "Restart your shell or run 'source ~/.bashrc' / 'source ~/.zshrc' to enable"
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

# Verify installation
verify_installation() {
    print_step "Verifying installation..."
    
    if command_exists macdownloader; then
        local version
        version=$(macdownloader --version 2>&1 | head -n1 || true)
        print_success "MacDownloader CLI is installed!"
        print_info "Version: $version"
        
        # Check FFmpeg
        if command_exists ffmpeg; then
            local ffmpeg_version
            ffmpeg_version=$(ffmpeg -version 2>&1 | head -n1 | awk '{print $3}' || true)
            print_success "FFmpeg: Installed (v${ffmpeg_version:-unknown})"
        else
            print_warning "FFmpeg: Not installed (optional for conversion features)"
            print_info "Install: brew install ffmpeg"
        fi
        
        return 0
    else
        print_error "Installation failed. macdownloader command not found."
        return 1
    fi
}

# =============================================================================
# UNINSTALL FUNCTION
# =============================================================================

uninstall() {
    print_header
    print_step "Uninstalling MacDownloader..."
    
    # Remove CLI
    if [[ -f "$INSTALL_DIR/macdownloader" ]]; then
        sudo rm -f "$INSTALL_DIR/macdownloader"
        print_success "Removed $INSTALL_DIR/macdownloader"
    fi
    
    if [[ -f "/usr/bin/macdownloader" ]]; then
        sudo rm -f "/usr/bin/macdownloader"
        print_success "Removed /usr/bin/macdownloader"
    fi
    
    # Remove repository
    if [[ -d "$HOME/MacDownloader" ]]; then
        rm -rf "$HOME/MacDownloader"
        print_success "Removed $HOME/MacDownloader"
    fi
    
    # Remove completions
    if [[ -d "$HOME/.macdownloader" ]]; then
        rm -rf "$HOME/.macdownloader"
        print_success "Removed shell completions"
    fi
    
    # Remove from bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        sed -i '' '/macdownloader/d' "$HOME/.bashrc" 2>/dev/null || true
    fi
    
    # Remove from zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        sed -i '' '/macdownloader/d' "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    print_success "MacDownloader has been uninstalled."
    exit 0
}

# =============================================================================
# USAGE FUNCTION
# =============================================================================

print_usage() {
    print_header
    
    echo ""
    echo "A powerful, open-source video downloader for macOS — like Downie but free!"
    echo ""
    echo "${BOLD}USAGE:${NC}"
    echo "  $0 [OPTION]"
    echo ""
    echo "${BOLD}OPTIONS:${NC}"
    echo "  --help, -h       Show this help message"
    echo "  --version, -v    Show version"
    echo "  --uninstall      Uninstall MacDownloader"
    echo "  --cli-only       Install CLI only (default)"
    echo "  --with-gui      Install with GUI support"
    echo "  --no-ffmpeg     Skip FFmpeg installation"
    echo "  --no-completions Skip shell completions"
    echo ""
    echo "${BOLD}EXAMPLES:${NC}"
    echo "  $0              Install MacDownloader (CLI only)"
    echo "  $0 --with-gui   Install MacDownloader with GUI"
    echo "  $0 --uninstall  Uninstall MacDownloader"
    echo ""
    echo "${BOLD}AFTER INSTALLATION:${NC}"
    echo "  macdownloader --help     Show CLI help"
    echo "  macdownloader list       Show supported sites"
    echo "  macdownloader d URL      Download a video"
    echo ""
    
    exit 0
}

# =============================================================================
# MAIN INSTALLATION FUNCTION
# =============================================================================

main_install() {
    local install_gui=false
    local install_ffmpeg=true
    local install_completions=true
    
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
            --with-gui|--gui)
                install_gui=true
                ;;
            --no-ffmpeg)
                install_ffmpeg=false
                ;;
            --no-completions)
                install_completions=false
                ;;
            *)
                if [[ "$arg" != "--cli-only" ]]; then
                    print_error "Unknown option: $arg"
                    print_usage
                fi
                ;;
        esac
    done
    
    print_header
    
    # Check system requirements
    print_section "Checking System Requirements"
    check_macOS_version
    check_xcode_tools
    check_swift_version
    echo ""
    
    # Install dependencies
    print_section "Installing Dependencies"
    check_homebrew
    check_git
    install_dependencies
    
    if [[ "$install_ffmpeg" == true ]]; then
        install_ffmpeg
    fi
    echo ""
    
    # Setup repository
    print_section "Setting Up Repository"
    setup_repository
    echo ""
    
    # Build and install CLI
    print_section "Building and Installing CLI"
    build_cli
    install_cli
    echo ""
    
    # Install GUI if requested
    if [[ "$install_gui" == true ]]; then
        print_section "GUI Installation"
        print_info "To build the GUI application:"
        print_command "1. cd $HOME/MacDownloader"
        print_command "2. swift package generate-xcodeproj"
        print_command "3. open MacDownloader.xcodeproj"
        print_command "4. Build the MacDownloaderApp target in Xcode"
        echo ""
    fi
    
    # Install shell completions
    if [[ "$install_completions" == true ]]; then
        install_completions
        echo ""
    fi
    
    # Verify installation
    verify_installation
    
    if [[ $? -eq 0 ]]; then
        echo ""
        print_section "Installation Complete!"
        print_success "✓ MacDownloader is ready to use!"
        echo ""
        print_info "Try it with:"
        print_command "  macdownloader --help"
        print_command "  macdownloader list"
        print_command "  macdownloader d https://youtube.com/watch?v=dQw4w9WgXcQ"
        echo ""
        
        # Check for updates
        print_info "Tip: Run '$0' to check for updates"
    fi
}

# =============================================================================
# ENTRY POINT
# =============================================================================

# Parse arguments for uninstall
for arg in "$@"; do
    if [[ "$arg" == "--uninstall" ]]; then
        uninstall
        exit 0
    fi
done

# Parse arguments for help
for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        print_usage
        exit 0
    fi
done

# Parse arguments for version
for arg in "$@"; do
    if [[ "$arg" == "--version" || "$arg" == "-v" ]]; then
        echo "MacDownloader Installer v$VERSION"
        exit 0
    fi
done

# Run main installation
main_install "$@"
