import XCTest
@testable import MacDownloaderCore

final class VideoDownloaderTests: XCTestCase {
    
    var downloader: VideoDownloader!
    
    override func setUp() {
        super.setUp()
        downloader = VideoDownloader()
    }
    
    override func tearDown() {
        downloader = nil
        super.tearDown()
    }
    
    func testSupportedSites() {
        // Test that supported sites are correctly identified
        let sites = SupportedSite.allCases
        
        XCTAssertFalse(sites.isEmpty, "There should be at least one supported site")
        
        // Test YouTube detection
        let youtubeURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let youtubeSite = SupportedSite.site(from: youtubeURL)
        XCTAssertEqual(youtubeSite, .youtube, "YouTube URL should be detected as YouTube")
        
        // Test Vimeo detection
        let vimeoURL = "https://vimeo.com/123456789"
        let vimeoSite = SupportedSite.site(from: vimeoURL)
        XCTAssertEqual(vimeoSite, .vimeo, "Vimeo URL should be detected as Vimeo")
        
        // Test TikTok detection
        let tiktokURL = "https://www.tiktok.com/@user/video/123456789"
        let tiktokSite = SupportedSite.site(from: tiktokURL)
        XCTAssertEqual(tiktokSite, .tiktok, "TikTok URL should be detected as TikTok")
    }
    
    func testSanitizeFilename() {
        let downloader = VideoDownloader()
        
        // Test filename sanitization
        let testCases = [
            ("Normal File.mp4", "Normal File.mp4"),
            ("File/With/Slashes.mp4", "File_With_Slashes.mp4"),
            ("File:With:Colons.mp4", "File_With_Colons.mp4"),
            ("File*With*Asterisks.mp4", "File_With_Asterisks.mp4"),
            ("File?With?Questions.mp4", "File_With_Questions.mp4"),
            ("File\"With\"Quotes.mp4", "File_With_Quotes.mp4"),
            ("File<With>Brackets.mp4", "File_With_Brackets.mp4"),
            ("File|With|Pipes.mp4", "File_With_Pipes.mp4"),
        ]
        
        for (input, expected) in testCases {
            let sanitized = downloader.sanitizeFilename(input.replacingOccurrences(of: ".mp4", with: "")) + ".mp4"
            // Note: The sanitizeFilename method doesn't add the extension, so we need to adjust
            let baseName = downloader.sanitizeFilename(input.replacingOccurrences(of: ".mp4", with: ""))
            let result = baseName + ".mp4"
            XCTAssertEqual(result, expected, "Filename '" + input + "' should sanitize to '" + expected + "'")
        }
    }
    
    func testVideoInfoStruct() {
        // Test VideoInfo initialization
        let url = URL(string: "https://example.com/video.mp4")!
        let thumbnailURL = URL(string: "https://example.com/thumbnail.jpg")!
        
        let videoInfo = VideoInfo(
            title: "Test Video",
            url: url,
            thumbnailURL: thumbnailURL,
            duration: 120.5,
            quality: "1080p",
            format: "mp4"
        )
        
        XCTAssertEqual(videoInfo.title, "Test Video")
        XCTAssertEqual(videoInfo.url, url)
        XCTAssertEqual(videoInfo.thumbnailURL, thumbnailURL)
        XCTAssertEqual(videoInfo.duration, 120.5)
        XCTAssertEqual(videoInfo.quality, "1080p")
        XCTAssertEqual(videoInfo.format, "mp4")
    }
    
    func testDownloadError() {
        // Test DownloadError cases
        let invalidURLError = DownloadError.invalidURL
        let downloadFailedError = DownloadError.downloadFailed(NSError(domain: "test", code: 1))
        let fileWriteFailedError = DownloadError.fileWriteFailed(NSError(domain: "test", code: 2))
        let noVideoFoundError = DownloadError.noVideoFound
        let unsupportedSiteError = DownloadError.unsupportedSite
        let extractionFailedError = DownloadError.extractionFailed("Test message")
        
        // Verify error cases exist
        XCTAssertNotNil(invalidURLError)
        XCTAssertNotNil(downloadFailedError)
        XCTAssertNotNil(fileWriteFailedError)
        XCTAssertNotNil(noVideoFoundError)
        XCTAssertNotNil(unsupportedSiteError)
        XCTAssertNotNil(extractionFailedError)
    }
    
    func testDownloadProgress() {
        // Test DownloadProgress calculation
        let progress1 = DownloadProgress(bytesDownloaded: 500, totalBytes: 1000)
        XCTAssertEqual(progress1.progress, 0.5, "Progress should be 0.5")
        
        let progress2 = DownloadProgress(bytesDownloaded: 1000, totalBytes: 1000)
        XCTAssertEqual(progress2.progress, 1.0, "Progress should be 1.0")
        
        let progress3 = DownloadProgress(bytesDownloaded: 0, totalBytes: 1000)
        XCTAssertEqual(progress3.progress, 0.0, "Progress should be 0.0")
        
        let progress4 = DownloadProgress(bytesDownloaded: 500, totalBytes: nil)
        XCTAssertEqual(progress4.progress, 0.0, "Progress should be 0.0 when totalBytes is nil")
    }
    
    func testSiteSupportsMultipleQualities() {
        // Test which sites support multiple qualities
        XCTAssertTrue(SupportedSite.youtube.supportsMultipleQualities)
        XCTAssertTrue(SupportedSite.vimeo.supportsMultipleQualities)
        XCTAssertTrue(SupportedSite.dailymotion.supportsMultipleQualities)
        XCTAssertTrue(SupportedSite.facebook.supportsMultipleQualities)
        XCTAssertTrue(SupportedSite.twitch.supportsMultipleQualities)
        
        XCTAssertFalse(SupportedSite.instagram.supportsMultipleQualities)
        XCTAssertFalse(SupportedSite.twitter.supportsMultipleQualities)
        XCTAssertFalse(SupportedSite.tiktok.supportsMultipleQualities)
        XCTAssertFalse(SupportedSite.reddit.supportsMultipleQualities)
        XCTAssertFalse(SupportedSite.soundcloud.supportsMultipleQualities)
        XCTAssertFalse(SupportedSite.generic.supportsMultipleQualities)
    }
    
    func testSiteSupportedFormats() {
        // Test supported formats for each site
        XCTAssertEqual(SupportedSite.youtube.supportedFormats, ["mp4"])
        XCTAssertEqual(SupportedSite.vimeo.supportedFormats, ["mp4"])
        XCTAssertEqual(SupportedSite.dailymotion.supportedFormats, ["mp4"])
        XCTAssertEqual(SupportedSite.facebook.supportedFormats, ["mp4"])
        XCTAssertEqual(SupportedSite.instagram.supportedFormats, ["mp4"])
        XCTAssertEqual(SupportedSite.twitter.supportedFormats, ["mp4"])
        XCTAssertEqual(SupportedSite.tiktok.supportedFormats, ["mp4"])
        XCTAssertEqual(SupportedSite.reddit.supportedFormats, ["mp4"])
        XCTAssertTrue(SupportedSite.twitch.supportedFormats.contains("mp4"))
        XCTAssertTrue(SupportedSite.twitch.supportedFormats.contains("m3u8"))
        XCTAssertEqual(SupportedSite.soundcloud.supportedFormats, ["mp3"])
    }
}
