#!/bin/bash

# Script to build the MacDownloader CLI
# Usage: ./scripts/build_cli.sh [--debug] [--arch ARCH]

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

echo -e "${BLUE}Building MacDownloader CLI...${NC}"
echo "Configuration: $CONFIG"
echo "Architectures: ${ARCHS[*]}"
echo ""

# Function to build for a specific architecture
build_for_arch() {
    local arch="$1"
    echo -e "${BLUE}Building for $arch...${NC}"
    
    if [[ "$CONFIG" == "debug" ]]; then
        swift build -c debug --arch "$arch"
    else
        swift build -c release --arch "$arch"
    fi
    
    echo -e "${GREEN}Built for $arch${NC}"
}

# Build for all architectures
for arch in "${ARCHS[@]}"; do
    build_for_arch "$arch"
done

# Create universal binary if requested
if [[ "$BUILD_UNIVERSAL" == true && ${#ARCHS[@]} -gt 1 ]]; then
    echo -e "${BLUE}Creating universal binary...${NC}"
    
    mkdir -p .build/universal
    
    # Collect all architecture-specific binaries
    local binary_paths=()
    for arch in "${ARCHS[@]}"; do
        binary_paths+=(".build/${arch}-apple-macosx/${CONFIG}/macdownloader")
    done
    
    # Combine into universal binary
    lipo -create "${binary_paths[@]}" -output .build/universal/macdownloader
    
    # Verify the universal binary
    echo -e "${BLUE}Verifying universal binary...${NC}"
    lipo -info .build/universal/macdownloader
    
    # Make executable
    chmod +x .build/universal/macdownloader
    
    echo -e "${GREEN}Universal binary created at .build/universal/macdownloader${NC}"
else
    echo -e "${GREEN}Build complete${NC}"
    for arch in "${ARCHS[@]}"; do
        echo "  .build/${arch}-apple-macosx/${CONFIG}/macdownloader"
    done
fi

echo ""
echo -e "${GREEN}CLI build finished successfully!${NC}"
