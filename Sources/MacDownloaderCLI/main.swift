#!/usr/bin/env swift

import Foundation
import MacDownloaderCore

@main
struct MacDownloaderCLI {
    
    // Color codes for terminal output
    private static let RESET = "\u{001B}[0m"
    private static let BOLD = "\u{001B}[1m"
    private static let RED = "\u{001B}[31m"
    private static let GREEN = "\u{001B}[32m"
    private static let YELLOW = "\u{001B}[33m"
    private static let BLUE = "\u{001B}[34m"
    private static let MAGENTA = "\u{001B}[35m"
    private static let CYAN = "\u{001B}[36m"
    private static let WHITE = "\u{001B}[37m"
    
    static func main() async {
        let arguments = CommandLine.arguments
        
        // Check if FFmpeg is available
        let ffmpegAvailable = FFmpegWrapper.isFFmpegAvailable
        
        if arguments.count < 2 {
            printUsage(ffmpegAvailable: ffmpegAvailable)
            return
        }
        
        let command = arguments[1].lowercased()
        let downloader = VideoDownloader()
        
        do {
            switch command {
            case "d", "download":
                await handleDownload(arguments: Array(arguments.dropFirst(2)), downloader: downloader)
            case "g", "get":
                await handleGet(arguments: Array(arguments.dropFirst(2)), downloader: downloader)
            case "i", "info":
                await handleInfo(arguments: Array(arguments.dropFirst(2)), downloader: downloader)
            case "b", "batch":
                await handleBatch(arguments: Array(arguments.dropFirst(2)), downloader: downloader)
            case "l", "list":
                listSupportedSites()
            case "c", "convert":
                if ffmpegAvailable {
                    await handleConvert(arguments: Array(arguments.dropFirst(2)))
                } else {
                    printError("FFmpeg is not installed. Install it with: brew install ffmpeg")
                }
            case "s", "sites":
                listSupportedSites()
            case "v", "version":
                printVersion()
            case "h", "help", "--help", "-h":
                printUsage(ffmpegAvailable: ffmpegAvailable)
            case "--ffmpeg":
                checkFFmpeg()
            default:
                // Try to interpret as URL
                if command.hasPrefix("http") {
                    await handleDownload(arguments: [command], downloader: downloader)
                } else {
                    printError("Unknown command: '" + command + "'")
                    printUsage(ffmpegAvailable: ffmpegAvailable)
                }
            }
        } catch let error as DownloadError {
            handleDownloadError(error)
        } catch let error as FFmpegError {
            handleFFmpegError(error)
        } catch {
            printError("Error: " + error.localizedDescription)
            exit(1)
        }
    }
    
