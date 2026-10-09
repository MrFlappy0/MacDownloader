import Foundation
import Alamofire
import SwiftSoup

// Import FFmpeg wrapper
public typealias FFmpeg = FFmpegWrapper

public enum DownloadError: Error {
    case invalidURL
    case downloadFailed(Error)
    case fileWriteFailed(Error)
    case noVideoFound
    case unsupportedSite
    case extractionFailed(String)
    case ffmpegError(FFmpegError)
    case conversionFailed(String)
    case ffmpegNotAvailable
}

public struct VideoInfo {
    public let title: String
    public let url: URL
    public let thumbnailURL: URL?
    public let duration: TimeInterval?
    public let quality: String?
    public let format: String
    public let availableQualities: [String]
    public let availableFormats: [String]
    public let isAudioOnly: Bool
    
    public init(title: String, url: URL, thumbnailURL: URL? = nil, duration: TimeInterval? = nil, 
                quality: String? = nil, format: String = "mp4",
                availableQualities: [String] = [], availableFormats: [String] = [],
                isAudioOnly: Bool = false) {
        self.title = title
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.quality = quality
        self.format = format
        self.availableQualities = availableQualities
        self.availableFormats = availableFormats
        self.isAudioOnly = isAudioOnly
    }
}

public struct DownloadProgress {
    public let bytesDownloaded: Int64
    public let totalBytes: Int64?
    public let progress: Double
    
    public init(bytesDownloaded: Int64, totalBytes: Int64? = nil) {
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.progress = totalBytes != nil ? Double(bytesDownloaded) / Double(totalBytes!) : 0
    }
}

public protocol DownloadDelegate: AnyObject {
    func downloadProgress(_ progress: DownloadProgress, for videoInfo: VideoInfo)
    func downloadCompleted(_ videoInfo: VideoInfo, at location: URL)
    func downloadFailed(_ error: DownloadError, for videoInfo: VideoInfo?)
}

public class VideoDownloader {
    private let session: Session
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    public weak var delegate: DownloadDelegate?
    
    public var ffmpegAvailable: Bool = false
    
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
        configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
        
        self.session = Session(configuration: configuration)
        
