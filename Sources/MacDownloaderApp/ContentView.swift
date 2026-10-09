import SwiftUI
import MacDownloaderCore

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var urlText: String = ""
    @State private var selectedQuality: String? = nil
    @State private var isDownloading = false
    @State private var showQueue = false
    @State private var showInfoSheet = false
    @State private var videoInfo: [VideoInfo]?
    @State private var errorMessage: String?
    @State private var supportedSites = SupportedSite.allCases
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(appState)
        } detail: {
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Main content
                mainContentView
                    .padding(.horizontal)
                
                Divider()
                
                // Recent downloads
                recentDownloadsView
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            .background(Color(.windowBackgroundColor))
            .navigationTitle("MacDownloader")
            .sheet(isPresented: $showInfoSheet) {
                VideoInfoSheet(videoInfo: videoInfo ?? [], onClose: { videoInfo = nil })
                    .frame(minWidth: 600, minHeight: 400)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = nil
                    }
                )
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("MacDownloader")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showQueue = true }) {
                    Label("Queue", systemImage: "list.bullet")
                }
                .help("Show Download Queue")
                
                Button(action: { NSApp.sendAction(#selector(NSApplication.showSettings(_:)), to: nil, from: nil) }) {
                    Label("Settings", systemImage: "gear")
                }
                .help("Open Settings")
            }
            
            // URL Input
            HStack(spacing: 12) {
                TextField("Enter video URL...", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .disableAutocorrection(true)
                    .onSubmit {
                        handleDownload()
                    }
                
                Picker("Quality", selection: $selectedQuality) {
                    Text("Auto").tag(nil as String?)
                    ForEach(["1080p", "720p", "480p", "360p", "HD", "SD"], id: \.self) { quality in
                        Text(quality).tag(quality as String?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                .disabled(true)
                
                Button(action: handleDownload) {
                    Label("Download", systemImage: "arrow.down.circle")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .disabled(urlText.isEmpty || isDownloading)
                .buttonStyle(.borderedProminent)
                .help("Download the video")
                
                Button(action: fetchVideoInfo) {
                    Image(systemName: "info.circle")
                        .padding(8)
                }
                .disabled(urlText.isEmpty)
                .buttonStyle(.bordered)
                .help("Get video information")
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 16) {
            // Supported sites
            VStack(alignment: .leading, spacing: 8) {
                Text("Supported Sites")
                    .font(.headline)
                
                FlowLayout(
                    items: supportedSites.map { $0.rawValue },
                    spacing: 8,
                    lineSpacing: 8
                ) { site in
                    Text(site)
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 16)
            
            // Quick actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    QuickActionButton(
                        icon: "plus.circle",
                        title: "Add URL",
                        color: .blue
                    ) {
                        // Focus on URL field
                    }
                    
                    QuickActionButton(
                        icon: "folder",
                        title: "Open Folder",
                        color: .green
                    ) {
                        NSWorkspace.shared.open(appState.settings.downloadLocation)
                    }
                    
                    QuickActionButton(
                        icon: "list.bullet",
                        title: "View Queue",
                        color: .orange
                    ) {
                        showQueue = true
                    }
                    
                    QuickActionButton(
                        icon: "gear",
                        title: "Settings",
                        color: .gray
                    ) {
                        NSApp.sendAction(#selector(NSApplication.showSettings(_:)), to: nil, from: nil)
                    }
                }
            }
            .padding(.vertical, 16)
            
            Spacer()
        }
    }
    
    private var recentDownloadsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !appState.recentDownloads.isEmpty {
                HStack {
                    Text("Recent Downloads")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        appState.recentDownloads.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appState.recentDownloads.prefix(5)) { download in
                            RecentDownloadCard(download: download)
                        }
                    }
                }
            }
        }
    }
    
    private func handleDownload() {
        guard !urlText.isEmpty else { return }
        
        isDownloading = true
        errorMessage = nil
        
        Task {
            do {
                let download = QueuedDownload(
                    url: urlText,
                    quality: selectedQuality,
                    outputPath: appState.settings.downloadLocation
                )
                
                appState.downloadQueue.add(download)
                
                // Clear URL field
                DispatchQueue.main.async {
                    urlText = ""
                    isDownloading = false
                    selectedQuality = nil
                }
                
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isDownloading = false
                }
            }
        }
    }
    
    private func fetchVideoInfo() {
        guard !urlText.isEmpty else { return }
        
        errorMessage = nil
        
        Task {
            do {
                let downloader = VideoDownloader()
                let infos = try await downloader.extractVideoInfo(from: urlText)
                
                DispatchQueue.main.async {
                    videoInfo = infos
                    showInfoSheet = true
                }
                
            } catch let error as DownloadError {
                DispatchQueue.main.async {
                    switch error {
                    case .invalidURL:
                        errorMessage = "Invalid URL"
                    case .noVideoFound:
                        errorMessage = "No video found at this URL"
                    case .unsupportedSite:
                        errorMessage = "This site is not supported"
                    case .extractionFailed(let message):
                        errorMessage = "Failed to extract video: " + message
                    default:
                        errorMessage = error.localizedDescription
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
            }
            .padding(12)
            .frame(width: 80)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help(title)
    }
}

struct RecentDownloadCard: View {
    let download: QueuedDownload
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let videoInfo = download.videoInfo {
                Text(videoInfo.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                
                if let duration = videoInfo.duration {
                    Text(formatDuration(duration))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                if let quality = videoInfo.quality {
                    Text(quality)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Unknown Video")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 200, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor)),
            alignment: .bottom
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
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

struct FlowLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    
    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(proposal) }
        
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        
        for size in sizes {
            if currentLineWidth + size.width + spacing > proposal.width ?? .infinity {
                totalWidth = max(totalWidth, currentLineWidth)
                totalHeight += currentLineHeight + lineSpacing
                currentLineWidth = size.width
                currentLineHeight = size.height
            } else {
                currentLineWidth += size.width + spacing
                currentLineHeight = max(currentLineHeight, size.height)
            }
        }
        
        totalWidth = max(totalWidth, currentLineWidth)
        totalHeight += currentLineHeight
        
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var point = CGPoint(x: bounds.minX, y: bounds.minY)
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            
            if point.x + size.width + spacing > bounds.maxX {
                point.x = bounds.minX
                point.y += currentLineHeight + lineSpacing
                currentLineHeight = 0
            }
            
            subview.place(at: point, proposal: ProposedViewSize(size))
            point.x += size.width + spacing
            currentLineHeight = max(currentLineHeight, size.height)
        }
    }
}
