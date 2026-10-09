import SwiftUI
import MacDownloaderCore

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSite: SupportedSite? = nil
    
    var body: some View {
        List(selection: $selectedSite) {
            Section {
                NavigationLink {
                    ContentView()
                        .environmentObject(appState)
                } label: {
                    Label("Home", systemImage: "house")
                }
                
                NavigationLink {
                    DownloadQueueView()
                        .environmentObject(appState)
                } label: {
                    Label("Download Queue", systemImage: "list.bullet")
                }
                
                NavigationLink {
                    HistoryView()
                        .environmentObject(appState)
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
            
            Section("Supported Sites") {
                ForEach(SupportedSite.allCases.filter { $0 != .generic }, id: \.self) { site in
                    NavigationLink {
                        SiteBrowserView(site: site)
                            .environmentObject(appState)
                    } label: {
                        Label(site.rawValue, systemImage: siteIcon(for: site))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MacDownloader")
    }
    
    private func siteIcon(for site: SupportedSite) -> String {
        switch site {
        case .youtube: return "play.tv"
        case .vimeo: return "play.square"
        case .dailymotion: return "play.circle"
        case .facebook: return "f.circle"
        case .instagram: return "camera"
        case .twitter: return "text.bubble"
        case .tiktok: return "music.note"
        case .reddit: return "person.2"
        case .twitch: return "gamecontroller"
        case .soundcloud: return "waveform"
        case .generic: return "globe"
        }
    }
}

struct SiteBrowserView: View {
    let site: SupportedSite
    @EnvironmentObject var appState: AppState
    @State private var urlText: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: siteIcon(for: site))
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text(site.rawValue)
                    .font(.system(size: 24, weight: .bold))
                
                Text("Domain: " + site.domain)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 16)
            
            // URL Input
            HStack(spacing: 12) {
                TextField("Enter " + site.rawValue + " URL...", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .disableAutocorrection(true)
                    .onSubmit {
                        handleDownload()
                    }
                
                Button(action: handleDownload) {
                    Label("Download", systemImage: "arrow.down.circle")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .disabled(urlText.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            // Site info
            VStack(alignment: .leading, spacing: 8) {
                if site.supportsMultipleQualities {
                    Text("✓ Supports multiple qualities")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                
                Text("Supported formats: " + site.supportedFormats.joined(separator: ", "))
                    .font(.system(size: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle(site.rawValue)
        .padding(.top, 16)
    }
    
    private func siteIcon(for site: SupportedSite) -> String {
        switch site {
        case .youtube: return "play.tv"
        case .vimeo: return "play.square"
        case .dailymotion: return "play.circle"
        case .facebook: return "f.circle"
        case .instagram: return "camera"
        case .twitter: return "text.bubble"
        case .tiktok: return "music.note"
        case .reddit: return "person.2"
        case .twitch: return "gamecontroller"
        case .soundcloud: return "waveform"
        case .generic: return "globe"
        }
    }
    
    private func handleDownload() {
        guard !urlText.isEmpty else { return }
        
        let download = QueuedDownload(
            url: urlText,
            quality: appState.settings.defaultQuality,
            outputPath: appState.settings.downloadLocation
        )
        
        appState.downloadQueue.add(download)
        urlText = ""
    }
}

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            ForEach(appState.recentDownloads) { download in
                DownloadRow(download: download)
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Clear") {
                    appState.recentDownloads.removeAll()
                }
                .disabled(appState.recentDownloads.isEmpty)
            }
        }
    }
}

struct DownloadRow: View {
    let download: QueuedDownload
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let videoInfo = download.videoInfo {
                    Text(videoInfo.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if let duration = videoInfo.duration {
                            Text(formatDuration(duration))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        if let quality = videoInfo.quality {
                            Text(quality)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text(download.url)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                Text(download.url)
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                statusIcon(for: download.status)
                
                if let date = download.completionDate {
                    Text(formatDate(date))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func statusIcon(for status: DownloadStatus) -> some View {
        switch status {
        case .queued:
            return Image(systemName: "clock")
                .foregroundColor(.orange)
        case .downloading:
            return ProgressView()
                .frame(width: 20, height: 20)
        case .paused:
            return Image(systemName: "pause")
                .foregroundColor(.yellow)
        case .completed:
            return Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
        case .failed:
            return Image(systemName: "xmark.circle")
                .foregroundColor(.red)
        case .cancelled:
            return Image(systemName: "xmark")
                .foregroundColor(.gray)
        }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
