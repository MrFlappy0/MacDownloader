# MacDownloader

<p align="center">
  <img src="https://img.shields.io/badge/macOS-Ventura%2B-blue?logo=apple" alt="macOS Ventura+">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  <img src="https://github.com/MrFlappy0/MacDownloader/actions/workflows/build.yml/badge.svg" alt="Build Status">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/MrFlappy0/MacDownloader/main/Resources/AppIcon.png" alt="MacDownloader Icon" width="128">
</p>

<h1 align="center">MacDownloader</h1>

<p align="center">
  A powerful, open-source video downloader for macOS - like Downie but free and open source!
</p>

<p align="center">
  <a href="#-features">Features</a> • 
  <a href="#-installation">Installation</a> • 
  <a href="#-usage">Usage</a> • 
  <a href="#-supported-sites">Supported Sites</a> • 
  <a href="#-screenshots">Screenshots</a> • 
  <a href="#-contributing">Contributing</a>
</p>

---

## 🌟 Features

### ✅ Core Features

- **Multi-site support**: Download from 10+ popular video platforms
- **Multiple qualities**: Choose from available video qualities when supported
- **CLI and GUI**: Use either command-line or graphical interface
- **Queue system**: Manage multiple downloads efficiently
- **Batch downloads**: Download multiple videos from a file
- **Video information**: Get detailed info before downloading
- **Custom output**: Specify download location and filename
- **Recent history**: Track your recent downloads

### 🎯 CLI Features

- Simple and intuitive command-line interface
- Shell completions for Bash, Zsh, and Fish
- JSON output for scripting
- Progress indicators
- Error handling with clear messages

### 🖥️ GUI Features

- Modern SwiftUI-based interface
- Native macOS look and feel
- Dark mode support
- System notifications
- Drag and drop URL support (coming soon)
- Download queue management

### ⚡ Performance

- Concurrent downloads (configurable)
- Resumable downloads
- Optimized for macOS
- Low memory footprint

---

## 📥 Installation

See the [complete installation guide](Documentation/INSTALL.md) for detailed instructions.

### 🚀 Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader

# Run the installer
chmod +x install.sh
./install.sh
```

### 🍺 Homebrew (Custom Tap)

```bash
# Add the custom tap
mkdir -p $(brew --repository)/Library/Taps/mrflappy0/homebrew-tap
curl -fsSL https://raw.githubusercontent.com/MrFlappy0/MacDownloader/main/scripts/homebrew/macdownloader.rb \
  -o $(brew --repository)/Library/Taps/mrflappy0/homebrew-tap/macdownloader.rb

# Install
brew install mrflappy0/tap/macdownloader
```

### 📦 Manual Install

```bash
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader
make install
```

### 🖥️ GUI Application

1. Open the project in Xcode:
   ```bash
   swift package generate-xcodeproj
   open MacDownloader.xcodeproj
   ```

2. Build and run the `MacDownloaderApp` target

---

## 💡 Usage

### CLI Usage

#### Basic Commands

```bash
# Show help
macdownloader --help

# Download a video
macdownloader download https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Download with specific quality
macdownloader download -q 1080p https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Download to specific directory
macdownloader download -o ~/Downloads/Videos https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Get video information
macdownloader info https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Get video information in JSON format
macdownloader info --json https://www.youtube.com/watch?v=dQw4w9WgXcQ

# List supported sites
macdownloader list
```

#### Batch Download

```bash
# Create a file with URLs (one per line)
cat > urls.txt << EOF
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://vimeo.com/123456789
https://www.tiktok.com/@user/video/123456789
EOF

# Download all videos from the file
macdownloader batch -f urls.txt

# Download to specific directory with quality
macdownloader batch -f urls.txt -o ~/Downloads/Videos -q 720p
```

#### All Options

```bash
# Download command
macdownloader download [OPTIONS] URL

# Options:
#   -q, --quality <quality>    Specify video quality (e.g., 1080p, 720p, HD, SD)
#   -o, --output <path>        Specify output directory
#   -n, --filename <name>     Specify output filename (without extension)
#   --overwrite              Overwrite existing files
#   --no-progress            Hide download progress

