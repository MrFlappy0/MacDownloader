import Foundation

public enum FFmpegError: Error {
    case ffmpegNotInstalled
    case conversionFailed(String)
    case invalidInputFile
    case invalidOutputFormat
    case unsupportedCodec
    case fileNotFound(String)
    case permissionDenied(String)
}

public struct FFmpegOptions {
    public var format: String?
    public var videoCodec: String?
    public var audioCodec: String?
    public var bitrate: String?
    public var framerate: Int?
    public var resolution: String?
    public var startTime: TimeInterval?
    public var duration: TimeInterval?
    public var overwrite: Bool = false
    public var optimize: Bool = true
    public var threads: Int?
    
    public init() {}
    
    public static func mp4HighQuality() -> FFmpegOptions {
        var options = FFmpegOptions()
        options.format = "mp4"
        options.videoCodec = "libx264"
        options.audioCodec = "aac"
        options.bitrate = "8M"
        options.threads = 4
        options.optimize = true
        return options
    }
    
    public static func mp4MediumQuality() -> FFmpegOptions {
        var options = FFmpegOptions()
        options.format = "mp4"
        options.videoCodec = "libx264"
        options.audioCodec = "aac"
        options.bitrate = "4M"
        return options
    }
    
    public static func mp4LowQuality() -> FFmpegOptions {
        var options = FFmpegOptions()
        options.format = "mp4"
        options.videoCodec = "libx264"
        options.audioCodec = "aac"
        options.bitrate = "2M"
        options.resolution = "640x480"
        return options
    }
    
    public static func mp3AudioOnly() -> FFmpegOptions {
        var options = FFmpegOptions()
        options.format = "mp3"
        options.audioCodec = "libmp3lame"
        options.bitrate = "320k"
        return options
    }
    
    public static func webm() -> FFmpegOptions {
        var options = FFmpegOptions()
        options.format = "webm"
        options.videoCodec = "libvpx-vp9"
        options.audioCodec = "libopus"
        options.bitrate = "5M"
        return options
    }
    
    public static func mkv() -> FFmpegOptions {
        var options = FFmpegOptions()
        options.format = "mkv"
        options.videoCodec = "copy"
        options.audioCodec = "copy"
        return options
    }
}

public struct FFmpegInfo {
    public let duration: TimeInterval?
    public let width: Int?
    public let height: Int?
    public let bitrate: Int?
    public let videoCodec: String?
    public let audioCodec: String?
    public let frameRate: Double?
    public let fileSize: Int64?
    
    public init(duration: TimeInterval? = nil, width: Int? = nil, height: Int? = nil, 
                bitrate: Int? = nil, videoCodec: String? = nil, audioCodec: String? = nil,
                frameRate: Double? = nil, fileSize: Int64? = nil) {
        self.duration = duration
        self.width = width
        self.height = height
        self.bitrate = bitrate
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.frameRate = frameRate
        self.fileSize = fileSize
    }
}

public class FFmpegWrapper {
    private static let ffmpegPath: String = {
        let paths = [
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg",
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/opt/ffmpeg/bin/ffmpeg"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Check PATH
        let whichFFmpeg = ProcessInfo.processInfo.environment["PATH"]?.components(separatedBy: ":")
            .map { "$0/ffmpeg" }
            .first(where: { FileManager.default.fileExists(atPath: $0) })
        
        return whichFFmpeg ?? "ffmpeg"
    }()
    
    public static var isFFmpegAvailable: Bool {
        return FileManager.default.fileExists(atPath: ffmpegPath)
    }
    
    public static func checkFFmpeg() throws {
        if !isFFmpegAvailable {
            throw FFmpegError.ffmpegNotInstalled
        }
        
        // Verify ffmpeg works
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["ffmpeg", "-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.launch()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw FFmpegError.ffmpegNotInstalled
        }
    }
    
    public static func installFFmpeg() -> String {
        #if os(macOS)
        return """
        To install FFmpeg on macOS, use Homebrew:
        
        1. Install Homebrew (if not already installed):
           /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        2. Install FFmpeg:
           brew install ffmpeg
        
        3. Verify installation:
           ffmpeg -version
        
        Alternatively, you can download a pre-built binary from:
        https://evermeet.cx/ffmpeg/
        """
        #else
        return "FFmpeg installation is not supported on this platform."
        #endif
    }
    
    public static func getVersion() -> String? {
        guard isFFmpegAvailable else { return nil }
        
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["ffmpeg", "-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        process.launch()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines).first?.components(separatedBy: " ").last
            }
        }
        
        return nil
    }
    
    public static func getFileInfo(_ filePath: String) throws -> FFmpegInfo {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw FFmpegError.fileNotFound(filePath)
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", filePath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        process.launch()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw FFmpegError.conversionFailed("Failed to get file info")
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: data, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8) else {
            throw FFmpegError.conversionFailed("Invalid ffprobe output")
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let format = json["format"] as? [String: Any] {
                
                var info = FFmpegInfo()
                
                // Duration
                if let durationString = format["duration"] as? String,
                   let duration = Double(durationString) {
                    info.duration = duration
                }
                
                // Bitrate
                if let bitrateString = format["bit_rate"] as? String,
                   let bitrate = Int(bitrateString) {
                    info.bitrate = bitrate
                }
                
                // File size
                if let sizeString = format["size"] as? String,
                   let size = Int64(sizeString) {
                    info.fileSize = size
                }
                
                // Stream info
                if let streams = json["streams"] as? [[String: Any]] {
                    for stream in streams {
                        if let codecType = stream["codec_type"] as? String {
                            if codecType == "video" {
                                if let width = stream["width"] as? Int {
                                    info.width = width
                                }
                                if let height = stream["height"] as? Int {
                                    info.height = height
                                }
                                if let codec = stream["codec_name"] as? String {
                                    info.videoCodec = codec
                                }
                                if let frameRateString = stream["r_frame_rate"] as? String {
                                    let components = frameRateString.components(separatedBy: "/")
                                    if components.count == 2,
                                       let numerator = Double(components[0]),
                                       let denominator = Double(components[1]),
                                       denominator != 0 {
                                        info.frameRate = numerator! / denominator!
                                    }
                                }
                            } else if codecType == "audio" {
                                if let codec = stream["codec_name"] as? String {
                                    info.audioCodec = codec
                                }
                            }
                        }
                    }
                }
                
                return info
            }
        } catch {
            throw FFmpegError.conversionFailed(error.localizedDescription)
        }
        
