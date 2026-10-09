import Foundation

public struct QueuedDownload: Identifiable {
    public let id: UUID
    public let url: String
    public let quality: String?
    public let outputPath: URL?
    public var status: DownloadStatus
    public var progress: Double
    public var videoInfo: VideoInfo?
    public var createdDate: Date
    public var completionDate: Date?
    public var error: DownloadError?
    
    public init(id: UUID = UUID(), url: String, quality: String? = nil, outputPath: URL? = nil) {
        self.id = id
        self.url = url
        self.quality = quality
        self.outputPath = outputPath
        self.status = .queued
        self.progress = 0
        self.videoInfo = nil
        self.createdDate = Date()
        self.completionDate = nil
        self.error = nil
    }
}

public enum DownloadStatus: String, Codable {
    case queued
    case downloading
    case paused
    case completed
    case failed
    case cancelled
}

public protocol DownloadQueueDelegate: AnyObject {
    func queueUpdated(_ queue: DownloadQueue)
    func downloadStatusChanged(_ download: QueuedDownload)
    func downloadProgressUpdated(_ download: QueuedDownload, progress: Double)
}

public class DownloadQueue {
    private var downloads: [QueuedDownload] = []
    private var currentDownload: QueuedDownload?
    private var isProcessing = false
    
    public weak var delegate: DownloadQueueDelegate?
    public let downloader: VideoDownloader
    
    public var allDownloads: [QueuedDownload] {
        return downloads
    }
    
    public var activeDownloads: [QueuedDownload] {
        return downloads.filter { $0.status == .downloading }
    }
    
    public var queuedDownloads: [QueuedDownload] {
        return downloads.filter { $0.status == .queued }
    }
    
    public var completedDownloads: [QueuedDownload] {
        return downloads.filter { $0.status == .completed }
    }
    
    public var failedDownloads: [QueuedDownload] {
        return downloads.filter { $0.status == .failed }
    }
    
    public var count: Int {
        return downloads.count
    }
    
    public var isEmpty: Bool {
        return downloads.isEmpty
    }
    
    public init(downloader: VideoDownloader = VideoDownloader()) {
        self.downloader = downloader
        self.downloader.delegate = self
    }
    
    public func add(url: String, quality: String? = nil, outputPath: URL? = nil) -> QueuedDownload {
        let download = QueuedDownload(url: url, quality: quality, outputPath: outputPath)
        downloads.append(download)
        
        if !isProcessing {
            processQueue()
        }
        
        notifyQueueUpdated()
        return download
    }
    
    public func add(_ download: QueuedDownload) {
        downloads.append(download)
        
        if !isProcessing {
            processQueue()
        }
        
        notifyQueueUpdated()
    }
    
    public func remove(_ id: UUID) -> QueuedDownload? {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            let download = downloads.remove(at: index)
            
            if currentDownload?.id == id {
                currentDownload = nil
                isProcessing = false
                processQueue()
            }
            
            notifyQueueUpdated()
            return download
        }
        return nil
    }
    
    public func clear() {
        downloads.removeAll()
        currentDownload = nil
        isProcessing = false
        notifyQueueUpdated()
    }
    
    public func clearCompleted() {
        downloads = downloads.filter { $0.status != .completed }
        notifyQueueUpdated()
    }
    
    public func clearFailed() {
        downloads = downloads.filter { $0.status != .failed }
        notifyQueueUpdated()
    }
    
    public func pause(_ id: UUID) {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .paused
            notifyDownloadStatusChanged(downloads[index])
        }
    }
    
    public func resume(_ id: UUID) {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .queued
            notifyDownloadStatusChanged(downloads[index])
            processQueue()
        }
    }
    
    public func cancel(_ id: UUID) {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .cancelled
            notifyDownloadStatusChanged(downloads[index])
            
            if currentDownload?.id == id {
                currentDownload = nil
                isProcessing = false
                processQueue()
            }
        }
    }
    
    public func retry(_ id: UUID) {
        if let index = downloads.firstIndex(where: { $0.id == id }) {
            downloads[index].status = .queued
            downloads[index].error = nil
            downloads[index].progress = 0
            notifyDownloadStatusChanged(downloads[index])
            processQueue()
        }
    }
    
    private func processQueue() {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Find next queued download
        if let nextDownload = downloads.first(where: { $0.status == .queued }) {
            currentDownload = nextDownload
            startDownload(nextDownload)
        } else {
            isProcessing = false
            currentDownload = nil
        }
    }
    
    private func startDownload(_ download: QueuedDownload) {
        guard let index = downloads.firstIndex(where: { $0.id == download.id }) else { return }
        
        downloads[index].status = .downloading
        notifyDownloadStatusChanged(downloads[index])
        
        Task {
            do {
                // Extract video info
                let videoInfos = try await downloader.extractVideoInfo(from: download.url)
                
                guard let videoInfo = videoInfos.first else {
                    throw DownloadError.noVideoFound
                }
                
                // Update download with video info
                downloads[index].videoInfo = videoInfo
                notifyDownloadStatusChanged(downloads[index])
                
                // Download the video
                let outputURL = download.outputPath ?? downloader.getDefaultOutputURL(for: videoInfo)
                let finalURL = try await downloader.downloadVideo(from: download.url, quality: download.quality, outputPath: outputURL)
                
                // Mark as completed
                downloads[index].status = .completed
                downloads[index].completionDate = Date()
                downloads[index].progress = 1.0
                notifyDownloadStatusChanged(downloads[index])
                
                // Process next in queue
                currentDownload = nil
                isProcessing = false
                processQueue()
                
            } catch let error as DownloadError {
                // Mark as failed
                downloads[index].status = .failed
                downloads[index].error = error
                downloads[index].completionDate = Date()
                notifyDownloadStatusChanged(downloads[index])
                
                // Process next in queue
                currentDownload = nil
                isProcessing = false
                processQueue()
                
            } catch {
                // Mark as failed
                downloads[index].status = .failed
                downloads[index].error = .downloadFailed(error)
                downloads[index].completionDate = Date()
                notifyDownloadStatusChanged(downloads[index])
                
                // Process next in queue
                currentDownload = nil
                isProcessing = false
                processQueue()
            }
        }
    }
    
    private func notifyQueueUpdated() {
        DispatchQueue.main.async {
            self.delegate?.queueUpdated(self)
        }
    }
    
    private func notifyDownloadStatusChanged(_ download: QueuedDownload) {
        DispatchQueue.main.async {
            self.delegate?.downloadStatusChanged(download)
        }
    }
    
    private func notifyDownloadProgressUpdated(_ download: QueuedDownload, progress: Double) {
        DispatchQueue.main.async {
            self.delegate?.downloadProgressUpdated(download, progress: progress)
        }
    }
}

// MARK: - DownloadDelegate Implementation

extension DownloadQueue: DownloadDelegate {
    public func downloadProgress(_ progress: DownloadProgress, for videoInfo: VideoInfo) {
        guard let currentDownload = currentDownload else { return }
        
        if let index = downloads.firstIndex(where: { $0.id == currentDownload.id }) {
            downloads[index].progress = progress.progress
            notifyDownloadProgressUpdated(downloads[index], progress: progress.progress)
        }
    }
    
    public func downloadCompleted(_ videoInfo: VideoInfo, at location: URL) {
        // Handled in startDownload
    }
    
    public func downloadFailed(_ error: DownloadError, for videoInfo: VideoInfo?) {
        // Handled in startDownload
    }
}
