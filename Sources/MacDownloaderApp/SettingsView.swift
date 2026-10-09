import SwiftUI
import MacDownloaderCore

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var tempSettings: Settings
    
    init() {
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        _tempSettings = State(initialValue: appState.settings)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General")) {
                    Toggle("Dark Mode", isOn: $tempSettings.darkMode)
                        .onChange(of: tempSettings.darkMode) { _ in saveSettings() }
                    
                    Toggle("Show Notifications", isOn: $tempSettings.showNotifications)
                        .onChange(of: tempSettings.showNotifications) { _ in saveSettings() }
                }
                
                Section(header: Text("Downloads")) {
                    HStack {
                        Text("Download Location")
                        Spacer()
                        Text(tempSettings.downloadLocation.path)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Button("Browse...") {
                            showFolderPicker()
                        }
                    }
                    
                    Picker("Default Quality", selection: $tempSettings.defaultQuality) {
                        Text("Auto").tag(nil as String?)
                        ForEach(["1080p", "720p", "480p", "360p", "HD", "SD"], id: \.self) { quality in
                            Text(quality).tag(quality as String?)
                        }
                    }
                    .onChange(of: tempSettings.defaultQuality) { _ in saveSettings() }
                    
                    Stepper("Max Concurrent Downloads: " + String(tempSettings.maxConcurrentDownloads), 
                            value: $tempSettings.maxConcurrentDownloads,
                            in: 1...10)
                        .onChange(of: tempSettings.maxConcurrentDownloads) { _ in saveSettings() }
                    
                    Toggle("Auto Start Downloads", isOn: $tempSettings.autoStartDownloads)
                        .onChange(of: tempSettings.autoStartDownloads) { _ in saveSettings() }
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MacDownloader")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("An open-source video downloader for macOS")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com/MrFlappy0/MacDownloader")!)
                }
            }
            .formStyle(.grouped)
            .frame(width: 500)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: saveSettings) {
                        Text("Save")
                    }
                }
            }
        }
        .frame(width: 550, height: 500)
    }
    
    private func showFolderPicker() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Download Location"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            tempSettings.downloadLocation = openPanel.url!
            appState.settings.downloadLocation = openPanel.url!
            appState.saveSettings()
        }
    }
    
    private func saveSettings() {
        appState.settings = tempSettings
        appState.saveSettings()
    }
}
