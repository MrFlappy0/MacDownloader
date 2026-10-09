# MacDownloader

<p align="center">
  <img alt="MacDownloader Icon" src="https://img.icons8.com/ios-filled/100/000000/download--v1.png" width="128" />
</p>

<h1 align="center">⬇️ MacDownloader</h1>

<p align="center">
  <i>A powerful, open-source video downloader for macOS — like Downie but free!</i>
</p>

<p align="center">
  <a href="https://github.com/MrFlappy0/MacDownloader/releases"><img src="https://img.shields.io/github/v/release/MrFlappy0/MacDownloader?style=flat-square" alt="Latest Release" /></a>
  <img src="https://img.shields.io/badge/macOS-Ventura%2B-blue?logo=apple&style=flat-square" alt="macOS Ventura+" />
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift&style=flat-square" alt="Swift 5.9+" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License" />
  <img src="https://img.shields.io/github/stars/MrFlappy0/MacDownloader?style=social" alt="GitHub Stars" />
</p>

---

## ✨ Features

✅ **Multi-Site Support** — Download from YouTube, Vimeo, Dailymotion, Facebook, Instagram, Twitter/X, TikTok, Reddit, Twitch, SoundCloud, and more!
✅ **Multiple Qualities** — Choose from available video qualities (1080p, 720p, 480p, etc.)
✅ **CLI & GUI** — Use the powerful command-line interface or the native macOS app
✅ **Queue System** — Add and manage multiple downloads efficiently
✅ **Batch Downloads** — Download multiple videos from a text file
✅ **Video Info** — Get detailed information before downloading
✅ **Custom Output** — Specify download location and filename
✅ **Shell Completions** — Bash, Zsh, and Fish shell completions included
✅ **Homebrew Support** — Easy installation via Homebrew tap

---

## 🚀 Quick Start

### 📥 Installation

#### **Method 1: Automatic (Recommended)**
```bash
# Clone and run the installer
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader
chmod +x install.sh
./install.sh
```

#### **Method 2: One-Line Install**
```bash
curl -fsSL https://raw.githubusercontent.com/MrFlappy0/MacDownloader/main/install.sh | bash
```

#### **Method 3: Homebrew**
```bash
# Add custom tap
mkdir -p $(brew --repository)/Library/Taps/mrflappy0/homebrew-tap
curl -fsSL https://raw.githubusercontent.com/MrFlappy0/MacDownloader/main/scripts/homebrew/macdownloader.rb \
  -o $(brew --repository)/Library/Taps/mrflappy0/homebrew-tap/macdownloader.rb

# Install
brew install mrflappy0/tap/macdownloader
```

#### **Method 4: Manual**
```bash
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader
make install
```

---

### 💡 Usage

#### **CLI Examples**

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

# Batch download from file
macdownloader batch -f urls.txt

# List supported sites
macdownloader list
```

#### **GUI Application**

1. Open the project in Xcode:
   ```bash
   swift package generate-xcodeproj
   open MacDownloader.xcodeproj
   ```
2. Build and run the `MacDownloaderApp` target
3. Use the intuitive SwiftUI interface to download videos

---

## 🌐 Supported Sites

| Site | Status | Quality Support | Format |
|------|--------|-----------------|--------|
| 📺 YouTube | ✅ | Multiple | MP4 |
| 🎬 Vimeo | ✅ | Multiple | MP4 |
| 📹 Dailymotion | ✅ | Multiple | MP4 |
| 👥 Facebook | ✅ | Multiple | MP4 |
| 📷 Instagram | ✅ | Single | MP4 |
| 🐦 Twitter/X | ✅ | Single | MP4 |
| 🎵 TikTok | ✅ | Single | MP4 |
| 🔴 Reddit | ✅ | Single | MP4 |
| 🎮 Twitch | ✅ | Multiple | MP4, M3U8 |
| 🎵 SoundCloud | ✅ | Single | MP3 |
| 🌐 Generic | ✅ | Single | Various |

---

## 📦 Project Structure

```
MacDownloader/
├── README.md                          # This file
├── install.sh                         # Automatic installation script
├── Makefile                           # Build commands
├── Package.swift                      # Swift Package Manager manifest
├── Sources/
│   ├── MacDownloaderCore/           # Shared download logic
│   │   ├── VideoDownloader.swift     # Main downloader class
│   │   ├── SupportedSites.swift      # Site support information
│   │   └── DownloadQueue.swift        # Queue management
│   ├── MacDownloaderCLI/            # Command-line interface
│   │   └── main.swift                # CLI entry point
│   └── MacDownloaderApp/            # macOS GUI application
│       ├── MacDownloaderApp.swift    # App entry point
│       ├── ContentView.swift         # Main view
│       ├── SidebarView.swift         # Navigation
│       ├── DownloadQueueView.swift   # Queue management
│       ├── SettingsView.swift         # Settings
│       └── VideoInfoSheet.swift       # Video info display
├── Scripts/
│   ├── build_cli.sh                   # CLI build script
│   ├── build_gui.sh                   # GUI build script
│   ├── install_homebrew.sh            # Homebrew installer
│   ├── homebrew/
│   │   └── macdownloader.rb           # Homebrew formula
│   └── completions/
│       ├── macdownloader.bash        # Bash completions
│       ├── _macdownloader             # Zsh completions
│       └── macdownloader.fish         # Fish completions
├── Resources/
│   └── Info.plist                     # App info
├── Documentation/
│   ├── INSTALL.md                     # Detailed installation guide
│   └── LICENSE                        # License file
└── Tests/
    └── MacDownloaderCoreTests/       # Unit tests
        ├── VideoDownloaderTests.swift
        └── DownloadQueueTests.swift
```

---

## 🛠 Development

### Prerequisites
- **macOS**: Ventura (13.0) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

### Setup
```bash
# Clone the repository
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader

# Generate Xcode project
swift package generate-xcodeproj

# Open in Xcode
open MacDownloader.xcodeproj
```

### Build Commands
```bash
# Build everything
make build

# Build CLI only
make build-cli

# Build GUI only
make build-gui

# Install CLI
make install

# Run tests
make test

# Clean build
make clean
```

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`make test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

---

## 📜 License

This project is licensed under the **MIT License** — see [LICENSE](Documentation/LICENSE) for details.

---

## 🙏 Acknowledgments

- Inspired by [Downie](https://software.charliemonroe.net/downie.php)
- Built with [Swift](https://swift.org/) and [SwiftUI](https://developer.apple.com/documentation/swiftui)
- Uses [Alamofire](https://github.com/Alamofire/Alamofire) for networking
- Uses [SwiftSoup](https://github.com/scinfu/SwiftSoup) for HTML parsing

---

## 📞 Contact

- **Repository**: [MrFlappy0/MacDownloader](https://github.com/MrFlappy0/MacDownloader)
- **Issues**: [GitHub Issues](https://github.com/MrFlappy0/MacDownloader/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MrFlappy0/MacDownloader/discussions)

---

<p align="center">
  Made with ❤️ for macOS<br />
  <sub>Copyright © 2024 MrFlappy0. All rights reserved.</sub>
</p>
