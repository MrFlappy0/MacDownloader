import XCTest
@testable import MacDownloaderCore

final class DownloadQueueTests: XCTestCase {
    
    var queue: DownloadQueue!
    
    override func setUp() {
        super.setUp()
        queue = DownloadQueue()
    }
    
    override func tearDown() {
        queue = nil
        super.tearDown()
    }
    
    func testEmptyQueue() {
        XCTAssertTrue(queue.isEmpty, "Queue should be empty initially")
        XCTAssertEqual(queue.count, 0, "Queue count should be 0 initially")
        XCTAssertTrue(queue.allDownloads.isEmpty, "All downloads should be empty")
        XCTAssertTrue(queue.activeDownloads.isEmpty, "Active downloads should be empty")
        XCTAssertTrue(queue.queuedDownloads.isEmpty, "Queued downloads should be empty")
        XCTAssertTrue(queue.completedDownloads.isEmpty, "Completed downloads should be empty")
        XCTAssertTrue(queue.failedDownloads.isEmpty, "Failed downloads should be empty")
    }
    
    func testAddDownload() {
        let url = "https://example.com/video.mp4"
        let download = queue.add(url: url)
        
        XCTAssertFalse(queue.isEmpty, "Queue should not be empty after adding")
        XCTAssertEqual(queue.count, 1, "Queue count should be 1")
        XCTAssertEqual(queue.allDownloads.count, 1, "All downloads count should be 1")
        XCTAssertEqual(queue.queuedDownloads.count, 1, "Queued downloads count should be 1")
        
        XCTAssertEqual(download.url, url)
        XCTAssertEqual(download.status, .queued)
        XCTAssertEqual(download.progress, 0)
    }
    
    func testAddMultipleDownloads() {
        let urls = [
            "https://example.com/video1.mp4",
            "https://example.com/video2.mp4",
            "https://example.com/video3.mp4"
        ]
        
        for url in urls {
            queue.add(url: url)
        }
        
        XCTAssertEqual(queue.count, 3, "Queue count should be 3")
        XCTAssertEqual(queue.allDownloads.count, 3, "All downloads count should be 3")
    }
    
    func testRemoveDownload() {
        let download1 = queue.add(url: "https://example.com/video1.mp4")
        let download2 = queue.add(url: "https://example.com/video2.mp4")
        
        XCTAssertEqual(queue.count, 2)
        
        let removed = queue.remove(download1.id)
        
        XCTAssertNotNil(removed, "Should return removed download")
        XCTAssertEqual(removed?.id, download1.id)
        XCTAssertEqual(queue.count, 1, "Queue count should be 1 after removal")
        
        // Try to remove non-existent download
        let nonExistentResult = queue.remove(UUID())
        XCTAssertNil(nonExistentResult, "Should return nil for non-existent download")
    }
    
    func testClearQueue() {
        queue.add(url: "https://example.com/video1.mp4")
        queue.add(url: "https://example.com/video2.mp4")
        
        XCTAssertEqual(queue.count, 2)
        
        queue.clear()
        
        XCTAssertTrue(queue.isEmpty, "Queue should be empty after clear")
        XCTAssertEqual(queue.count, 0)
    }
    
    func testClearCompleted() {
        let download1 = queue.add(url: "https://example.com/video1.mp4")
        let download2 = queue.add(url: "https://example.com/video2.mp4")
        
        // Simulate completion
        if let index1 = queue.allDownloads.firstIndex(where: { $0.id == download1.id }) {
            queue.allDownloads[index1].status = .completed
        }
        if let index2 = queue.allDownloads.firstIndex(where: { $0.id == download2.id }) {
            queue.allDownloads[index2].status = .completed
        }
        
        XCTAssertEqual(queue.completedDownloads.count, 2)
        
        queue.clearCompleted()
        
        XCTAssertEqual(queue.completedDownloads.count, 0)
        XCTAssertEqual(queue.count, 0)
    }
    
    func testDownloadStatus() {
        let download = queue.add(url: "https://example.com/video.mp4")
        
        XCTAssertEqual(download.status, .queued)
        
        // Test status changes
        if let index = queue.allDownloads.firstIndex(where: { $0.id == download.id }) {
            queue.allDownloads[index].status = .downloading
            XCTAssertEqual(queue.allDownloads[index].status, .downloading)
            
            queue.allDownloads[index].status = .paused
            XCTAssertEqual(queue.allDownloads[index].status, .paused)
            
            queue.allDownloads[index].status = .completed
            XCTAssertEqual(queue.allDownloads[index].status, .completed)
            
            queue.allDownloads[index].status = .failed
            XCTAssertEqual(queue.allDownloads[index].status, .failed)
            
            queue.allDownloads[index].status = .cancelled
            XCTAssertEqual(queue.allDownloads[index].status, .cancelled)
        }
    }
    
    func testQueuedDownloadProperties() {
        let url = "https://example.com/video.mp4"
        let quality = "1080p"
        let outputPath = URL(fileURLWithPath: "/tmp/downloads")
        
        let download = QueuedDownload(url: url, quality: quality, outputPath: outputPath)
        
        XCTAssertEqual(download.url, url)
        XCTAssertEqual(download.quality, quality)
        XCTAssertEqual(download.outputPath, outputPath)
        XCTAssertEqual(download.status, .queued)
        XCTAssertEqual(download.progress, 0)
        XCTAssertNotNil(download.id)
        XCTAssertNotNil(download.createdDate)
        XCTAssertNil(download.completionDate)
        XCTAssertNil(download.videoInfo)
        XCTAssertNil(download.error)
    }
    
    func testDownloadWithQuality() {
        let download = queue.add(url: "https://example.com/video.mp4", quality: "720p")
        
        XCTAssertEqual(download.quality, "720p")
    }
    
    func testDownloadWithOutputPath() {
        let outputPath = URL(fileURLWithPath: "/tmp/custom/path")
        let download = queue.add(url: "https://example.com/video.mp4", outputPath: outputPath)
        
        XCTAssertEqual(download.outputPath, outputPath)
    }
}
