# MacDownloader

A powerful, open-source video downloader for macOS, similar to Downie but completely free and open source.

## Features

- **Multi-site support**: Download videos from YouTube, Vimeo, Dailymotion, Facebook, Instagram, Twitter/X, TikTok, Reddit, Twitch, SoundCloud, and more
- **Multiple qualities**: Choose from available video qualities (when supported by the site)
- **CLI and GUI**: Use either the command-line interface or the native macOS application
- **Queue system**: Add multiple downloads to a queue and manage them efficiently
- **Batch downloads**: Download multiple videos from a file containing URLs
- **Video information**: Get detailed information about videos before downloading
- **Custom output**: Specify output directory and filename
- **Recent history**: Keep track of your recent downloads

## Installation

### CLI Installation

1. Clone the repository:
```bash
git clone https://github.com/MrFlappy0/MacDownloader.git
cd MacDownloader
```

2. Build the CLI:
```bash
swift build -c release
```

3. The CLI will be available at `.build/release/macdownloader`

4. (Optional) Install it globally:
```bash
cp .build/release/macdownloader /usr/local/bin/macdownloader
```

### GUI Installation

1. Open the project in Xcode
2. Select the `MacDownloaderApp` target
3. Build and run (⌘R)
4. Or archive and export for distribution

## CLI Usage

```bash
# Show help
macdownloader help

# Download a video
macdownloader download https://youtube.com/watch?v=dQw4w9WgXcQ

# Download with specific quality
macdownloader download -q 1080p https://youtube.com/watch?v=dQw4w9WgXcQ

# Download to specific directory
macdownloader download -o ~/Downloads/Videos https://youtube.com/watch?v=dQw4w9WgXcQ

# Get video information
macdownloader info https://youtube.com/watch?v=dQw4w9WgXcQ

# Get video information in JSON format
macdownloader info --json https://youtube.com/watch?v=dQw4w9WgXcQ

# Batch download from file
macdownloader batch -f urls.txt

# List supported sites
macdownloader list
```

### CLI Options

**Download Command:**
- `-q, --quality <quality>`: Specify video quality (e.g., 1080p, 720p, hd, sd)
- `-o, --output <path>`: Specify output directory
- `-n, --filename <name>`: Specify output filename (without extension)
- `--overwrite`: Overwrite existing files
- `--no-progress`: Hide download progress

**Info Command:**
- `-q, --quality <quality>`: Filter by quality
- `--json`: Output in JSON format

**Batch Command:**
- `-f, --file <path>`: Path to file containing URLs (one per line)
- `-o, --output <path>`: Specify output directory
- `-q, --quality <quality>`: Specify video quality
- `--overwrite`: Overwrite existing files

## GUI Usage

1. Launch the MacDownloader application
2. Enter a video URL in the input field
3. (Optional) Select a quality from the dropdown
4. Click "Download" or press Enter
5. View your downloads in the queue and history

### Keyboard Shortcuts

- `⌘ + ,`: Open Settings
- `⌘ + Q`: Quit MacDownloader
- `⌘ + N`: Add new download
- `⌘ + T`: Open download queue

## Supported Sites

- YouTube
- Vimeo
- Dailymotion
- Facebook
- Instagram
- Twitter/X
- TikTok
- Reddit
- Twitch
- SoundCloud
- Generic video sites (via og:video meta tag)

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later
- Xcode 15 or later

## Dependencies

- [Alamofire](https://github.com/Alamofire/Alamofire) - Networking library
- [SwiftSoup](https://github.com/scinfu/SwiftSoup) - HTML parsing library

## Project Structure

```
MacDownloader/
├── Sources/
│   ├── MacDownloaderCore/     # Shared download logic
│   │   ├── VideoDownloader.swift    # Main downloader class
│   │   ├── SupportedSites.swift     # Supported sites information
│   │   └── DownloadQueue.swift      # Queue management
│   ├── MacDownloaderCLI/      # Command-line interface
│   │   └── main.swift              # CLI entry point
│   └── MacDownloaderApp/      # macOS GUI application
│       ├── MacDownloaderApp.swift  # App entry point
│       ├── ContentView.swift        # Main content view
│       ├── SidebarView.swift        # Sidebar navigation
│       ├── DownloadQueueView.swift # Queue management view
│       ├── SettingsView.swift        # Settings view
│       └── VideoInfoSheet.swift      # Video information sheet
├── Resources/                    # App resources
│   └── Info.plist                 # App info plist
├── Documentation/                # Documentation
│   └── README.md                  # This file
└── Package.swift                  # Swift Package Manager manifest
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [Downie](https://software.charliemonroe.net/downie.php)
- Built with [Swift](https://swift.org/) and [SwiftUI](https://developer.apple.com/documentation/swiftui)
- Uses [Alamofire](https://github.com/Alamofire/Alamofire) for networking
- Uses [SwiftSoup](https://github.com/scinfu/SwiftSoup) for HTML parsing
