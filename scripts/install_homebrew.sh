#!/bin/bash

# Script to install MacDownloader via Homebrew
# This script creates a local tap and installs the formula

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed"
    print_info "Install Homebrew first:"
    print_info "  /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

print_info "Homebrew is installed"

# Get the current directory (should be the repo root)
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

print_info "Repository root: $REPO_ROOT"

# Create a temporary tap directory
TAP_DIR=$(mktemp -d)
TAP_NAME="mrflappy0/tap"
FORMULA_NAME="macdownloader"

print_info "Creating temporary tap at $TAP_DIR"

# Copy the formula to the tap directory
mkdir -p "$TAP_DIR/$TAP_NAME/Formula"
cp "$REPO_ROOT/scripts/homebrew/macdownloader.rb" "$TAP_DIR/$TAP_NAME/Formula/$FORMULA_NAME.rb"

# Update the formula URL to point to the current directory
sed -i '' "s|url \"https://github.com/MrFlappy0/MacDownloader/archive/refs/tags/v1.0.0.tar.gz\"|url \"file://$REPO_ROOT\"|" \
    "$TAP_DIR/$TAP_NAME/Formula/$FORMULA_NAME.rb"

# Remove sha256 since we're using local files
sed -i '' '/sha256/d' "$TAP_DIR/$TAP_NAME/Formula/$FORMULA_NAME.rb"

print_info "Tap structure created"

# Link the tap
print_info "Linking tap..."
ln -sf "$TAP_DIR/$TAP_NAME" "$(brew --repository)/Library/Taps/"

print_info "Tap linked"

# Install the formula
print_info "Installing MacDownloader..."

if brew list "$FORMULA_NAME" >/dev/null 2>&1; then
    print_info "MacDownloader is already installed. Upgrading..."
    brew upgrade "$FORMULA_NAME"
else
    brew install "$FORMULA_NAME"
fi

# Verify installation
if command -v macdownloader &> /dev/null; then
    print_success "MacDownloader installed successfully!"
    print_info "Try it with: macdownloader --help"
else
    print_error "Installation failed. macdownloader command not found."
    exit 1
fi

# Clean up
print_info "Cleaning up temporary files..."
rm -rf "$TAP_DIR"

print_success "Installation complete!"