# Info command
macdownloader info [OPTIONS] URL

# Options:
#   -q, --quality <quality>    Filter by quality
#   --json                    Output in JSON format

# Batch command
macdownloader batch [OPTIONS]

# Options:
#   -f, --file <path>         Path to file containing URLs (one per line)
#   -o, --output <path>        Specify output directory
#   -q, --quality <quality>    Specify video quality
#   --overwrite              Overwrite existing files
```

### GUI Usage

1. **Launch the application** from Applications or via Spotlight
2. **Enter a video URL** in the input field
3. **(Optional)** Select a quality from the dropdown
4. **Click Download** or press Enter
5. **View progress** in the download queue
6. **Manage downloads** from the queue window

#### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘ + , | Open Settings |
| ⌘ + Q | Quit MacDownloader |
| ⌘ + N | Add new download |
| ⌘ + T | Open download queue |
| ⌘ + H | Hide MacDownloader |

---

## 🌐 Supported Sites

MacDownloader supports the following video platforms:

| Site | Quality Support | Format | Notes |
|------|----------------|--------|-------|
| 📺 **YouTube** | ✅ Multiple | MP4 | Full support |
| 🎬 **Vimeo** | ✅ Multiple | MP4 | Full support |
| 📹 **Dailymotion** | ✅ Multiple | MP4 | Full support |
| 👥 **Facebook** | ✅ Multiple | MP4 | Including fb.watch |
| 📷 **Instagram** | ❌ Single | MP4 | Reels and posts |
| 🐦 **Twitter/X** | ❌ Single | MP4 | Including x.com |
| 🎵 **TikTok** | ❌ Single | MP4 | Full support |
| 🔴 **Reddit** | ❌ Single | MP4 | Including v.redd.it |
| 🎮 **Twitch** | ✅ Multiple | MP4, M3U8 | Live and VOD |
| 🎵 **SoundCloud** | ❌ Single | MP3 | Audio only |
| 🌐 **Generic** | ❌ Single | Various | Via og:video meta tag |

### Requesting New Sites

If you'd like support for additional sites:

1. Check if the site has a public API or embeddable videos
2. Open an issue on GitHub with:
   - Site URL
   - Example video URL
   - Any API documentation if available

---

## 📸 Screenshots

### CLI Interface

```
$ macdownloader --help

⬇️  MacDownloader - A powerful video downloader for macOS

Usage: macdownloader [command] [options] [url]

Commands:
  download, d    Download a video
  info, i       Get video information without downloading
  batch, b      Download multiple videos from a file
  list, l       List supported sites
  help, h       Show this help message

Options for download command:
  -q, --quality <quality>    Specify video quality (e.g., 1080p, 720p, hd, sd)
  -o, --output <path>        Specify output directory
  -n, --filename <name>     Specify output filename (without extension)
  --overwrite              Overwrite existing files
  --no-progress            Hide download progress
```

### GUI Interface

<p align="center">
  <img src="https://raw.githubusercontent.com/MrFlappy0/MacDownloader/main/Documentation/Screenshots/main-window.png" alt="Main Window" width="600">
  <em>Main Application Window</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/MrFlappy0/MacDownloader/main/Documentation/Screenshots/queue.png" alt="Download Queue" width="600">
  <em>Download Queue Management</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/MrFlappy0/MacDownloader/main/Documentation/Screenshots/settings.png" alt="Settings" width="400">
  <em>Application Settings</em>
</p>

---

## 🛠 Development

### Prerequisites

- macOS Ventura (13.0) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader

# Generate Xcode project
swift package generate-xcodeproj

# Open in Xcode
open MacDownloader.xcodeproj
```

### Building from Command Line

```bash
# Build CLI
make build-cli

# Build GUI
make build-gui

# Build everything
make build

# Run tests
make test

# Clean build
make clean
```

### Project Structure

