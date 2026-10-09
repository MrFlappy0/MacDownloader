# MacDownloader - Installation Guide

This guide provides comprehensive installation instructions for MacDownloader on macOS.

## 📋 System Requirements

- **macOS**: Ventura (13.0) or later
- **Swift**: 5.9 or later
- **Xcode**: 15.0 or later (for GUI application)
- **Disk Space**: ~500MB for dependencies

## 🚀 Quick Installation Methods

Choose one of the following installation methods:

### Method 1: Automatic Installation (Recommended)

Run the installation script:

```bash
# Clone the repository
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader

# Make the script executable
chmod +x install.sh

# Run the installer
./install.sh
```

This will:
1. Check system requirements
2. Install Homebrew (if not installed)
3. Install required dependencies
4. Build the CLI
5. Install to `/usr/local/bin/macdownloader`

### Method 2: Using Make

```bash
# Clone the repository
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader

# Build and install
make install
```

### Method 3: Manual Installation

```bash
# Clone the repository
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader

# Resolve dependencies
swift package resolve

# Build in release mode
swift build -c release --arch x86_64 --arch arm64

# Create universal binary
mkdir -p .build/universal
lipo -create \
    .build/x86_64-apple-macosx/release/macdownloader \
    .build/arm64-apple-macosx/release/macdownloader \
    -output .build/universal/macdownloader

# Install
sudo cp .build/universal/macdownloader /usr/local/bin/macdownloader
sudo chmod +x /usr/local/bin/macdownloader
```

## 🍺 Homebrew Installation

### Option A: Install from Custom Tap

```bash
# Add the custom tap
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader

# Run the Homebrew installer
./scripts/install_homebrew.sh
```

### Option B: Manual Tap Creation

```bash
# Create a local tap
mkdir -p $(brew --repository)/Library/Taps/mrflappy0/homebrew-tap
cp scripts/homebrew/macdownloader.rb $(brew --repository)/Library/Taps/mrflappy0/homebrew-tap/

# Install the formula
brew install mrflappy0/tap/macdownloader
```

### Option C: Using a Custom Tap Repository

If you want to create a proper Homebrew tap:

```bash
# Create a new repository for the tap
git clone https://github.com/mrflappy0/homebrew-tap.git
cd homebrew-tap

# Create the formula directory
mkdir -p Formula
cp ../MacDownloader/scripts/homebrew/macdownloader.rb Formula/

# Commit and push
git add Formula/macdownloader.rb
git commit -m "Add MacDownloader formula"
git push origin main

# Then install
brew tap mrflappy0/tap
brew install macdownloader
```

## 📦 GUI Application Installation

### Using Xcode (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/MrFlappy0/MacDownloader.git
   cd MacDownloader
   ```

2. Generate Xcode project:
   ```bash
   swift package generate-xcodeproj
   ```

3. Open in Xcode:
   ```bash
   open MacDownloader.xcodeproj
   ```

4. In Xcode:
   - Select the `MacDownloaderApp` scheme
   - Build (⌘B)
   - Run (⌘R)

5. The application will be available in the `DerivedData` folder or you can:
   - Go to Products folder in Xcode
   - Right-click on MacDownloaderApp
   - Select "Show in Finder"

### Using Make

```bash
# Build GUI components
make build-gui

# Then open MacDownloader.xcodeproj in Xcode
open MacDownloader.xcodeproj
```

## 🔧 Post-Installation Setup

### Shell Completions

MacDownloader includes shell completions for Bash, Zsh, and Fish:

**Bash:**
```bash
# Copy completion script
sudo cp scripts/completions/macdownloader.bash /etc/bash_completion.d/macdownloader

# Or source it in your .bashrc
echo "source $(brew --prefix)/etc/bash_completion.d/macdownloader" >> ~/.bashrc
source ~/.bashrc
```

**Zsh:**
```bash
# Copy completion script
sudo cp scripts/completions/_macdownloader /usr/local/share/zsh/site-functions/_macdownloader

# Or add to your .zshrc
echo "fpath=($$(brew --prefix)/share/zsh/site-functions $fpath)" >> ~/.zshrc
source ~/.zshrc
```

**Fish:**
```bash
# Copy completion script
sudo cp scripts/completions/macdownloader.fish /usr/local/share/fish/vendor_completions.d/macdownloader.fish
```

### Environment Variables

You can configure MacDownloader with environment variables:

```bash
# Set default download location
export MACDOWNLOADER_DOWNLOAD_DIR="$HOME/Downloads/Videos"

# Set default quality
export MACDOWNLOADER_DEFAULT_QUALITY="1080p"

# Enable verbose output
export MACDOWNLOADER_VERBOSE="true"
```

## ⚡ Quick Start

After installation, try these commands:

```bash
# Show help
macdownloader --help

# Download a YouTube video
macdownloader download https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Download with specific quality
macdownloader download -q 1080p https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Get video information
macdownloader info https://www.youtube.com/watch?v=dQw4w9WgXcQ

# List supported sites
macdownloader list
```

## 🔄 Updating

### If installed via script:

```bash
cd MacDownloader
git pull origin main
./install.sh
```

### If installed via Homebrew:

```bash
brew update
brew upgrade macdownloader
```

## 🗑️ Uninstalling

### Using the uninstall script:

```bash
# If you used install.sh
/tmp/uninstall_macdownloader.sh

# Or manually
sudo rm /usr/local/bin/macdownloader
sudo rm /usr/bin/macdownloader
rm -rf ~/MacDownloader
```

### If installed via Homebrew:

```bash
brew uninstall macdownloader
brew untap mrflappy0/tap
```

## 🐛 Troubleshooting

### "Command not found" after installation

1. Check if the binary exists:
   ```bash
   ls -la /usr/local/bin/macdownloader
   ```

2. Make sure it's executable:
   ```bash
   chmod +x /usr/local/bin/macdownloader
   ```

3. Add to PATH if needed:
   ```bash
   echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

### Swift Package Manager errors

1. Update Swift Package Manager:
   ```bash
   swift package update
   ```

2. Clean and rebuild:
   ```bash
   rm -rf .build
   swift build
   ```

### Missing dependencies

1. Install Xcode command line tools:
   ```bash
   xcode-select --install
   ```

2. Install Homebrew:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Install required packages:
   ```bash
   brew install git curl wget
   ```

### macOS version too old

MacDownloader requires macOS Ventura (13.0) or later. If you're on an older version:

1. Upgrade your macOS
2. Or use a compatible version of Swift for your macOS version

### Network errors

If you're behind a proxy or firewall:

```bash
# Set proxy for git
git config --global http.proxy http://proxy.example.com:8080

# Set proxy for Homebrew
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
```

## 📊 Verifying Installation

```bash
# Check version
macdownloader --version

# Check help
macdownloader --help

# Test with a simple download
macdownloader info https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

## 📝 Release Notes

### Version 1.0.0
- Initial release
- Support for 10+ video sites
- CLI and GUI applications
- Download queue management
- Batch download support

## 🤝 Contributing

If you encounter issues during installation:

1. Check the [GitHub Issues](https://github.com/MrFlappy0/MacDownloader/issues)
2. Create a new issue with details about your system and the error
3. Include the output of:
   ```bash
   sw_vers -productVersion
   swift --version
   macdownloader --version
   ```

## 📄 License

MacDownloader is released under the MIT License. See [LICENSE](LICENSE) for details.
