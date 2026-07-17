import SwiftUI
import Foundation

// MARK: - macOS 27 Liquid Glass Style System
struct LiquidGlassButtonStyle: ButtonStyle {
    @State private var isHovered = false
    var isProminent: Bool = false
    var accentColor: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .font(.system(.body, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(isProminent ? .white : .primary)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [accentColor.opacity(0.85), accentColor],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .opacity(configuration.isPressed ? 0.75 : (isHovered ? 0.95 : 0.85))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.black.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.05), radius: isHovered ? 4 : 2, x: 0, y: 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65, blendDuration: 0), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.65, blendDuration: 0), value: configuration.isPressed)
            .onHover { hover in
                isHovered = hover
            }
    }
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.black.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func liquidGlassCard() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}


import AppKit

// MARK: - App Entrypoint
@main
struct MediaStudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 580, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// MARK: - Native macOS Translucent Glass Background
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground // Liquid Glass refraction style
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Drag & Drop Area Component
struct DropZoneView: View {
    let title: String
    let fileTypes: String
    @Binding var filePath: String
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: filePath.isEmpty ? "arrow.down.doc.fill" : "doc.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(filePath.isEmpty ? (isTargeted ? .blue : .secondary) : .green)
            
            if filePath.isEmpty {
                Text(title)
                    .fontWeight(.medium)
                Text("or click to browse (\(fileTypes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(URL(fileURLWithPath: filePath).lastPathComponent)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(filePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isTargeted ? Color.blue : Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6]))
        )
        .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
        .contentShape(Rectangle())
        .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                if let url = url {
                    DispatchQueue.main.async {
                        self.filePath = url.path
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Downloader State & Execution Engine (yt-dlp)
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
            default: // Best
                arguments.append(contentsOf: ["-f", "bestvideo+bestaudio/best"])
            }
            arguments.append(contentsOf: ["--merge-output-format", "mp4"])
        }
        
        let outputTemplate = "\(outputFolder)/%(title)s.%(ext)s"
        arguments.append(contentsOf: ["-o", outputTemplate])
        
        if downloadSubs {
            arguments.append(contentsOf: ["--write-subs", "--write-auto-subs", "--embed-subs"])
        }
        
        if browserCookies != "None" {
            arguments.append(contentsOf: ["--cookies-from-browser", browserCookies.lowercased()])
        }
        
        let cleanedArgs = customArgs.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedArgs.isEmpty {
            let splitArgs = cleanedArgs.components(separatedBy: " ")
            arguments.append(contentsOf: splitArgs.filter { !$0.isEmpty })
        }
        
        arguments.append(url)
        process.arguments = arguments
        
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
                if let percentRange = line.range(of: "\\b\\d+(\\.\\d+)?%", options: .regularExpression) {
                    var percentStr = String(line[percentRange])
                    percentStr.removeLast()
                    if let percentVal = Double(percentStr) {
                        self.progress = percentVal / 100.0
                        self.statusMessage = "Downloading... \(percentStr)%"
                    }
                }
                
                if let ofRange = line.range(of: "of\\s+\\S+", options: .regularExpression) {
                    let parts = String(line[ofRange]).components(separatedBy: .whitespaces)
                    if parts.count >= 2 {
                        self.size = parts[1]
                    }
                }
                
                if let atRange = line.range(of: "at\\s+\\S+", options: .regularExpression) {
                    let parts = String(line[atRange]).components(separatedBy: .whitespaces)
                    if parts.count >= 2 {
                        self.speed = parts[1]
                    }
                }
                
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

// MARK: - Script Background Runner State (Whisper, MarkItDown, Crawl4AI)
class ScriptRunner: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var logOutput: String = ""
    @Published var resultText: String = ""
    @Published var statusMessage: String = "Ready"
    @Published var parsedProgress: Double = 0.0
    
    private var process: Process?
    private var outputPipe: Pipe?
    
    func runScript(executable: String, arguments: [String], targetResultFile: String? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.execute(executable: executable, arguments: arguments, targetResultFile: targetResultFile)
        }
    }
    
    private func execute(executable: String, arguments: [String], targetResultFile: String?) {
        DispatchQueue.main.async {
            self.isRunning = true
            self.logOutput = "Launching background Python task...\n"
            self.statusMessage = "Running task..."
            self.resultText = ""
            self.parsedProgress = 0.1
        }
        
        let process = Process()
        self.process = process
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
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
                    self.parseRunnerLogs(outputString)
                }
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            fileHandle.readabilityHandler = nil
            let status = process.terminationStatus
            