```
MacDownloader/
├── Sources/
│   ├── MacDownloaderCore/          # Shared download logic
│   │   ├── VideoDownloader.swift   # Main downloader class
│   │   ├── SupportedSites.swift    # Supported sites information
│   │   └── DownloadQueue.swift     # Queue management
│   ├── MacDownloaderCLI/           # Command-line interface
│   │   └── main.swift             # CLI entry point
│   └── MacDownloaderApp/           # macOS GUI application
│       ├── MacDownloaderApp.swift # App entry point
│       ├── ContentView.swift       # Main content view
│       ├── SidebarView.swift       # Navigation sidebar
│       ├── DownloadQueueView.swift # Queue management view
│       ├── SettingsView.swift       # Settings view
│       └── VideoInfoSheet.swift     # Video information sheet
├── Resources/
│   └── Info.plist                 # Application info
├── Documentation/
│   ├── README.md                  # This file
│   ├── INSTALL.md                 # Installation guide
│   └── LICENSE                    # License file
├── Scripts/
│   ├── install.sh                 # Installation script
│   ├── build_cli.sh               # CLI build script
│   ├── build_gui.sh               # GUI build script
│   ├── install_homebrew.sh        # Homebrew installer
│   ├── homebrew/
│   │   └── macdownloader.rb        # Homebrew formula
│   └── completions/
│       ├── macdownloader.bash     # Bash completions
│       ├── _macdownloader          # Zsh completions
│       └── macdownloader.fish      # Fish completions
├── Tests/
│   └── MacDownloaderCoreTests/    # Unit tests
│       ├── VideoDownloaderTests.swift
│       └── DownloadQueueTests.swift
├── Package.swift                   # Swift Package Manager manifest
└── Makefile                       # Make build system
```

### Adding New Features

1. **Adding a new site**:
   - Add site to `SupportedSite` enum
   - Implement extraction method in `VideoDownloader`
   - Add tests for the new site

2. **Adding CLI commands**:
   - Add command to `main.swift`
   - Add completion scripts
   - Update documentation

3. **Adding GUI features**:
   - Add new SwiftUI views
   - Update AppState as needed
   - Add to navigation

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test -c release MacDownloaderCoreTests

# Run with coverage
swift test --enable-code-coverage
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues

1. Check existing issues to avoid duplicates
2. Provide detailed information:
   - macOS version
   - Swift version
   - Steps to reproduce
   - Expected vs actual behavior
   - Error messages

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`make test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use descriptive names
- Add comments for complex logic
- Keep functions focused and short
- Write tests for new functionality

### Testing

- Add unit tests for new features
- Update existing tests if behavior changes
- Run `make test` before committing

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 MrFlappy0

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
```

---

## 🙏 Acknowledgments

- **Inspiration**: [Downie](https://software.charliemonroe.net/downie.php) - A great commercial video downloader
- **Technologies**:
  - [Swift](https://swift.org/) - The programming language
  - [SwiftUI](https://developer.apple.com/documentation/swiftui) - UI framework
  - [Alamofire](https://github.com/Alamofire/Alamofire) - Networking library
  - [SwiftSoup](https://github.com/scinfu/SwiftSoup) - HTML parsing library
  - [Homebrew](https://brew.sh/) - Package manager for macOS

- **Contributors**: Thanks to everyone who contributes!

---

## 📞 Contact

- **GitHub**: [MrFlappy0](https://github.com/MrFlappy0)
- **Repository**: [MacDownloader](https://github.com/MrFlappy0/MacDownloader)
- **Issues**: [GitHub Issues](https://github.com/MrFlappy0/MacDownloader/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MrFlappy0/MacDownloader/discussions)

---

<p align="center">
  Made with ❤️ for macOS
</p>

<p align="center">
  <a href="https://github.com/MrFlappy0/MacDownloader/stargazers">
    <img src="https://img.shields.io/github/stars/MrFlappy0/MacDownloader?style=social" alt="Star on GitHub">
  </a>
  <a href="https://github.com/MrFlappy0/MacDownloader/forks">
    <img src="https://img.shields.io/github/forks/MrFlappy0/MacDownloader?style=social" alt="Fork on GitHub">
  </a>
</p>
