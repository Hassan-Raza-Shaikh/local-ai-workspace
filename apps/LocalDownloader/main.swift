import SwiftUI
import Foundation
import AppKit

// MARK: - App Entrypoint
@main
struct LocalDownloaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 480, minHeight: 460)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// MARK: - Downloader State & Execution Engine
class Downloader: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var speed: String = ""
    @Published var eta: String = ""
    @Published var size: String = ""
    @Published var isDownloading: Bool = false
    @Published var logOutput: String = ""
    @Published var statusMessage: String = "Ready"
    
    private var process: Process?
    private var outputPipe: Pipe?
    
    func startDownload(
        url: String,
        isAudioOnly: Bool,
        outputFolder: String,
        maxResolution: String,
        downloadSubs: Bool,
        browserCookies: String,
        customArgs: String
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.runDownload(
                url: url,
                isAudioOnly: isAudioOnly,
                outputFolder: outputFolder,
                maxResolution: maxResolution,
                downloadSubs: downloadSubs,
                browserCookies: browserCookies,
                customArgs: customArgs
            )
        }
    }
    
    private func runDownload(
        url: String,
        isAudioOnly: Bool,
        outputFolder: String,
        maxResolution: String,
        downloadSubs: Bool,
        browserCookies: String,
        customArgs: String
    ) {
        DispatchQueue.main.async {
            self.isDownloading = true
            self.progress = 0.0
            self.speed = ""
            self.eta = ""
            self.size = ""
            self.logOutput = "Starting download sequence...\n"
            self.statusMessage = "Initializing..."
        }
        
        let process = Process()
        self.process = process
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yt-dlp")
        
        var arguments: [String] = []
        
        // Format options (Audio vs Video with Resolution cap)
        if isAudioOnly {
            arguments.append(contentsOf: ["-x", "--audio-format", "mp3", "--audio-quality", "0"])
        } else {
            switch maxResolution {
            case "1080p":
                arguments.append(contentsOf: ["-f", "bestvideo[height<=1080]+bestaudio/best"])
            case "720p":
                arguments.append(contentsOf: ["-f", "bestvideo[height<=720]+bestaudio/best"])
            case "480p":
                arguments.append(contentsOf: ["-f", "bestvideo[height<=480]+bestaudio/best"])
            default: // Best available
                arguments.append(contentsOf: ["-f", "bestvideo+bestaudio/best"])
            }
            arguments.append(contentsOf: ["--merge-output-format", "mp4"])
        }
        
        // Directory output template
        let outputTemplate = "\(outputFolder)/%(title)s.%(ext)s"
        arguments.append(contentsOf: ["-o", outputTemplate])
        
        // Subtitles configuration
        if downloadSubs {
            arguments.append(contentsOf: ["--write-subs", "--write-auto-subs", "--embed-subs"])
        }
        
        // Browser Cookies integration
        if browserCookies != "None" {
            arguments.append(contentsOf: ["--cookies-from-browser", browserCookies.lowercased()])
        }
        
        // Append Custom User Flags
        let cleanedArgs = customArgs.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedArgs.isEmpty {
            let splitArgs = cleanedArgs.components(separatedBy: " ")
            arguments.append(contentsOf: splitArgs.filter { !$0.isEmpty })
        }
        
        // Append video URL
        arguments.append(url)
        process.arguments = arguments
        
        // Set up IO pipes
        let pipe = Pipe()
        self.outputPipe = pipe
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let outputString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.logOutput += outputString
                    self.parseOutput(outputString)
                }
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            fileHandle.readabilityHandler = nil
            let status = process.terminationStatus
            
            DispatchQueue.main.async {
                self.isDownloading = false
                if status == 0 {
                    self.progress = 1.0
                    self.statusMessage = "Download Complete!"
                } else if status == 15 {
                    self.statusMessage = "Cancelled"
                    self.progress = 0.0
                } else {
                    self.statusMessage = "Error: Code \(status)"
                }
            }
        } catch {
            fileHandle.readabilityHandler = nil
            DispatchQueue.main.async {
                self.isDownloading = false
                self.statusMessage = "Execution failed: \(error.localizedDescription)"
            }
        }
    }
    
    func cancelDownload() {
        if let process = process, process.isRunning {
            process.terminate()
            logOutput += "\n[Download Terminated by User]\n"
        }
    }
    
    func upgradeYtdlp() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.isDownloading = true
                self.statusMessage = "Upgrading Engine..."
                self.logOutput = "Running 'brew upgrade yt-dlp' inside environment...\n"
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
            process.arguments = ["upgrade", "yt-dlp"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { [weak self] handle in
                guard let self = self else { return }
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let outputString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.logOutput += outputString
                    }
                }
            }
            
            do {
                try process.run()
                process.waitUntilExit()
                fileHandle.readabilityHandler = nil
                let status = process.terminationStatus
                DispatchQueue.main.async {
                    self.isDownloading = false
                    if status == 0 {
                        self.statusMessage = "Downloader Upgraded!"
                    } else {
                        self.statusMessage = "Upgrade failed (Code \(status))"
                    }
                }
            } catch {
                fileHandle.readabilityHandler = nil
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.statusMessage = "Upgrade launch failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func parseOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("[download]") {
                // Parse percentage (e.g. 52.4%)
                if let percentRange = line.range(of: "\\b\\d+(\\.\\d+)?%", options: .regularExpression) {
                    var percentStr = String(line[percentRange])
                    percentStr.removeLast()
                    if let percentVal = Double(percentStr) {
                        self.progress = percentVal / 100.0
                        self.statusMessage = "Downloading... \(percentStr)%"
                    }
                }
                
                // Parse file size
                if let ofRange = line.range(of: "of\\s+\\S+", options: .regularExpression) {
                    let parts = String(line[ofRange]).components(separatedBy: .whitespaces)
                    if parts.count >= 2 {
                        self.size = parts[1]
                    }
                }
                
                // Parse speed
                if let atRange = line.range(of: "at\\s+\\S+", options: .regularExpression) {
                    let parts = String(line[atRange]).components(separatedBy: .whitespaces)
                    if parts.count >= 2 {
                        self.speed = parts[1]
                    }
                }
                
                // Parse ETA
                if let etaRange = line.range(of: "ETA\\s+\\S+", options: .regularExpression) {
                    let parts = String(line[etaRange]).components(separatedBy: .whitespaces)
                    if parts.count >= 2 {
                        self.eta = parts[1]
                    }
                }
            }
        }
    }
}

