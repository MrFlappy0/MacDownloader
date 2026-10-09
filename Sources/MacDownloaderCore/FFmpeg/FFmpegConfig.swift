import Foundation

public enum VideoFormat: String, CaseIterable {
    case mp4 = "mp4"
    case webm = "webm"
    case mkv = "mkv"
    case mov = "mov"
    case avi = "avi"
    case flv = "flv"
    case wmv = "wmv"
    case mpeg = "mpeg"
    case mp3 = "mp3"
    case aac = "aac"
    case wav = "wav"
    case ogg = "ogg"
    case m4a = "m4a"
    
    public var isAudioOnly: Bool {
        return self == .mp3 || self == .aac || self == .wav || self == .ogg || self == .m4a
    }
    
    public var isVideo: Bool {
        return !isAudioOnly
    }
    
    public var extension: String {
        return self.rawValue
    }
    
    public static func fromFileExtension(_ ext: String) -> VideoFormat? {
        let lowercased = ext.lowercased().replacingOccurrences(of: ".", with: "")
        return VideoFormat(rawValue: lowercased)
    }
}

public enum VideoQuality: String, CaseIterable {
    case lowest = "lowest"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case highest = "highest"
    case auto = "auto"
    
    public var resolution: String? {
        switch self {
        case .lowest: return "240p"
        case .low: return "480p"
        case .medium: return "720p"
        case .high: return "1080p"
        case .highest: return "4K"
        case .auto: return nil
        }
    }
    
    public var bitrate: String? {
        switch self {
        case .lowest: return "500k"
        case .low: return "2M"
        case .medium: return "5M"
        case .high: return "8M"
        case .highest: return "20M"
        case .auto: return nil
        }
    }
    
    public static func fromString(_ string: String) -> VideoQuality {
        let lowercased = string.lowercased()
        
        if lowercased.contains("4k") || lowercased.contains("ultra") || lowercased.contains("max") {
            return .highest
        } else if lowercased.contains("1080") || lowercased.contains("full") || lowercased.contains("hd") {
            return .high
        } else if lowercased.contains("720") || lowercased.contains("high") {
            return .medium
        } else if lowercased.contains("480") || lowercased.contains("medium") {
            return .medium
        } else if lowercased.contains("360") || lowercased.contains("240") || lowercased.contains("low") {
            return .low
        } else if lowercased.contains("144") || lowercased.contains("lowest") {
            return .lowest
        }
        
        return .auto
    }
}

public enum AudioFormat: String, CaseIterable {
    case mp3 = "mp3"
    case aac = "aac"
    case wav = "wav"
    case ogg = "ogg"
    case m4a = "m4a"
    case flac = "flac"
    
    public var bitrate: String {
        switch self {
        case .mp3: return "320k"
        case .aac: return "256k"
        case .wav: return "1411k"  // CD quality
        case .ogg: return "256k"
        case .m4a: return "256k"
        case .flac: return "1000k"  // Lossless
        }
    }
}

public struct ConversionOptions {
    public var format: VideoFormat?
    public var videoQuality: VideoQuality?
    public var audioFormat: AudioFormat?
    public var startTime: TimeInterval?
    public var duration: TimeInterval?
    public var resolution: String?
    public var audioOnly: Bool = false
    public var videoOnly: Bool = false
    public var overwrite: Bool = false
    public var optimize: Bool = true
    
    public init() {}
    
    public static func audioOnly(_ format: AudioFormat = .mp3) -> ConversionOptions {
        var options = ConversionOptions()
        options.audioOnly = true
        options.audioFormat = format
        return options
    }
    
    public static func videoOnly(_ quality: VideoQuality = .high) -> ConversionOptions {
        var options = ConversionOptions()
        options.videoOnly = true
        options.videoQuality = quality
        return options
    }
}

public class FFmpegConfig {
    public static let shared = FFmpegConfig()
    
    private init() {}
    
    public var ffmpegPath: String = FFmpegWrapper.ffmpegPath
    public var ffprobePath: String = {
        let basePath = FFmpegWrapper.ffmpegPath.replacingOccurrences(of: "ffmpeg", with: "ffprobe")
        if FileManager.default.fileExists(atPath: basePath) {
            return basePath
        }
        return "ffprobe"
    }()
    
    public var defaultVideoFormat: VideoFormat = .mp4
    public var defaultAudioFormat: AudioFormat = .mp3
    public var defaultVideoQuality: VideoQuality = .high
    public var maxThreads: Int = 4
    public var enableHardwareAcceleration: Bool = true
    
    public func getFFmpegArguments(for options: ConversionOptions, inputPath: String, outputPath: String) -> [String] {
        var arguments = ["ffmpeg"]
        
        // Hardware acceleration
        if enableHardwareAcceleration {
            arguments.append("-hwaccel")
            arguments.append("auto")
        }
        
        // Input
        arguments.append("-i")
        arguments.append(inputPath)
        
        // Audio only
        if options.audioOnly {
            arguments.append("-vn")  // No video
            if let audioFormat = options.audioFormat {
                arguments.append("-c:a")
                arguments.append(audioFormat == .wav ? "pcm_s16le" : "lib" + audioFormat.rawValue)
                arguments.append("-b:a")
                arguments.append(audioFormat.bitrate)
            }
        }
        
        // Video only
        if options.videoOnly {
            arguments.append("-an")  // No audio
        }
        
        // Video quality/format
        if !options.audioOnly {
            if let videoQuality = options.videoQuality {
                if let resolution = videoQuality.resolution {
                    arguments.append("-s")
                    arguments.append(resolution)
                }
                if let bitrate = videoQuality.bitrate {
                    arguments.append("-b:v")
                    arguments.append(bitrate)
                }
            }
            
            if let resolution = options.resolution {
                arguments.append("-s")
                arguments.append(resolution)
            }
        }
        
        // Time options
        if let startTime = options.startTime {
            arguments.append("-ss")
            arguments.append(String(format: "%.2f", startTime))
        }
        
        if let duration = options.duration {
            arguments.append("-t")
            arguments.append(String(format: "%.2f", duration))
        }
        
        // Output format
        if let format = options.format {
            arguments.append("-f")
            arguments.append(format.rawValue)
        }
        
        // Optimize
        if optimize {
            arguments.append("-movflags")
            arguments.append("+faststart")
        }
        
        // Threads
        arguments.append("-threads")
        arguments.append(String(maxThreads))
        
        // Overwrite
        if options.overwrite {
            arguments.append("-y")
        } else {
            arguments.append("-n")
        }
        
        // Output
        arguments.append(outputPath)
        
        return arguments
    }
}
