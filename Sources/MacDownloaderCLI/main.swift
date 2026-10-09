#!/usr/bin/env swift

import Foundation
import MacDownloaderCore

@main
struct MacDownloaderCLI {
    static func main() async {
        let arguments = CommandLine.arguments
        
        if arguments.count < 2 {
            printUsage()
            return
        }
        
        let command = arguments[1].lowercased()
        let downloader = VideoDownloader()
        
        do {
            switch command {
            case "download", "d":
                await handleDownload(arguments: Array(arguments.dropFirst(2)), downloader: downloader)
            case "info", "i":
                await handleInfo(arguments: Array(arguments.dropFirst(2)), downloader: downloader)
            case "batch", "b":
                await handleBatch(arguments: Array(arguments.dropFirst(2)), downloader: downloader)
            case "list", "l":
                listSupportedSites()
            case "help", "h", "--help", "-h":
                printUsage()
            default:
                print("Unknown command: '" + command + "'")
                printUsage()
            }
        } catch {
            printError("Error: " + error.localizedDescription)
            exit(1)
        }
    }
    
    static func printUsage() {
        let executableName = (CommandLine.arguments.first ?? "macdownloader").split(separator: "/").last ?? "macdownloader"
        
        print("""
        ⬇️  MacDownloader - A powerful video downloader for macOS
        
        Usage: \u{001B}[1m}(executableName)\u{001B}[0m [command] [options] [url]
        
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
        
        Options for info command:
          -q, --quality <quality>    Filter by quality
          --json                    Output in JSON format
        
        Options for batch command:
          -f, --file <path>         Path to file containing URLs (one per line)
          -o, --output <path>        Specify output directory
          -q, --quality <quality>    Specify video quality
          --overwrite              Overwrite existing files
        
        Examples:
          \u{001B}[1m(executableName) d https://youtube.com/watch?v=dQw4w9WgXcQ\u{001B}[0m
          \u{001B}[1m(executableName) d -q 1080p https://youtube.com/watch?v=dQw4w9WgXcQ\u{001B}[0m
          \u{001B}[1m(executableName) d -o ~/Downloads/Videos https://vimeo.com/123456789\u{001B}[0m
          \u{001B}[1m(executableName) i https://twitter.com/user/status/123456789\u{001B}[0m
          \u{001B}[1m(executableName) b -f urls.txt -o ~/Downloads/Videos\u{001B}[0m
          \u{001B}[1m(executableName) l\u{001B}[0m
        
        Supported Sites:
          YouTube, Vimeo, Dailymotion, Facebook, Instagram, Twitter/X, TikTok, Reddit, Twitch, SoundCloud
        
        Version: 1.0.0
        """)
    }
    
    static func listSupportedSites() {
        print("Supported Sites:")
        print("----------------")
        for site in SupportedSite.allCases {
            print("  • " + site.rawValue + " (" + site.domain + ")")
        }
    }
    
    static func handleDownload(arguments: [String], downloader: VideoDownloader) async {
        var options = DownloadOptions()
        var urls: [String] = []
        
        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            
            switch arg {
            case "-q", "--quality":
                i += 1
                if i < arguments.count {
                    options.quality = arguments[i]
                }
            case "-o", "--output":
                i += 1
                if i < arguments.count {
                    options.outputPath = URL(fileURLWithPath: arguments[i])
                }
            case "-n", "--filename":
                i += 1
                if i < arguments.count {
                    options.filename = arguments[i]
                }
            case "--overwrite":
                options.overwrite = true
            case "--no-progress":
                options.showProgress = false
            default:
                if arg.hasPrefix("-") {
                    printError("Unknown option: '" + arg + "'")
                    printUsage()
                    return
                }
                urls.append(arg)
            }
            
            i += 1
        }
        
        guard !urls.isEmpty else {
            printError("No URL provided")
            printUsage()
            return
        }
        