// MARK: - SwiftUI Presentation Layer
struct ContentView: View {
    @StateObject private var downloader = Downloader()
    
    @State private var url: String = ""
    @State private var isAudioOnly: Bool = false
    @State private var outputFolder: String = "\(NSHomeDirectory())/Downloads"
    @State private var maxResolution: String = "Best"
    @State private var downloadSubs: Bool = false
    @State private var browserCookies: String = "None"
    @State private var customArgs: String = ""
    @State private var showLogs: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Title Header
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local Video Downloader")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Powered by yt-dlp")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 6)
            
            // URL Input Section
            VStack(alignment: .leading, spacing: 5) {
                Text("Video URL or Playlist Link")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                TextField("https://www.youtube.com/watch?v=...", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .disabled(downloader.isDownloading)
            }
            
            // Mode Select Segment
            Picker("Format", selection: $isAudioOnly) {
                Text("Video (MP4)").tag(false)
                Text("Audio (MP3)").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(downloader.isDownloading)
            
            // Destination Directory Box
            VStack(alignment: .leading, spacing: 4) {
                Text("Save Destination")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.orange)
                    Text(outputFolder)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Select...") {
                        selectFolder()
                    }
                    .disabled(downloader.isDownloading)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(.thinMaterial)
                .cornerRadius(6)
            }
            
            // Basic Options grid
            VStack(spacing: 10) {
                HStack {
                    Text("Maximum Resolution")
                    Spacer()
                    Picker("", selection: $maxResolution) {
                        Text("Best Quality").tag("Best")
                        Text("1080p (Full HD)").tag("1080p")
                        Text("720p (HD)").tag("720p")
                        Text("480p (SD)").tag("480p")
                    }
                    .frame(width: 160)
                    .disabled(downloader.isDownloading || isAudioOnly)
                }
                
                HStack {
                    Text("Download & Embed Subtitles")
                    Spacer()
                    Toggle("", isOn: $downloadSubs)
                        .toggleStyle(.checkbox)
                        .disabled(downloader.isDownloading || isAudioOnly)
                }
            }
            .padding(10)
            .background(.thinMaterial)
            .cornerRadius(6)
            
            // Advanced Custom Settings
            DisclosureGroup("Advanced Settings") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Extract Cookies From:")
                            .font(.body)
                        Spacer()
                        Picker("", selection: $browserCookies) {
                            Text("None").tag("None")
                            Text("Chrome").tag("Chrome")
                            Text("Safari").tag("Safari")
                            Text("Firefox").tag("Firefox")
                            Text("Brave").tag("Brave")
                        }
                        .frame(width: 160)
                        .disabled(downloader.isDownloading)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom CLI Flags")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g. --playlist-start 2 --limit-rate 1M", text: $customArgs)
                            .textFieldStyle(.roundedBorder)
                            .disabled(downloader.isDownloading)
                    }
                    
                    Button(action: {
                        downloader.upgradeYtdlp()
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle")
                            Text("Upgrade Downloader Engine (yt-dlp)")
                        }
                    }
                    .disabled(downloader.isDownloading)
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            
            // Progress Bar Area
            if downloader.isDownloading || downloader.progress > 0 {
                VStack(spacing: 6) {
                    ProgressView(value: downloader.progress)
                        .progressViewStyle(.linear)
                    
                    HStack {
                        Text(downloader.statusMessage)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        if downloader.isDownloading && !downloader.speed.isEmpty {
                            Text("\(downloader.speed) • \(downloader.size) • ETA \(downloader.eta)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Primary Execute / Terminate Row
            HStack {
                if downloader.isDownloading {
                    Button(action: {
                        downloader.cancelDownload()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Cancel Download")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button(action: {
                        downloader.startDownload(
                            url: url,
                            isAudioOnly: isAudioOnly,
                            outputFolder: outputFolder,
                            maxResolution: maxResolution,
                            downloadSubs: downloadSubs,
                            browserCookies: browserCookies,
                            customArgs: customArgs
                        )
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Start Download")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            // Drawer to expand logs
            Divider()
            Button(action: {
                withAnimation {
                    showLogs.toggle()
                }
            }) {
                HStack {
                    Text(showLogs ? "Hide Diagnostics Console" : "Show Diagnostics Console")
                    Image(systemName: showLogs ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            if showLogs {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(downloader.logOutput)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(4)
                            .id("logText")
                    }
                    .frame(maxHeight: 120)
                    .onChange(of: downloader.logOutput) { _ in
                        proxy.scrollTo("logText", anchor: .bottom)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 480)
        .background(.ultraThinMaterial)
    }
    
    private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Destination Folder"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let path = openPanel.url?.path {
                self.outputFolder = path
            }
        }
    }
}
