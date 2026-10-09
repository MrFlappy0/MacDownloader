import SwiftUI
import MacDownloaderCore

struct VideoInfoSheet: View {
    let videoInfo: [VideoInfo]
    let onClose: () -> Void
    
    @State private var selectedQuality: VideoInfo?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Video Information")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.borderless)
            }
            
            Divider()
            
            // Video list
            if videoInfo.count == 1 {
                singleVideoView(videoInfo[0])
            } else {
                multipleVideosView
            }
            
            Divider()
            
            // Actions
            HStack {
                Spacer()
                Button("Close") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(minWidth: 600)
    }
    
    private var singleVideoView: some View { { info in
        VStack(alignment: .leading, spacing: 16) {
            // Thumbnail
            if let thumbnailURL = info.thumbnailURL {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(8)
                } placeholder: {
                    Color.gray
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                        )
                }
                .frame(maxHeight: 200)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text(info.title)
                    .font(.title)
                    .bold()
                
                HStack(spacing: 16) {
                    if let duration = info.duration {
                        Label(formatDuration(duration), systemImage: "clock")
                    }
                    
                    if let quality = info.quality {
                        Label(quality, systemImage: "video")
                    }
                    
                    Label(info.format, systemImage: "doc")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            
            // URL
            VStack(alignment: .leading, spacing: 4) {
                Text("URL")
                    .font(.headline)
                    .fontSize(12)
                Text(info.url.absoluteString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.blue)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
    }}
    
    private var multipleVideosView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Multiple qualities available")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(videoInfo, id: \.url) { info in
                        QualityOptionView(
                            info: info,
                            isSelected: Binding(
                                get: { selectedQuality?.url == info.url },
                                set: { isSelected in
                                    if isSelected {
                                        selectedQuality = info
                                    } else if selectedQuality?.url == info.url {
                                        selectedQuality = nil
                                    }
                                }
                            )
                        )
                    }
                }
            }
            
            Spacer()
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
}

struct QualityOptionView: View {
    let info: VideoInfo
    @Binding var isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(info.quality ?? "Default")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let duration = info.duration {
                        Text(formatDuration(duration))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(info.format)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            isSelected.toggle()
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
}
