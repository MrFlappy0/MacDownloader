#!/bin/bash

# Script to build the MacDownloader GUI application
# Usage: ./scripts/build_gui.sh [--debug] [--arch ARCH]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
CONFIG="release"
ARCHS=("x86_64" "arm64")
BUILD_UNIVERSAL=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            CONFIG="debug"
            shift
            ;;
        --arch)
            ARCHS=("$2")
            BUILD_UNIVERSAL=false
            shift 2
            ;;
        --no-universal)
            BUILD_UNIVERSAL=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}Building MacDownloader GUI...${NC}"
echo "Configuration: $CONFIG"
echo "Architectures: ${ARCHS[*]}"
echo ""

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Xcode is required to build the GUI application${NC}"
    echo "Install Xcode from the Mac App Store"
    exit 1
fi

echo -e "${BLUE}Generating Xcode project...${NC}"
swift package generate-xcodeproj

echo -e "${BLUE}Building GUI with Xcode...${NC}"
echo "Note: This will open Xcode. Build the MacDownloaderApp target."
echo ""

# Open the project in Xcode
open MacDownloader.xcodeproj

echo ""
echo -e "${YELLOW}Xcode should now be open.${NC}"
echo -e "${YELLOW}Please manually build the MacDownloaderApp target.${NC}"
echo ""
echo "Alternatively, you can build from command line with:"
echo "  xcodebuild -scheme MacDownloaderApp -configuration $CONFIG"