        // Check FFmpeg availability
        self.ffmpegAvailable = FFmpegWrapper.isFFmpegAvailable
    }
    
    public func checkFFmpeg() throws {
        try FFmpegWrapper.checkFFmpeg()
        self.ffmpegAvailable = true
    }
    
    public func extractVideoInfo(from urlString: String) async throws -> [VideoInfo] {
        guard let url = URL(string: urlString) else {
            throw DownloadError.invalidURL
        }
        
        let host = url.host?.lowercased() ?? ""
        
        switch host {
        case "youtube.com", "www.youtube.com", "youtu.be":
            return try await extractYouTubeVideoInfo(from: url)
        case "vimeo.com", "www.vimeo.com":
            return try await extractVimeoVideoInfo(from: url)
        case "dailymotion.com", "www.dailymotion.com":
            return try await extractDailymotionVideoInfo(from: url)
        case "facebook.com", "www.facebook.com", "fb.watch":
            return try await extractFacebookVideoInfo(from: url)
        case "instagram.com", "www.instagram.com":
            return try await extractInstagramVideoInfo(from: url)
        case "twitter.com", "www.twitter.com", "x.com":
            return try await extractTwitterVideoInfo(from: url)
        case "tiktok.com", "www.tiktok.com":
            return try await extractTikTokVideoInfo(from: url)
        case "reddit.com", "www.reddit.com":
            return try await extractRedditVideoInfo(from: url)
        case "twitch.tv", "www.twitch.tv":
            return try await extractTwitchVideoInfo(from: url)
        case "soundcloud.com", "www.soundcloud.com":
            return try await extractSoundCloudVideoInfo(from: url)
        default:
            // Try generic video extraction
            return try await extractGenericVideoInfo(from: url)
        }
    }
    
    public func downloadVideo(from urlString: String, quality: String? = nil, outputPath: URL? = nil, 
                               convertTo format: String? = nil, audioOnly: Bool = false) async throws -> URL {
        let videoInfos = try await extractVideoInfo(from: urlString)
        
        guard !videoInfos.isEmpty else {
            throw DownloadError.noVideoFound
        }
        
        // Filter by quality if specified
        let filteredInfos = quality != nil ? 
            videoInfos.filter { $0.quality?.lowercased() == quality?.lowercased() } : 
            videoInfos
        
        guard let videoInfo = filteredInfos.first else {
            throw DownloadError.noVideoFound
        }
        
        let outputURL = outputPath ?? getDefaultOutputURL(for: videoInfo)
        
        // If conversion is requested
        if let format = format, !format.isEmpty {
            let downloadedURL = try await downloadVideoInfo(videoInfo, to: outputURL)
            
            // Convert the file
            if audioOnly {
                let audioOutputURL = outputURL.deletingPathExtension().appendingPathExtension(format)
                try FFmpegWrapper.extractAudio(downloadedURL.path, to: audioOutputURL)
                
                // Remove the original video file
                try FileManager.default.removeItem(at: downloadedURL)
                
                return audioOutputURL
            } else {
                let convertedOutputURL = outputURL.deletingPathExtension().appendingPathExtension(format)
                try FFmpegWrapper.convertToMP4(downloadedURL.path, to: convertedOutputURL, quality: quality ?? "high")
                
                // Remove the original file
                try FileManager.default.removeItem(at: downloadedURL)
                
                return convertedOutputURL
            }
        }
        
        return try await downloadVideoInfo(videoInfo, to: outputURL)
    }
    
    private func downloadVideoInfo(_ videoInfo: VideoInfo, to outputURL: URL) async throws -> URL {
        // Create directory if it doesn't exist
        let directory = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Download the video
        let tempURL = directory.appendingPathComponent(".tmp_" + UUID().uuidString)
        
        do {
            let request = session.download(videoInfo.url, to: { _, response in
                let filename = self.sanitizeFilename(videoInfo.title) + "." + videoInfo.format
                let finalURL = directory.appendingPathComponent(filename)
                return (finalURL, [.removePreviousFile, .createIntermediateDirectories])
            })
            
            let downloadTask = request.downloadTask
            
            // Monitor progress
            request.downloadProgress { progress in
                let downloadProgress = DownloadProgress(
                    bytesDownloaded: progress.bytesDownloaded,
                    totalBytes: progress.totalBytes
                )
                DispatchQueue.main.async {
                    self.delegate?.downloadProgress(downloadProgress, for: videoInfo)
                }
            }
            
            let result = await request.serializingDownloadedURLResponse()
            
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.delegate?.downloadCompleted(videoInfo, at: response.first!)
                }
                return response.first!
            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.downloadFailed(.downloadFailed(error), for: videoInfo)
                }
                throw DownloadError.downloadFailed(error)
            }
        } catch {
            DispatchQueue.main.async {
                self.delegate?.downloadFailed(.downloadFailed(error), for: videoInfo)
            }
            throw DownloadError.downloadFailed(error)
        }
    }
    
    private func getDefaultOutputURL(for videoInfo: VideoInfo) -> URL {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let sanitizedTitle = sanitizeFilename(videoInfo.title)
        return downloadsURL.appendingPathComponent("MacDownloader").appendingPathComponent(sanitizedTitle + "." + videoInfo.format)
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:?*\"<>|\n\r\t")
        let sanitized = filename.components(separatedBy: invalidCharacters).joined(separator: "_")
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - YouTube Extraction

extension VideoDownloader {
    private func extractYouTubeVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        // Extract title
        let title = try doc.title() ?? "YouTube Video"
        