    // MARK: - Command Handlers
    
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
            case "-n", "--name":
                i += 1
                if i < arguments.count {
                    options.filename = arguments[i]
                }
            case "-f", "--format":
                i += 1
                if i < arguments.count {
                    options.format = arguments[i]
                }
            case "-a", "--audio":
                options.audioOnly = true
            case "-y", "--yes", "--overwrite":
                options.overwrite = true
            case "--no-ffmpeg":
                options.useFFmpeg = false
            default:
                if arg.hasPrefix("-") {
                    printError("Unknown option: '" + arg + "'")
                    printUsage(ffmpegAvailable: true)
                    return
                }
                urls.append(arg)
            }
            
            i += 1
        }
        
        guard !urls.isEmpty else {
            printError("No URL provided")
            printUsage(ffmpegAvailable: true)
            return
        }
        
        for url in urls {
            await downloadVideo(url: url, options: options, downloader: downloader)
        }
    }
    
    static func handleGet(arguments: [String], downloader: VideoDownloader) async {
        // Get is a simpler version of download with default options
        var urls: [String] = []
        
        for arg in arguments {
            if !arg.hasPrefix("-") {
                urls.append(arg)
            }
        }
        
        guard !urls.isEmpty else {
            printError("No URL provided")
            return
        }
        
        for url in urls {
            let options = DownloadOptions()
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
            case "-j", "--json":
                options.jsonOutput = true
            case "-s", "--short":
                options.shortOutput = true
            default:
                if !arg.hasPrefix("-") {
                    urls.append(arg)
                }
            }
            
            i += 1
        }
        
        guard !urls.isEmpty else {
            printError("No URL provided")
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
            case "-a", "--audio":
                options.audioOnly = true
            case "-f", "--format":
                i += 1
                if i < arguments.count {
                    options.format = arguments[i]
                }
            case "-y", "--yes", "--overwrite":
                options.overwrite = true
            default:
                if !arg.hasPrefix("-") {
                    urls.append(arg)
                }
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
            return
        }
        
        print("\u{001B}[1mDownloading " + String(urls.count) + " videos...\u{001B}[0m")
        print()
        
        for (index, url) in urls.enumerated() {
            print("[" + String(index + 1) + "/" + String(urls.count) + "] " + url)
            await downloadVideo(url: url, options: options, downloader: downloader, showIndex: false)
            print()
        }
        
        printSuccess("Batch download completed!")
    }
    
    static func handleConvert(arguments: [String]) async {
        guard arguments.count >= 2 else {
            printError("Usage: macdownloader convert <input> <output> [options]")
            return
        }
        
        let inputPath = arguments[0]
        let outputPath = URL(fileURLWithPath: arguments[1])
        
        var options = ConversionOptions()
        var i = 2
        
        while i < arguments.count {
            let arg = arguments[i]
            
            switch arg {
            case "-f", "--format":
                i += 1
                if i < arguments.count {
                    if let format = VideoFormat.fromFileExtension(arguments[i]) {
                        options.format = format
                    } else {
                        options.format = VideoFormat(rawValue: arguments[i].lowercased())
                    }
                }
            case "-q", "--quality":
                i += 1
                if i < arguments.count {
                    options.videoQuality = VideoQuality.fromString(arguments[i])
                }
            case "-a", "--audio":
                options = .audioOnly()
            case "-v", "--video":
                options = .videoOnly()
            case "-s", "--start":
                i += 1
                if i < arguments.count, let time = Double(arguments[i]) {
                    options.startTime = time
                }
            case "-t", "--duration":
                i += 1
                if i < arguments.count, let duration = Double(arguments[i]) {
                    options.duration = duration
                }
            case "-r", "--resolution":
                i += 1
                if i < arguments.count {
                    options.resolution = arguments[i]
                }
            case "-y", "--yes", "--overwrite":
                options.overwrite = true
            default:
                if arg.hasPrefix("-") {
                    printError("Unknown option: '" + arg + "'")
                    return
                }
            }
            
            i += 1
        }
        
        do {
            try FFmpegWrapper.convert(inputPath, to: outputPath, options: options)
            printSuccess("Converted: " + inputPath + " -> " + outputPath.path)
        } catch {
            printError("Conversion failed: " + error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    static func downloadVideo(url: String, options: DownloadOptions, downloader: VideoDownloader, showIndex: Bool = true) async {
        do {
            // Check if FFmpeg is needed
            if options.useFFmpeg && options.format != nil {
                try await downloader.checkFFmpeg()
            }
            
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
            let filename = options.filename ?? sanitizeFilename(videoInfo.title)
            let extension = options.format ?? videoInfo.format
            let sanitizedFilename = filename + "." + extension
            let outputURL = outputPath.appendingPathComponent(sanitizedFilename)
            
            // Check if file exists
            if !options.overwrite && FileManager.default.fileExists(atPath: outputURL.path) {
                printError("File already exists: " + outputURL.path)
                print("Use -y or --overwrite to replace existing files")
                return
            }
            
            // Print video info
            if showIndex {
                printVideoInfo(videoInfo, short: true)
            }
            
            // Download
            print("Downloading to: " + outputURL.path)
            
            let finalURL = try await downloader.downloadVideo(
                from: url,
                quality: options.quality,
                outputPath: outputURL,
                convertTo: options.format,
                audioOnly: options.audioOnly
            )
            
            printSuccess("Downloaded: " + finalURL.path)
            
        } catch let error as DownloadError {
            handleDownloadError(error)
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
            } else if options.shortOutput {
                for info in filteredInfos {
                    printShortInfo(info)
                }
            } else {
                print("\u{001B}[1mVideo Information\u{001B}[0m")
                print("=" * 60)
                for (index, videoInfo) in filteredInfos.enumerated() {
                    if index > 0 {
                        print("-" * 60)
                    }
                    printVideoInfo(videoInfo, detailed: true)
                }
            }
            
        } catch let error as DownloadError {
            handleDownloadError(error)
        } catch {
            printError("Error: " + error.localizedDescription)
        }
    }
    
    // MARK: - Output Methods
    
    static func printUsage(ffmpegAvailable: Bool) {
        let executableName = (CommandLine.arguments.first ?? "macdownloader").split(separator: "/").last ?? "macdownloader"
        
        print("""
        \u{001B}[1;36m⬇️  MacDownloader\u{001B}[0m - A powerful video downloader for macOS
        \u{001B}[33mVersion 1.0.0\u{001B}[0m | \u{001B}[32mOpen Source\u{001B}[0m | \u{001B}[34mhttps://github.com/MrFlappy0/MacDownloader\u{001B}[0m
        
        \u{001B}[1mUSAGE:\u{001B}[0m
          \u{001B}[36m(executableName)\u{001B}[0m [\u{001B}[33mcommand\u{001B}[0m] [\u{001B}[35moptions\u{001B}[0m] \u{001B}[34mURL\u{001B}[0m]
          \u{001B}[36m(executableName)\u{001B}[0m \u{001B}[34mURL\u{001B}[0m  (shortcut: download URL directly)
        
        \u{001B}[1mCOMMANDS:\u{001B}[0m
          \u{001B}[32md, download\u{001B}[0m     Download a video
          \u{001B}[32mg, get\u{001B}[0m        Download with default options
          \u{001B}[32mi, info\u{001B}[0m       Get video information
          \u{001B}[32mb, batch\u{001B}[0m      Download multiple videos from a file
          \u{001B}[32ml, list\u{001B}[0m       List supported sites
          \u{001B}[32mc, convert\u{001B}[0m     Convert a video (requires FFmpeg)
          \u{001B}[32mv, version\u{001B}[0m    Show version information
          \u{001B}[32mh, help\u{001B}[0m       Show this help message
        
        \u{001B}[1mOPTIONS:\u{001B}[0m
          \u{001B}[33mDownload/Convert Options:\u{001B}[0m
            -q, --quality <q>    Video quality (1080p, 720p, 480p, etc.)\u{001B}[0m
            -o, --output <path>  Output directory\u{001B}[0m
            -n, --name <name>   Output filename (without extension)\u{001B}[0m
            -f, --format <fmt>  Output format (mp4, webm, mkv, mp3, etc.)\u{001B}[0m
            -a, --audio        Extract audio only\u{001B}[0m
            -y, --overwrite    Overwrite existing files\u{001B}[0m
            --no-ffmpeg       Disable FFmpeg conversion\u{001B}[0m
          
          \u{001B}[33mInfo Options:\u{001B}[0m
            -q, --quality <q>    Filter by quality\u{001B}[0m
            -j, --json         Output in JSON format\u{001B}[0m
            -s, --short        Short output format\u{001B}[0m
          
          \u{001B}[33mBatch Options:\u{001B}[0m
            -f, --file <path>   Path to file containing URLs\u{001B}[0m
        
        \u{001B}[1mEXAMPLES:\u{001B}[0m
          \u{001B}[36m(executableName) d https://youtube.com/watch?v=dQw4w9WgXcQ\u{001B}[0m
          \u{001B}[36m(executableName) d -q 1080p https://youtube.com/watch?v=dQw4w9WgXcQ\u{001B}[0m
          \u{001B}[36m(executableName) d -o ~/Downloads/Videos https://vimeo.com/123456789\u{001B}[0m
          \u{001B}[36m(executableName) d -a -f mp3 https://youtube.com/watch?v=dQw4w9WgXcQ\u{001B}[0m
          \u{001B}[36m(executableName) i https://twitter.com/user/status/123456789\u{001B}[0m
          \u{001B}[36m(executableName) b -f urls.txt -o ~/Downloads/Videos\u{001B}[0m
          \u{001B}[36m(executableName) c input.mp4 output.mkv\u{001B}[0m
          \u{001B}[36m(executableName) --ffmpeg\u{001B}[0m  (check FFmpeg installation)
        
        \u{001B}[1mFFmpeg Status:\u{001B}[0m \u{001B}[" + (ffmpegAvailable ? "32m✓ Installed" : "31m✗ Not installed") + "\u{001B}[0m"
        
        \u{001B}[1mSUPPORTED SITES:\u{001B}[0m \u{001B}[36m" + String(SupportedSite.allCases.filter { $0 != .generic }.count) + "+ sites\u{001B}[0m
        
        \u{001B}[33mTip: Use 'macdownloader list' to see all supported sites\u{001B}[0m
        """)
    }
    
    static func listSupportedSites() {
        print("\u{001B}[1;36mSupported Sites\u{001B}[0m (\u{001B}[32m" + String(SupportedSite.allCases.filter { $0 != .generic }.count) + "+ sites\u{001B}[0m)")
        print("=" * 60)
        
        let sites = SupportedSite.allCases.filter { $0 != .generic }
        
        for (index, site) in sites.enumerated() {
            let symbol = site.supportsMultipleQualities ? "✓" : "○"
            let formats = site.supportedFormats.joined(separator: ", ")
            let count = index + 1
            
            print(String(format: "  %2d. ", count) + "\u{001B}[36m" + site.rawValue.padding(toLength: 15) + "\u{001B}[0m" + 
                  " [" + symbol + "] " + 
                  "\u{001B}[33m" + formats + "\u{001B}[0m")
        }
        
        print()
        print("\u{001B}[33mLegend: ✓ = Multiple qualities, ○ = Single quality\u{001B}[0m")
    }
    
    static func printVersion() {
        print("\u{001B}[1;36mMacDownloader\u{001B}[0m")
        print("\u{001B}[33mVersion:\u{001B}[0m 1.0.0")
        print("\u{001B}[33mSwift:\u{001B}[0m ", terminator: "")
        
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["swift", "--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        process.launch()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print(output.components(separatedBy: .newlines).first ?? "Unknown")
            }
        }
        
        if let ffmpegVersion = FFmpegWrapper.getVersion() {
            print("\u{001B}[33mFFmpeg:\u{001B}[0m ", terminator: "")
            print(ffmpegVersion)
        }
        
        print()
        print("\u{001B}[33mGitHub:\u{001B}[0m https://github.com/MrFlappy0/MacDownloader")
    }
    
    static func checkFFmpeg() {
        do {
            try FFmpegWrapper.checkFFmpeg()
            if let version = FFmpegWrapper.getVersion() {
                printSuccess("FFmpeg is installed (v" + version + ")")
            } else {
                printSuccess("FFmpeg is installed")
            }
        } catch {
            printError("FFmpeg is not installed")
            print()
            print(FFmpegWrapper.installFFmpeg())
        }
    }
    
    // MARK: - Info Output
    
    static func printVideoInfo(_ videoInfo: VideoInfo, short: Bool = false, detailed: Bool = false) {
        if short {
            print("\u{001B}[36m" + videoInfo.title + "\u{001B}[0m")
            if let quality = videoInfo.quality {
                print("  Quality: \u{001B}[33m" + quality + "\u{001B}[0m")
            }
            if let duration = videoInfo.duration {
                print("  Duration: \u{001B}[33m" + formatDuration(duration) + "\u{001B}[0m")
            }
            print("  Format: \u{001B}[33m" + videoInfo.format + "\u{001B}[0m")
            print("  URL: \u{001B}[34m" + videoInfo.url.absoluteString + "\u{001B}[0m")
        } else if detailed {
            print("\u{001B}[1mTitle:\u{001B}[0m " + videoInfo.title)
            print("\u{001B}[1mURL:\u{001B}[0m " + videoInfo.url.absoluteString)
            
            if let quality = videoInfo.quality {
                print("\u{001B}[1mQuality:\u{001B}[0m " + quality)
            }
            
            if !videoInfo.availableQualities.isEmpty {
                print("\u{001B}[1mAvailable Qualities:\u{001B}[0m " + videoInfo.availableQualities.joined(separator: ", "))
            }
            
            if let duration = videoInfo.duration {
                print("\u{001B}[1mDuration:\u{001B}[0m " + formatDuration(duration))
            }
            
            print("\u{001B}[1mFormat:\u{001B}[0m " + videoInfo.format)
            
            if !videoInfo.availableFormats.isEmpty {
                print("\u{001B}[1mAvailable Formats:\u{001B}[0m " + videoInfo.availableFormats.joined(separator: ", "))
            }
            
            if let thumbnailURL = videoInfo.thumbnailURL {
                print("\u{001B}[1mThumbnail:\u{001B}[0m " + thumbnailURL.absoluteString)
            }
            
            if let site = SupportedSite.site(from: videoInfo.url.absoluteString) {
                print("\u{001B}[1mSite:\u{001B}[0m " + site.rawValue)
            }
        } else {
            print("\u{001B}[36m" + videoInfo.title + "\u{001B}[0m")
            print("  URL: \u{001B}[34m" + videoInfo.url.absoluteString + "\u{001B}[0m")
            
            if let quality = videoInfo.quality {
                print("  Quality: \u{001B}[33m" + quality + "\u{001B}[0m")
            }
            
            if let duration = videoInfo.duration {
                print("  Duration: \u{001B}[33m" + formatDuration(duration) + "\u{001B}[0m")
            }
            
            print("  Format: \u{001B}[33m" + videoInfo.format + "\u{001B}[0m")
        }
    }
    
    static func printShortInfo(_ videoInfo: VideoInfo) {
        var line = "\u{001B}[36m" + (videoInfo.title.prefix(40) + (videoInfo.title.count > 40 ? "..." : "")) + "\u{001B}[0m"
        
        if let duration = videoInfo.duration {
            line += " (" + formatDuration(duration) + ")"
        }
        
        if let quality = videoInfo.quality {
            line += " [" + quality + "]"
        }
        
        print(line)
        print("  " + videoInfo.url.absoluteString)
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
            let availableQualities: [String]
            let availableFormats: [String]
            let isAudioOnly: Bool
        }
        
        let jsonInfos = videoInfos.map { VideoInfoJSON(
            title: $0.title,
            url: $0.url.absoluteString,
            thumbnailURL: $0.thumbnailURL?.absoluteString,
            duration: $0.duration,
            quality: $0.quality,
            format: $0.format,
            availableQualities: $0.availableQualities,
            availableFormats: $0.availableFormats,
            isAudioOnly: $0.isAudioOnly
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
    
    // MARK: - Error Handling
    
    static func handleDownloadError(_ error: DownloadError) {
        switch error {
        case .invalidURL:
            printError("Invalid URL")
        case .noVideoFound:
            printError("No video found at this URL")
        case .unsupportedSite:
            printError("This site is not supported")
        case .extractionFailed(let message):
            printError("Failed to extract video: " + message)
        case .downloadFailed(let underlyingError):
            printError("Download failed: " + underlyingError.localizedDescription)
        case .fileWriteFailed(let underlyingError):
            printError("Failed to save file: " + underlyingError.localizedDescription)
        case .ffmpegError(let ffmpegError):
            handleFFmpegError(ffmpegError)
        case .conversionFailed(let message):
            printError("Conversion failed: " + message)
        case .ffmpegNotAvailable:
            printError("FFmpeg is not available. Install it with: brew install ffmpeg")
        }
    }
    
    static func handleFFmpegError(_ error: FFmpegError) {
        switch error {
        case .ffmpegNotInstalled:
            printError("FFmpeg is not installed")
            print()
            print(FFmpegWrapper.installFFmpeg())
        case .conversionFailed(let message):
            printError("FFmpeg conversion failed: " + message)
        case .invalidInputFile:
            printError("Invalid input file")
        case .invalidOutputFormat:
            printError("Invalid output format")
        case .unsupportedCodec:
            printError("Unsupported codec")
        case .fileNotFound(let path):
            printError("File not found: " + path)
        case .permissionDenied(let path):
            printError("Permission denied: " + path)
        }
    }
    
    // MARK: - Utility Methods
    
    static func printError(_ message: String) {
        fputs("\u{001B}[31m✗ " + message + "\u{001B}[0m\n", stderr)
    }
    
    static func printSuccess(_ message: String) {
        fputs("\u{001B}[32m✓ " + message + "\u{001B}[0m\n", stdout)
    }
    
    static func printWarning(_ message: String) {
        fputs("\u{001B}[33m⚠ " + message + "\u{001B}[0m\n", stdout)
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
}

// MARK: - Data Structures

struct DownloadOptions {
    var quality: String?
    var outputPath: URL?
    var filename: String?
    var format: String?
    var audioOnly: Bool = false
    var overwrite: Bool = false
    var useFFmpeg: Bool = true
}

struct InfoOptions {
    var qualityFilter: String?
    var jsonOutput: Bool = false
    var shortOutput: Bool = false
}

// MARK: - Helper Extensions

fileprivate extension String {
    static func * (lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