            DispatchQueue.main.async {
                self.isRunning = false
                if status == 0 {
                    self.parsedProgress = 1.0
                    self.statusMessage = "Task Completed Successfully!"
                    
                    // If output file exists, read it into resultText
                    if let resultFile = targetResultFile, FileManager.default.fileExists(atPath: resultFile) {
                        do {
                            self.resultText = try String(contentsOfFile: resultFile, encoding: .utf8)
                        } catch {
                            self.resultText = "[Failed to read result file: \(error.localizedDescription)]"
                        }
                    }
                } else if status == 15 {
                    self.statusMessage = "Task Terminated by User."
                    self.parsedProgress = 0.0
                } else {
                    self.statusMessage = "Task Failed (Exit Code \(status))"
                    self.parsedProgress = 0.0
                }
            }
        } catch {
            fileHandle.readabilityHandler = nil
            DispatchQueue.main.async {
                self.isRunning = false
                self.statusMessage = "Launch error: \(error.localizedDescription)"
                self.parsedProgress = 0.0
            }
        }
    }
    
    func terminate() {
        if let process = process, process.isRunning {
            process.terminate()
            logOutput += "\n[Process terminated by user]\n"
        }
    }
    
    private func parseRunnerLogs(_ output: String) {
        if output.contains("Loading Whisper") || output.contains("Initializing MarkItDown") || output.contains("Initializing Crawl4AI") {
            self.parsedProgress = 0.3
            self.statusMessage = "Loading libraries..."
        } else if output.contains("Transcribing") || output.contains("Converting") || output.contains("Scraping") {
            self.parsedProgress = 0.6
            self.statusMessage = "Processing content..."
        }
    }
}

// MARK: - SwiftUI Presentation Layer
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Window drag area and custom title tab control
                HStack(spacing: 12) {
                    Text("Media Studio")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.leading, 20)
                    
                    Picker("", selection: $selectedTab) {
                        Text("Downloader").tag(0)
                        Text("Transcriber").tag(1)
                        Text("Doc Converter").tag(2)
                        Text("Web Scraper").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 360)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.04))
                
                Divider()
                
                // Tab Selection views
                switch selectedTab {
                case 0:
                    DownloaderView()
                case 1:
                    TranscriberView()
                case 2:
                    ConverterView()
                default:
                    ScraperView()
                }
            }
        }
    }
}

// MARK: - Downloader Panel (Tab 1)
struct DownloaderView: View {
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
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Media Downloader")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Download high-quality streams locally using yt-dlp engine")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Media URL or Playlist Link")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextField("https://www.youtube.com/watch?v=...", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .disabled(downloader.isDownloading)
                }
                
                Picker("Format", selection: $isAudioOnly) {
                    Text("Video (MP4)").tag(false)
                    Text("Audio (MP3)").tag(true)
                }
                .pickerStyle(.segmented)
                .disabled(downloader.isDownloading)
                
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
                            TextField("e.g. --playlist-items 1-5", text: $customArgs)
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
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                
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
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
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
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
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
                                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
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
            .frame(maxWidth: .infinity)
        }
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