        // Extract video URL from script tags
        let scriptPattern = "url_encoded_fmt_stream_map|url_encoded_fmt_url_map|adaptive_fmts"
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        var qualities: [String] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("url=") || scriptText.contains("url_encoded") {
                // Parse JSON from script
                if let jsonRange = scriptText.range(of: "\\{.*\\}", options: .regularExpression) {
                    let jsonString = String(scriptText[jsonRange])
                    if let data = jsonString.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                if let streams = json["url_encoded_fmt_stream_map"] as? String {
                                    let decoded = streams.removingPercentEncoding ?? streams
                                    if let streamsData = decoded.data(using: .utf8) {
                                        if let streamsArray = try JSONSerialization.jsonObject(with: streamsData) as? [[String: Any]] {
                                            for stream in streamsArray {
                                                if let urlString = stream["url"] as? String,
                                                   let url = URL(string: urlString.removingPercentEncoding ?? urlString),
                                                   let quality = stream["quality"] as? String {
                                                    videoURLs.append(url)
                                                    qualities.append(quality)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } catch {
                            continue
                        }
                    }
                }
            }
        }
        
        // Fallback: Try to find video URL in meta tags
        if videoURLs.isEmpty {
            let metaTags = try doc.select("meta[property='og:video:url']")
            if let metaTag = metaTags.first, let videoURL = try? metaTag.attr("content") {
                if let url = URL(string: videoURL) {
                    videoURLs.append(url)
                    qualities.append("default")
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from YouTube")
        }
        
        // Extract thumbnail
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        // Extract duration
        var duration: TimeInterval? = nil
        if let durationString = try? doc.select("meta[itemprop='duration']").first?.attr("content") {
            duration = parseISO8601Duration(durationString)
        }
        
        return videoURLs.enumerated().map { index, url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                duration: duration,
                quality: qualities.count > index ? qualities[index] : nil,
                format: "mp4"
            )
        }
    }
    
    private func parseISO8601Duration(_ duration: String) -> TimeInterval? {
        var time: TimeInterval = 0
        let components = duration.components(separatedBy: CharacterSet(charactersIn: "PTHMS"))
        
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Double = 0
        
        for component in components {
            if component.hasPrefix("H") {
                hours = Int(component.replacingOccurrences(of: "H", with: "")) ?? 0
            } else if component.hasPrefix("M") {
                minutes = Int(component.replacingOccurrences(of: "M", with: "")) ?? 0
            } else if component.hasPrefix("S") {
                seconds = Double(component.replacingOccurrences(of: "S", with: "")) ?? 0
            }
        }
        
        time = Double(hours * 3600) + Double(minutes * 60) + seconds
        return time > 0 ? time : nil
    }
}

// MARK: - Vimeo Extraction

extension VideoDownloader {
    private func extractVimeoVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Vimeo Video"
        
        // Extract video URL from JSON data
        let scriptPattern = "window\\.vimeo\\.clip_page_config"
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        var qualities: [String] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("clip_page_config") {
                if let jsonRange = scriptText.range(of: "\\{.*\\}", options: .regularExpression) {
                    let jsonString = String(scriptText[jsonRange])
                    if let data = jsonString.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let request = json["request"] as? [String: Any],
                               let files = request["files"] as? [String: Any],
                               let progressive = files["progressive"] as? [[String: Any]] {
                                
                                for video in progressive {
                                    if let urlString = video["url"] as? String,
                                       let url = URL(string: urlString),
                                       let quality = video["quality"] as? String {
                                        videoURLs.append(url)
                                        qualities.append(quality)
                                    }
                                }
                            }
                        } catch {
                            continue
                        }
                    }
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from Vimeo")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.enumerated().map { index, url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: qualities.count > index ? qualities[index] : nil,
                format: "mp4"
            )
        }
    }
}

// MARK: - Dailymotion Extraction

extension VideoDownloader {
    private func extractDailymotionVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Dailymotion Video"
        
        // Extract video URL from JSON data
        let scripts = try doc.select("script[type='application/json']")
        
        var videoURLs: [URL] = []
        var qualities: [String] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if let data = scriptText.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let metadata = json["metadata"] as? [String: Any],
                       let qualitiesDict = metadata["qualities"] as? [String: [String: Any]] {
                        
                        for (quality, info) in qualitiesDict {
                            if let urlString = info["url"] as? String,
                               let url = URL(string: urlString) {
                                videoURLs.append(url)
                                qualities.append(quality)
                            }
                        }
                    }
                } catch {
                    continue
                }
            }
        }
        
        if videoURLs.isEmpty {
            // Fallback: Try to find video URL in meta tags
            if let videoURL = try? doc.select("meta[property='og:video:url']").first?.attr("content") {
                if let url = URL(string: videoURL) {
                    videoURLs.append(url)
                    qualities.append("default")
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from Dailymotion")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.enumerated().map { index, url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: qualities.count > index ? qualities[index] : nil,
                format: "mp4"
            )
        }
    }
}

// MARK: - Facebook Extraction

extension VideoDownloader {
    private func extractFacebookVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Facebook Video"
        