        throw FFmpegError.conversionFailed("Unknown error")
    }
    
    public static func convert(_ inputPath: String, to outputPath: URL, options: FFmpegOptions = FFmpegOptions()) throws {
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw FFmpegError.invalidInputFile
        }
        
        let outputDirectory = outputPath.deletingLastPathComponent()
        let fileManager = FileManager.default
        
        // Create output directory if it doesn't exist
        if !fileManager.fileExists(atPath: outputDirectory.path) {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }
        
        // Remove output file if it exists and overwrite is true
        if fileManager.fileExists(atPath: outputPath.path) && options.overwrite {
            try fileManager.removeItem(at: outputPath)
        } else if fileManager.fileExists(atPath: outputPath.path) {
            throw FFmpegError.fileNotFound("Output file already exists. Use overwrite option.")
        }
        
        // Build command
        var arguments = ["ffmpeg"]
        
        // Input
        arguments.append("-i")
        arguments.append(inputPath)
        
        // Video codec
        if let videoCodec = options.videoCodec {
            arguments.append("-c:v")
            arguments.append(videoCodec)
        }
        
        // Audio codec
        if let audioCodec = options.audioCodec {
            arguments.append("-c:a")
            arguments.append(audioCodec)
        }
        
        // Bitrate
        if let bitrate = options.bitrate {
            arguments.append("-b:v")
            arguments.append(bitrate)
        }
        
        // Framerate
        if let framerate = options.framerate {
            arguments.append("-r")
            arguments.append(String(framerate))
        }
        
        // Resolution
        if let resolution = options.resolution {
            arguments.append("-s")
            arguments.append(resolution)
        }
        
        // Start time
        if let startTime = options.startTime {
            arguments.append("-ss")
            arguments.append(String(format: "%.2f", startTime))
        }
        
        // Duration
        if let duration = options.duration {
            arguments.append("-t")
            arguments.append(String(format: "%.2f", duration))
        }
        
        // Threads
        if let threads = options.threads {
            arguments.append("-threads")
            arguments.append(String(threads))
        }
        
        // Optimize
        if options.optimize {
            arguments.append("-movflags")
            arguments.append("+faststart")
        }
        
        // Overwrite
        if options.overwrite {
            arguments.append("-y")
        } else {
            arguments.append("-n")
        }
        
        // Output
        arguments.append(outputPath.path)
        
        // Execute
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        process.launch()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw FFmpegError.conversionFailed(errorString)
        }
    }
    
    public static func extractAudio(_ inputPath: String, to outputPath: URL, options: FFmpegOptions = .mp3AudioOnly()) throws {
        var audioOptions = options
        audioOptions.format = "mp3"
        audioOptions.audioCodec = "libmp3lame"
        audioOptions.videoCodec = nil
        
        try convert(inputPath, to: outputPath, options: audioOptions)
    }
    
    public static func convertToMP4(_ inputPath: String, to outputPath: URL, quality: String = "high") throws {
        let options: FFmpegOptions
        
        switch quality.lowercased() {
        case "low":
            options = .mp4LowQuality()
        case "medium":
            options = .mp4MediumQuality()
        default:
            options = .mp4HighQuality()
        }
        
        try convert(inputPath, to: outputPath, options: options)
    }
    
    public static func trimVideo(_ inputPath: String, to outputPath: URL, startTime: TimeInterval, duration: TimeInterval) throws {
        var options = FFmpegOptions()
        options.startTime = startTime
        options.duration = duration
        options.overwrite = true
        options.optimize = true
        
        try convert(inputPath, to: outputPath, options: options)
    }
    
    public static func changeResolution(_ inputPath: String, to outputPath: URL, resolution: String) throws {
        var options = FFmpegOptions()
        options.resolution = resolution
        options.videoCodec = "libx264"
        options.audioCodec = "aac"
        options.overwrite = true
        options.optimize = true
        
        try convert(inputPath, to: outputPath, options: options)
    }
    
    public static func extractThumbnail(_ inputPath: String, to outputPath: URL, time: TimeInterval = 0) throws {
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw FFmpegError.invalidInputFile
        }
        
        let outputDirectory = outputPath.deletingLastPathComponent()
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: outputDirectory.path) {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }
        
        if fileManager.fileExists(atPath: outputPath.path) {
            try fileManager.removeItem(at: outputPath)
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = [
            "ffmpeg",
            "-i", inputPath,
            "-ss", String(format: "%.2f", time),
            "-vframes", "1",
            "-q:v", "2",
            "-y",
            outputPath.path
        ]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        process.launch()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw FFmpegError.conversionFailed(errorString)
        }
    }
}
