# MacDownloader Makefile
# Provides convenient commands for building, testing, and installing

.PHONY: help build build-cli build-gui test clean install uninstall run-cli run-gui

# Version
VERSION := 1.0.0

# Directories
SRC_DIR := Sources
TEST_DIR := Tests
BUILD_DIR := .build
DIST_DIR := dist

# Targets
CLI_TARGET := MacDownloaderCLI
GUI_TARGET := MacDownloaderApp
CORE_TARGET := MacDownloaderCore

# Configuration
CONFIG := release
ARCHS := x86_64 arm64

# Help message
help: ## Show this help message
	@echo "MacDownloader - Build System"
	@echo "============================"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\t%-20s %s\n", $$1, $$2}'
	@echo ""

# Build everything
build: build-cli build-gui ## Build both CLI and GUI

# Build CLI
build-cli: ## Build the CLI tool
	@echo "Building MacDownloader CLI..."
	swift build -c $(CONFIG) --arch $(word 1, $(ARCHS))
	swift build -c $(CONFIG) --arch $(word 2, $(ARCHS))
	@echo "Creating universal binary..."
	mkdir -p $(BUILD_DIR)/universal
	lipo -create \
		$(BUILD_DIR)/$(word 1, $(ARCHS))-apple-macosx/$(CONFIG)/macdownloader \
		$(BUILD_DIR)/$(word 2, $(ARCHS))-apple-macosx/$(CONFIG)/macdownloader \
		-output $(BUILD_DIR)/universal/macdownloader
	chmod +x $(BUILD_DIR)/universal/macdownloader
	@echo "CLI built successfully at $(BUILD_DIR)/universal/macdownloader"

# Build GUI application
build-gui: ## Build the GUI application
	@echo "Building MacDownloader GUI..."
	@echo "Note: For best results, open in Xcode and build MacDownloaderApp target"
	swift build -c $(CONFIG) --arch $(word 1, $(ARCHS))
	swift build -c $(CONFIG) --arch $(word 2, $(ARCHS))
	@echo "GUI components built"

# Run tests
test: ## Run all tests
	@echo "Running tests..."
	swift test -c $(CONFIG)

# Clean build artifacts
clean: ## Clean all build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -rf Package.resolved
	rm -rf *.xcodeproj
	@echo "Cleaned successfully"

# Install CLI
install: build-cli ## Install the CLI to /usr/local/bin
	@echo "Installing CLI..."
	@mkdir -p /usr/local/bin
	sudo cp $(BUILD_DIR)/universal/macdownloader /usr/local/bin/macdownloader
	sudo chmod +x /usr/local/bin/macdownloader
	@echo "CLI installed to /usr/local/bin/macdownloader"

# Uninstall CLI
uninstall: ## Uninstall the CLI
	@echo "Uninstalling CLI..."
	sudo rm -f /usr/local/bin/macdownloader
	sudo rm -f /usr/bin/macdownloader
	@echo "CLI uninstalled"

# Run CLI
run-cli: build-cli ## Run the CLI
	@echo "Running CLI..."
	$(BUILD_DIR)/universal/macdownloader

# Run CLI with arguments
run-cli-%: build-cli ## Run CLI with arguments (e.g., make run-cli---help)
	@echo "Running CLI with arguments: $(subst run-cli-,,$@)"
	$(BUILD_DIR)/universal/macdownloader $(subst run-cli-,,$@)

# Create distribution package
package: build-cli ## Create a distributable package
	@echo "Creating distribution package..."
	mkdir -p $(DIST_DIR)
	cp $(BUILD_DIR)/universal/macdownloader $(DIST_DIR)/
	cp install.sh $(DIST_DIR)/
	cp Documentation/README.md $(DIST_DIR)/
	cp Documentation/LICENSE $(DIST_DIR)/
	@echo "Package created in $(DIST_DIR)/"

# Open in Xcode
xcode: ## Open the project in Xcode
	@echo "Opening project in Xcode..."
	swift package generate-xcodeproj
	open MacDownloader.xcodeproj

# Update dependencies
update-deps: ## Update Swift Package dependencies
	@echo "Updating dependencies..."
	swift package update
	swift package resolve

# Resolve dependencies
resolve-deps: ## Resolve Swift Package dependencies
	@echo "Resolving dependencies..."
	swift package resolve

# Show version
version: ## Show version
	@echo "MacDownloader v$(VERSION)"

# Clean and rebuild
rebuild: clean build ## Clean and rebuild everything

# Build for development (debug mode)
debug: ## Build in debug mode
	@echo "Building in debug mode..."
	swift build -c debug

# Build with tests
test-build: test ## Build and run tests

# Show build info
info: ## Show build information
	@echo "MacDownloader Build Information"
	@echo "=============================="
	@echo "Version: $(VERSION)"
	@echo "Swift version: $(shell swift --version | head -n1)"
	@echo "macOS version: $(shell sw_vers -productVersion)"
	@echo "Build directory: $(BUILD_DIR)"
	@echo "Architectures: $(ARCHS)"
	@echo "Configuration: $(CONFIG)"