        // Extract video URL from JSON data
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("videoSrc") || scriptText.contains("sd_src") || scriptText.contains("hd_src") {
                // Try to find video URLs in script
                let patterns = ["videoSrc\\s*:\\s*[\"']([^\"']+)[\"']", 
                               "sd_src\\s*:\\s*[\"']([^\"']+)[\"']",
                               "hd_src\\s*:\\s*[\"']([^\"']+)[\"']"]
                
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let matches = regex.matches(in: scriptText, range: NSRange(scriptText.startIndex..., in: scriptText))
                        for match in matches {
                            if match.numberOfRanges > 1 {
                                let range = match.range(at: 1)
                                if let substringRange = Range(range, in: scriptText) {
                                    let urlString = String(scriptText[substringRange])
                                    if let url = URL(string: urlString) {
                                        videoURLs.append(url)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if videoURLs.isEmpty {
            // Fallback: Try to find video URL in meta tags
            if let videoURL = try? doc.select("meta[property='og:video:url']").first?.attr("content") {
                if let url = URL(string: videoURL) {
                    videoURLs.append(url)
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from Facebook")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.enumerated().map { index, url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: index == 0 ? "hd" : "sd",
                format: "mp4"
            )
        }
    }
}

// MARK: - Instagram Extraction

extension VideoDownloader {
    private func extractInstagramVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Instagram Video"
        
        // Extract video URL from JSON data
        let scripts = try doc.select("script[type='application/ld+json']")
        
        var videoURLs: [URL] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if let data = scriptText.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let videoObject = json["video"] as? [String: Any],
                       let urlString = videoObject["contentUrl"] as? String {
                        if let url = URL(string: urlString) {
                            videoURLs.append(url)
                        }
                    }
                } catch {
                    continue
                }
            }
        }
        
        if videoURLs.isEmpty {
            // Try to find video URL in meta tags
            if let videoURL = try? doc.select("meta[property='og:video:url']").first?.attr("content") {
                if let url = URL(string: videoURL) {
                    videoURLs.append(url)
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from Instagram")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.map { url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: "default",
                format: "mp4"
            )
        }
    }
}

// MARK: - Twitter/X Extraction

extension VideoDownloader {
    private func extractTwitterVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Twitter Video"
        
        // Extract video URL from JSON data
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        var qualities: [String] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("video") || scriptText.contains("variants") {
                // Try to find video URLs in script
                if let data = scriptText.data(using: .utf8) {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let variants = json["variants"] as? [[String: Any]] {
                                for variant in variants {
                                    if let urlString = variant["url"] as? String,
                                       let url = URL(string: urlString),
                                       let contentType = variant["contentType"] as? String {
                                        if contentType.contains("mp4") {
                                            videoURLs.append(url)
                                            qualities.append("default")
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
        }
        
        if videoURLs.isEmpty {
            // Fallback: Try to find video URL in meta tags
            if let videoURL = try? doc.select("meta[property='og:video:url']").first?.attr("content") {
                if let url = URL(string: videoURL) {
                    videoURLs.append(url)
                    qualities.append("default")
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from Twitter")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.enumerated().map { index, url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: qualities.count > index ? qualities[index] : nil,
                format: "mp4"
            )
        }
    }
}

// MARK: - TikTok Extraction

extension VideoDownloader {
    private func extractTikTokVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "TikTok Video"
        
        // Extract video URL from JSON data
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("video") || scriptText.contains("playAddr") {
                // Try to find video URLs in script
                if let data = scriptText.data(using: .utf8) {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let videoData = json["video"] as? [String: Any],
                               let playAddr = videoData["playAddr"] as? String {
                                if let url = URL(string: playAddr) {
                                    videoURLs.append(url)
                                }
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
        }
        
        if videoURLs.isEmpty {
            // Fallback: Try to find video URL in meta tags
            if let videoURL = try? doc.select("meta[property='og:video:url']").first?.attr("content") {
                if let url = URL(string: videoURL) {
                    videoURLs.append(url)
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from TikTok")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.map { url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: "default",
                format: "mp4"
            )
        }
    }
}

// MARK: - Reddit Extraction

extension VideoDownloader {
    private func extractRedditVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Reddit Video"
        
        // Extract video URL from JSON data
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        var qualities: [String] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("video") || scriptText.contains("mp4") {
                // Try to find video URLs in script
                if let data = scriptText.data(using: .utf8) {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let media = json["media"] as? [String: Any],
                               let redditVideo = media["reddit_video"] as? [String: Any],
                               let fallbackUrl = redditVideo["fallback_url"] as? String {
                                if let url = URL(string: fallbackUrl) {
                                    videoURLs.append(url)
                                    qualities.append("default")
                                }
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
        }
        
        if videoURLs.isEmpty {
            // Fallback: Try to find video URL in meta tags
            if let videoURL = try? doc.select("meta[property='og:video:url']").first?.attr("content") {
                if let url = URL(string: videoURL) {
                    videoURLs.append(url)
                    qualities.append("default")
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from Reddit")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.enumerated().map { index, url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: qualities.count > index ? qualities[index] : nil,
                format: "mp4"
            )
        }
    }
}

// MARK: - Twitch Extraction

extension VideoDownloader {
    private func extractTwitchVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Twitch Video"
        
        // Extract video URL from JSON data
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        var qualities: [String] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("m3u8") || scriptText.contains("mp4") {
                // Try to find video URLs in script
                let patterns = ["https://[^\\s]+\\.m3u8", "https://[^\\s]+\\.mp4"]
                
                for pattern in patterns {
                    if let regex = try? NSRegularExpression(pattern: pattern) {
                        let matches = regex.matches(in: scriptText, range: NSRange(scriptText.startIndex..., in: scriptText))
                        for match in matches {
                            if match.numberOfRanges > 0 {
                                let range = match.range(at: 0)
                                if let substringRange = Range(range, in: scriptText) {
                                    let urlString = String(scriptText[substringRange])
                                    if let url = URL(string: urlString) {
                                        videoURLs.append(url)
                                        qualities.append(urlString.contains("720") ? "720p" : urlString.contains("1080") ? "1080p" : "default")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from Twitch")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.enumerated().map { index, url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: qualities.count > index ? qualities[index] : nil,
                format: url.absoluteString.contains("m3u8") ? "m3u8" : "mp4"
            )
        }
    }
}

// MARK: - SoundCloud Extraction

extension VideoDownloader {
    private func extractSoundCloudVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "SoundCloud Audio"
        
        // Extract audio URL from JSON data
        let scripts = try doc.select("script")
        
        var videoURLs: [URL] = []
        
        for script in scripts {
            let scriptText = try script.html()
            if scriptText.contains("mp3") || scriptText.contains("progressive") {
                // Try to find audio URLs in script
                if let data = scriptText.data(using: .utf8) {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let media = json["media"] as? [String: Any],
                               let transcodings = media["transcodings"] as? [[String: Any]] {
                                for transcoding in transcodings {
                                    if let urlString = transcoding["url"] as? String,
                                       let url = URL(string: urlString) {
                                        videoURLs.append(url)
                                    }
                                }
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract audio URL from SoundCloud")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.map { url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: "audio",
                format: "mp3"
            )
        }
    }
}

// MARK: - Generic Extraction

extension VideoDownloader {
    private func extractGenericVideoInfo(from url: URL) async throws -> [VideoInfo] {
        let html = try await fetchHTML(from: url)
        let doc = try SwiftSoup.parse(html)
        
        let title = try doc.title() ?? "Video"
        
        // Try to find video URL in meta tags
        var videoURLs: [URL] = []
        
        let videoMetaTags = try doc.select("meta[property='og:video:url']")
        for tag in videoMetaTags {
            if let urlString = try? tag.attr("content"), let url = URL(string: urlString) {
                videoURLs.append(url)
            }
        }
        
        // Try to find video URL in video tags
        let videoTags = try doc.select("video")
        for tag in videoTags {
            if let urlString = try? tag.attr("src"), let url = URL(string: urlString) {
                videoURLs.append(url)
            }
        }
        
        // Try to find video URL in source tags
        let sourceTags = try doc.select("source")
        for tag in sourceTags {
            if let urlString = try? tag.attr("src"), let url = URL(string: urlString) {
                videoURLs.append(url)
            }
        }
        
        if videoURLs.isEmpty {
            throw DownloadError.extractionFailed("Could not extract video URL from the page")
        }
        
        let thumbnailURL = try doc.select("meta[property='og:image']").first?.attr("content").flatMap { URL(string: $0) }
        
        return videoURLs.map { url in
            VideoInfo(
                title: title,
                url: url,
                thumbnailURL: thumbnailURL,
                quality: "default",
                format: url.pathExtension.isEmpty ? "mp4" : url.pathExtension
            )
        }
    }
}

// MARK: - Helper Methods

extension VideoDownloader {
    private func fetchHTML(from url: URL) async throws -> String {
        let headers: HTTPHeaders = [
            "User-Agent": userAgent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5"
        ]
        
        let request = session.request(url, method: .get, headers: headers)
        
        let response = await request.serializingString()
        
        switch response {
        case .success(let html):
            return html
        case .failure(let error):
            throw DownloadError.downloadFailed(error)
        }
    }
}
