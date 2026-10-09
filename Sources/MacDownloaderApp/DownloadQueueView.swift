import SwiftUI
import MacDownloaderCore

struct DownloadQueueView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDownload: QueuedDownload?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: startAll) {
                    Label("Start All", systemImage: "play.circle")
                }
                .disabled(appState.downloadQueue.queuedDownloads.isEmpty)
                
                Button(action: pauseAll) {
                    Label("Pause All", systemImage: "pause.circle")
                }
                .disabled(appState.downloadQueue.activeDownloads.isEmpty)
                
                Button(action: cancelAll) {
                    Label("Cancel All", systemImage: "xmark.circle")
                }
                .disabled(appState.downloadQueue.count == 0)
                
                Spacer()
                
                Button(action: clearCompleted) {
                    Label("Clear Completed", systemImage: "trash")
                }
                .disabled(appState.downloadQueue.completedDownloads.isEmpty)
                
                Button(action: clearAll) {
                    Label("Clear All", systemImage: "trash.fill")
                }
                .disabled(appState.downloadQueue.count == 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Queue list
            List(selection: $selectedDownload) {
                ForEach(appState.downloadQueue.allDownloads) { download in
                    QueueRow(download: download, onRetry: { appState.downloadQueue.retry(download.id) })
                        .tag(download)
                        .contextMenu {
                            Button(action: { appState.downloadQueue.retry(download.id) }) {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }
                            .disabled(download.status != .failed)
                            
                            Button(action: { appState.downloadQueue.cancel(download.id) }) {
                                Label("Cancel", systemImage: "xmark")
                            }
                            .disabled(download.status == .completed || download.status == .cancelled)
                            
                            Button(action: { appState.downloadQueue.remove(download.id) }) {
                                Label("Remove", systemImage: "trash")
                            }
                            .disabled(download.status == .downloading)
                        }
                }
            }
            .listStyle(.plain)
            
            // Summary
            HStack {
                Text("Total: " + String(appState.downloadQueue.count))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Active: " + String(appState.downloadQueue.activeDownloads.count))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Queued: " + String(appState.downloadQueue.queuedDownloads.count))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Completed: " + String(appState.downloadQueue.completedDownloads.count))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
        }
        .navigationTitle("Download Queue")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: addNewDownload) {
                    Label("Add Download", systemImage: "plus")
                }
            }
        }
    }
    
    private func startAll() {
        for download in appState.downloadQueue.queuedDownloads {
            appState.downloadQueue.resume(download.id)
        }
    }
    
    private func pauseAll() {
        for download in appState.downloadQueue.activeDownloads {
            appState.downloadQueue.pause(download.id)
        }
    }
    
    private func cancelAll() {
        for download in appState.downloadQueue.allDownloads {
            appState.downloadQueue.cancel(download.id)
        }
    }
    
    private func clearCompleted() {
        appState.downloadQueue.clearCompleted()
    }
    
    private func clearAll() {
        appState.downloadQueue.clear()
    }
    
    private func addNewDownload() {
        // Show a sheet to add new download
    }
}

struct QueueRow: View {
    let download: QueuedDownload
    let onRetry: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status
            statusView
                .frame(width: 30, alignment: .center)
            
            // Info
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
                
                // Progress bar
                if download.status == .downloading {
                    ProgressView(value: download.progress)
                        .frame(height: 4)
                        .controlSize(.small)
                }
            }
            
            Spacer()
            
            // Actions
            VStack(alignment: .trailing, spacing: 4) {
                if download.status == .failed {
                    Button(action: onRetry) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .help("Retry")
                }
                
                Text(formatProgress(download.progress))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
    
    private var statusView: some View {
        Group {
            switch download.status {
            case .queued:
                Image(systemName: "clock")
                    .foregroundColor(.orange)
            case .downloading:
                ProgressView()
                    .frame(width: 20, height: 20)
            case .paused:
                Image(systemName: "pause")
                    .foregroundColor(.yellow)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
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
    
    private func formatProgress(_ progress: Double) -> String {
        let percentage = Int(progress * 100)
        return String(percentage) + "%"
    }
}