// MARK: - Audio Transcriber Panel (Tab 2)
struct TranscriberView: View {
    @StateObject private var runner = ScriptRunner()
    @State private var audioPath: String = ""
    @State private var showLogs: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Audio Transcriber")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Transcribe local audio/video file audio offline using OpenAI Whisper")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Drag and Drop Zone
                Button(action: {
                    selectFile()
                }) {
                    DropZoneView(title: "Drag & Drop Audio/Video File Here", fileTypes: "MP3, WAV, M4A, MP4", filePath: $audioPath)
                }
                .buttonStyle(.plain)
                .disabled(runner.isRunning)
                
                if runner.isRunning || runner.parsedProgress > 0 {
                    VStack(spacing: 6) {
                        ProgressView(value: runner.parsedProgress)
                        HStack {
                            Text(runner.statusMessage)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    if runner.isRunning {
                        Button(action: {
                            runner.terminate()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop Transcription")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .tint(.red)
                    } else {
                        Button(action: {
                            startTranscription()
                        }) {
                            HStack {
                                Image(systemName: "waveform.circle.fill")
                                Text("Transcribe Audio")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .disabled(audioPath.isEmpty)
                    }
                }
                
                if !runner.resultText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Transcription Output:")
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(runner.resultText, forType: .string)
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copy Text")
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
                        }
                        
                        ScrollView {
                            Text(runner.resultText)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                                .cornerRadius(6)
                        }
                        .frame(maxHeight: 180)
                    }
                }
                
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
                            Text(runner.logOutput)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                                .cornerRadius(4)
                                .id("logText")
                        }
                        .frame(maxHeight: 120)
                        .onChange(of: runner.logOutput) { _ in
                            proxy.scrollTo("logText", anchor: .bottom)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func selectFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Audio or Video File"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.audio, .movie]
        
        if openPanel.runModal() == .OK {
            if let path = openPanel.url?.path {
                self.audioPath = path
            }
        }
    }
    
    private func startTranscription() {
        let targetTextFile = URL(fileURLWithPath: audioPath).deletingPathExtension().path + ".txt"
        runner.runScript(
            executable: "/opt/miniconda3/bin/python",
            arguments: ["/Users/hassan/local-ai/notebooks/transcribe.py", audioPath],
            targetResultFile: targetTextFile
        )
    }
}

// MARK: - Document Converter Panel (Tab 3)
struct ConverterView: View {
    @StateObject private var runner = ScriptRunner()
    @State private var docPath: String = ""
    @State private var showLogs: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Document Converter")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Convert local files (PDF, Word, Excel, PowerPoint) into clean Markdown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Drag and Drop Zone
                Button(action: {
                    selectFile()
                }) {
                    DropZoneView(title: "Drag & Drop Document File Here", fileTypes: "PDF, DOCX, XLSX, PPTX, HTML", filePath: $docPath)
                }
                .buttonStyle(.plain)
                .disabled(runner.isRunning)
                
                if runner.isRunning || runner.parsedProgress > 0 {
                    VStack(spacing: 6) {
                        ProgressView(value: runner.parsedProgress)
                        HStack {
                            Text(runner.statusMessage)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    if runner.isRunning {
                        Button(action: {
                            runner.terminate()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop Conversion")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .tint(.red)
                    } else {
                        Button(action: {
                            startConversion()
                        }) {
                            HStack {
                                Image(systemName: "doc.richtext.fill")
                                Text("Convert to Markdown")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .disabled(docPath.isEmpty)
                    }
                }
                
                if !runner.resultText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Markdown Content:")
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(runner.resultText, forType: .string)
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copy Markdown")
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
                        }
                        
                        ScrollView {
                            Text(runner.resultText)
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                                .cornerRadius(6)
                        }
                        .frame(maxHeight: 180)
                    }
                }
                
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
                            Text(runner.logOutput)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                                .cornerRadius(4)
                                .id("logText")
                        }
                        .frame(maxHeight: 120)
                        .onChange(of: runner.logOutput) { _ in
                            proxy.scrollTo("logText", anchor: .bottom)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func selectFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select File to Convert"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let path = openPanel.url?.path {
                self.docPath = path
            }
        }
    }
    
    private func startConversion() {
        let targetTextFile = URL(fileURLWithPath: docPath).deletingPathExtension().path + ".md"
        runner.runScript(
            executable: "/opt/miniconda3/bin/python",
            arguments: ["/Users/hassan/local-ai/notebooks/convert_doc.py", docPath],
            targetResultFile: targetTextFile
        )
    }
}

// MARK: - Web Scraper Panel (Tab 4 - Crawl4AI)
struct ScraperView: View {
    @StateObject private var runner = ScriptRunner()
    @State private var scrapeUrl: String = ""
    @State private var outputFolder: String = "\(NSHomeDirectory())/Downloads"
    @State private var showLogs: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Web Scraper (Crawl4AI)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Scrape dynamic web page layouts directly into LLM-friendly Markdown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Website URL to Scrape")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextField("https://example.com/article", text: $scrapeUrl)
                        .textFieldStyle(.roundedBorder)
                        .disabled(runner.isRunning)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Output Folder")
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
                        .disabled(runner.isRunning)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(.thinMaterial)
                    .cornerRadius(6)
                }
                
                if runner.isRunning || runner.parsedProgress > 0 {
                    VStack(spacing: 6) {
                        ProgressView(value: runner.parsedProgress)
                        HStack {
                            Text(runner.statusMessage)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    if runner.isRunning {
                        Button(action: {
                            runner.terminate()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Stop Scraper")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .tint(.red)
                    } else {
                        Button(action: {
                            startScraping()
                        }) {
                            HStack {
                                Image(systemName: "network")
                                Text("Scrape Website")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .disabled(scrapeUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if !runner.resultText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scraped Markdown:")
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(runner.resultText, forType: .string)
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copy Content")
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
                        }
                        
                        ScrollView {
                            Text(runner.resultText)
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                                .cornerRadius(6)
                        }
                        .frame(maxHeight: 180)
                    }
                }
                
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
                            Text(runner.logOutput)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                                .cornerRadius(4)
                                .id("logText")
                        }
                        .frame(maxHeight: 120)
                        .onChange(of: runner.logOutput) { _ in
                            proxy.scrollTo("logText", anchor: .bottom)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Output Directory"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let path = openPanel.url?.path {
                self.outputFolder = path
            }
        }
    }
    
    private func startScraping() {
        // Clean URL to build a valid filename
        let filename = scrapeUrl.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .prefix(30)
        let outputFilePath = "\(outputFolder)/\(filename).md"
        
        runner.runScript(
            executable: "/opt/miniconda3/bin/python",
            arguments: ["/Users/hassan/local-ai/apps/Media Studio/crawl_site.py", scrapeUrl, outputFilePath],
            targetResultFile: outputFilePath
        )
    }
}
