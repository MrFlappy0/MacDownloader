import SwiftUI

@main
struct MacDownloaderApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
        
        WindowGroup("Download Queue", id: "download-queue") {
            DownloadQueueView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowResizability(.contentSize)
    }
}

class AppState: ObservableObject {
    @Published var downloadQueue = DownloadQueue()
    @Published var settings = Settings()
    @Published var recentDownloads: [QueuedDownload] = []
    
    init() {
        loadSettings()
        downloadQueue.delegate = self
    }
    
    func loadSettings() {
        // Load saved settings
        if let savedSettings = UserDefaults.standard.data(forKey: "appSettings"),
           let decoded = try? JSONDecoder().decode(Settings.self, from: savedSettings) {
            settings = decoded
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "appSettings")
        }
    }
}

struct Settings: Codable {
    var downloadLocation: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    var defaultQuality: String?
    var autoStartDownloads: Bool = true
    var showNotifications: Bool = true
    var maxConcurrentDownloads: Int = 1
    var darkMode: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case downloadLocation
        case defaultQuality
        case autoStartDownloads
        case showNotifications
        case maxConcurrentDownloads
        case darkMode
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        downloadLocation = try container.decodeIfPresent(URL.self, forKey: .downloadLocation) ?? 
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        defaultQuality = try container.decodeIfPresent(String.self, forKey: .defaultQuality)
        autoStartDownloads = try container.decodeIfPresent(Bool.self, forKey: .autoStartDownloads) ?? true
        showNotifications = try container.decodeIfPresent(Bool.self, forKey: .showNotifications) ?? true
        maxConcurrentDownloads = try container.decodeIfPresent(Int.self, forKey: .maxConcurrentDownloads) ?? 1
        darkMode = try container.decodeIfPresent(Bool.self, forKey: .darkMode) ?? true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloadLocation, forKey: .downloadLocation)
        try container.encodeIfPresent(defaultQuality, forKey: .defaultQuality)
        try container.encode(autoStartDownloads, forKey: .autoStartDownloads)
        try container.encode(showNotifications, forKey: .showNotifications)
        try container.encode(maxConcurrentDownloads, forKey: .maxConcurrentDownloads)
        try container.encode(darkMode, forKey: .darkMode)
    }
}

extension DownloadQueue: DownloadQueueDelegate {
    public func queueUpdated(_ queue: DownloadQueue) {
        // Update recent downloads
        let recent = queue.completedDownloads.sorted { $0.completionDate ?? Date.distantPast > $1.completionDate ?? Date.distantPast }
        
        DispatchQueue.main.async {
            if let appState = queue.delegate as? AppState {
                appState.recentDownloads = recent.prefix(20).map { $0 }
            }
        }
    }
    
    public func downloadStatusChanged(_ download: QueuedDownload) {
        // Handle status change
        if download.status == .completed {
            showNotification(title: "Download Complete", subtitle: download.videoInfo?.title ?? "Video")
        } else if download.status == .failed {
            showNotification(title: "Download Failed", subtitle: download.videoInfo?.title ?? "Video")
        }
    }
    
    public func downloadProgressUpdated(_ download: QueuedDownload, progress: Double) {
        // Update progress
    }
    
    private func showNotification(title: String, subtitle: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = subtitle
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