        for url in urls {
            await downloadVideo(url: url, options: options, downloader: downloader)
        }
    }
    
    static func handleInfo(arguments: [String], downloader: VideoDownloader) async {
        var options = InfoOptions()
        var urls: [String] = []
        
        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            
            switch arg {
            case "-q", "--quality":
                i += 1
                if i < arguments.count {
                    options.qualityFilter = arguments[i]
                }
            case "--json":
                options.jsonOutput = true
            default:
                if arg.hasPrefix("-") {
                    printError("Unknown option: '" + arg + "'")
                    printUsage()
                    return
                }
                urls.append(arg)
            }
            
            i += 1
        }
        
        guard !urls.isEmpty else {
            printError("No URL provided")
            printUsage()
            return
        }
        
        for url in urls {
            await getVideoInfo(url: url, options: options, downloader: downloader)
        }
    }
    
    static func handleBatch(arguments: [String], downloader: VideoDownloader) async {
        var options = DownloadOptions()
        var filePath: String?
        var urls: [String] = []
        
        var i = 0
        while i < arguments.count {
            let arg = arguments[i]
            
            switch arg {
            case "-f", "--file":
                i += 1
                if i < arguments.count {
                    filePath = arguments[i]
                }
            case "-o", "--output":
                i += 1
                if i < arguments.count {
                    options.outputPath = URL(fileURLWithPath: arguments[i])
                }
            case "-q", "--quality":
                i += 1
                if i < arguments.count {
                    options.quality = arguments[i]
                }
            case "--overwrite":
                options.overwrite = true
            default:
                if arg.hasPrefix("-") {
                    printError("Unknown option: '" + arg + "'")
                    printUsage()
                    return
                }
                urls.append(arg)
            }
            
            i += 1
        }
        
        // Read URLs from file
        if let filePath = filePath {
            do {
                let contents = try String(contentsOfFile: filePath, encoding: .utf8)
                let fileURLs = contents.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                urls.append(contentsOf: fileURLs)
            } catch {
                printError("Failed to read file: " + error.localizedDescription)
                return
            }
        }
        
        guard !urls.isEmpty else {
            printError("No URLs provided")
            printUsage()
            return
        }
        
        print("Starting batch download of " + String(urls.count) + " videos...")
        print()
        
        for (index, url) in urls.enumerated() {
            print("[" + String(index + 1) + "/" + String(urls.count) + "] Downloading: " + url)
            await downloadVideo(url: url, options: options, downloader: downloader, showIndex: false)
            print()
        }
        
        print("Batch download completed!")
    }
    
    static func downloadVideo(url: String, options: DownloadOptions, downloader: VideoDownloader, showIndex: Bool = true) async {
        do {
            // Extract video info
            let videoInfos = try await downloader.extractVideoInfo(from: url)
            
            guard !videoInfos.isEmpty else {
                printError("No video found at URL: " + url)
                return
            }
            
            // Filter by quality if specified
            let filteredInfos = options.quality != nil ?
                videoInfos.filter { $0.quality?.lowercased() == options.quality?.lowercased() } :
                videoInfos
            
            guard let videoInfo = filteredInfos.first else {
                printError("No video found matching quality: " + (options.quality ?? ""))
                return
            }
            
            // Determine output path
            let outputPath = options.outputPath ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let filename = options.filename ?? videoInfo.title
            let sanitizedFilename = sanitizeFilename(filename) + "." + videoInfo.format
            let outputURL = outputPath.appendingPathComponent(sanitizedFilename)
            
            // Check if file exists
            if !options.overwrite && FileManager.default.fileExists(atPath: outputURL.path) {
                printError("File already exists: " + outputURL.path)
                print("Use --overwrite to replace existing files")
                return
            }
            
            // Print video info
            if showIndex {
                printVideoInfo(videoInfo)
            }
            
            // Download
            print("Downloading to: " + outputURL.path)
            
            let finalURL = try await downloader.downloadVideo(
                from: url,
                quality: options.quality,
                outputPath: outputURL
            )
            
            printSuccess("Download completed: " + finalURL.path)
            
        } catch let error as DownloadError {
            switch error {
            case .invalidURL:
                printError("Invalid URL: " + url)
            case .noVideoFound:
                printError("No video found at URL: " + url)
            case .unsupportedSite:
                printError("Unsupported site: " + url)
            case .extractionFailed(let message):
                printError("Failed to extract video: " + message)
            case .downloadFailed(let underlyingError):
                printError("Download failed: " + underlyingError.localizedDescription)
            case .fileWriteFailed(let underlyingError):
                printError("Failed to save file: " + underlyingError.localizedDescription)
            }
        } catch {
            printError("Error: " + error.localizedDescription)
        }
    }
    
    static func getVideoInfo(url: String, options: InfoOptions, downloader: VideoDownloader) async {
        do {
            let videoInfos = try await downloader.extractVideoInfo(from: url)
            
            guard !videoInfos.isEmpty else {
                printError("No video found at URL: " + url)
                return
            }
            
            // Filter by quality if specified
            let filteredInfos = options.qualityFilter != nil ?
                videoInfos.filter { $0.quality?.lowercased() == options.qualityFilter?.lowercased() } :
                videoInfos
            
            if options.jsonOutput {
                printJSON(videoInfos: filteredInfos)
            } else {
                print("Video Information for: " + url)
                print("=" * 60)
                for (index, videoInfo) in filteredInfos.enumerated() {
                    if index > 0 {
                        print("-" * 60)
                    }
                    printVideoInfo(videoInfo, detailed: true)
                }
            }
            
        } catch let error as DownloadError {
            switch error {
            case .invalidURL:
                printError("Invalid URL: " + url)
            case .noVideoFound:
                printError("No video found at URL: " + url)
            case .unsupportedSite:
                printError("Unsupported site: " + url)
            case .extractionFailed(let message):
                printError("Failed to extract video: " + message)
            default:
                printError("Error: " + error.localizedDescription)
            }
        } catch {
            printError("Error: " + error.localizedDescription)
        }
    }
    
    static func printVideoInfo(_ videoInfo: VideoInfo, detailed: Bool = false) {
        print("Title: " + videoInfo.title)
        
        if detailed {
            print("URL: " + videoInfo.url.absoluteString)
        }
        
        if let quality = videoInfo.quality {
            print("Quality: " + quality)
        }
        
        if let duration = videoInfo.duration {
            print("Duration: " + formatDuration(duration))
        }
        
        if let thumbnailURL = videoInfo.thumbnailURL {
            print("Thumbnail: " + thumbnailURL.absoluteString)
        }
        
        print("Format: " + videoInfo.format)
        
        if detailed {
            if let site = SupportedSite.site(from: videoInfo.url.absoluteString) {
                print("Site: " + site.rawValue)
            }
        }
    }
    
    static func printJSON(videoInfos: [VideoInfo]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        struct VideoInfoJSON: Codable {
            let title: String
            let url: String
            let thumbnailURL: String?
            let duration: TimeInterval?
            let quality: String?
            let format: String
        }
        
        let jsonInfos = videoInfos.map { VideoInfoJSON(
            title: $0.title,
            url: $0.url.absoluteString,
            thumbnailURL: $0.thumbnailURL?.absoluteString,
            duration: $0.duration,
            quality: $0.quality,
            format: $0.format
        ) }
        
        do {
            let data = try encoder.encode(jsonInfos)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            printError("Failed to encode JSON: " + error.localizedDescription)
        }
    }
    
    static func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:?*\"<>|\n\r\t")
        let sanitized = filename.components(separatedBy: invalidCharacters).joined(separator: "_")
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    static func printError(_ message: String) {
        fputs("\u{001B}[31m✗ " + message + "\u{001B}[0m\n", stderr)
    }
    
    static func printSuccess(_ message: String) {
        fputs("\u{001B}[32m✓ " + message + "\u{001B}[0m\n", stdout)
    }
}

struct DownloadOptions {
    var quality: String?
    var outputPath: URL?
    var filename: String?
    var overwrite: Bool = false
    var showProgress: Bool = true
}

struct InfoOptions {
    var qualityFilter: String?
    var jsonOutput: Bool = false
}

// Helper extension for String
fileprivate extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
