import SwiftUI
import Foundation
import AppKit
import WebKit

// MARK: - App Entrypoint
@main
struct OdysseusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, maxWidth: .infinity, minHeight: 650, maxHeight: .infinity)
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
        view.material = .underWindowBackground // Liquid Glass translucency
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Embedded WebView Wrapper
struct WebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}

// MARK: - Workspace State Manager
class WorkspaceManager: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var consoleLogs: String = ""
    @Published var statusMessage: String = "Stopped"
    @Published var showWebView: Bool = false
    
    @Published var cpuUsage: String = "0.0%"
    @Published var ramUsage: String = "Free: 0 GB"
    
    private var process: Process?
    private var pipe: Pipe?
    private var statsTimer: Timer?
    
    init() {
        checkStatus()
        startStatsTimer()
    }
    
    deinit {
        statsTimer?.invalidate()
    }
    
    func checkStatus() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        process.arguments = ["ps", "-a", "--filter", "name=odysseus-app", "--format", "{{.State}}"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        DispatchQueue.main.async {
            if output.contains("running") || output.contains("up") {
                self.isRunning = true
                self.statusMessage = "Running"
                self.showWebView = true
            } else if !output.isEmpty {
                self.isRunning = false
                self.statusMessage = output.capitalized
                self.showWebView = false
            } else {
                self.isRunning = false
                self.statusMessage = "Stopped"
                self.showWebView = false
            }
        }
    }
    
    func startWorkspace() {
        DispatchQueue.main.async {
            self.statusMessage = "Deploying workspace..."
            self.consoleLogs = "Starting Odysseus Local AI Workspace launcher...\n"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            self.process = process
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["/Users/hassan/local-ai/start_workspace.sh"]
            process.currentDirectoryURL = URL(fileURLWithPath: "/Users/hassan/local-ai")
            
            // Set headless environment to prevent popping open default browser window
            var env = ProcessInfo.processInfo.environment
            env["HEADLESS"] = "1"
            process.environment = env
            
            let pipe = Pipe()
            self.pipe = pipe
            process.standardOutput = pipe
            process.standardError = pipe
            
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { [weak self] handle in
                guard let self = self else { return }
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let outputString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.consoleLogs += outputString
                        if outputString.contains("Setup complete!") || outputString.contains("Setup complete") {
                            self.isRunning = true
                            self.showWebView = true
                            self.statusMessage = "Running"
                        }
                    }
                }
            }
            
            do {
                try process.run()
                
                // Safety backup: show WebView after 10 seconds of compilation
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if !self.isRunning {
                        self.isRunning = true
                        self.showWebView = true
                        self.statusMessage = "Running (Active)"
                    }
                }
                
                process.waitUntilExit()
            } catch {
                fileHandle.readabilityHandler = nil
                DispatchQueue.main.async {
                    self.statusMessage = "Failed: \(error.localizedDescription)"
                    self.isRunning = false
                }
            }
        }
    }
    
    func stopWorkspace() {
        DispatchQueue.main.async {
            self.statusMessage = "Stopping..."
            self.showWebView = false
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
            process.arguments = ["compose", "-f", "/Users/hassan/local-ai/odysseus/docker-compose.yml", "down"]
            process.currentDirectoryURL = URL(fileURLWithPath: "/Users/hassan/local-ai/odysseus")
            
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
                        self.consoleLogs += outputString
                    }
                }
            }
            
            do {
                try process.run()
                process.waitUntilExit()
                fileHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.statusMessage = "Stopped"
                    self.consoleLogs += "\n[Workspace Stopped by User]\n"
                }
            } catch {
                fileHandle.readabilityHandler = nil
                DispatchQueue.main.async {
                    self.statusMessage = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
            self?.querySystemStats()
        }
    }
    
    private func querySystemStats() {
        // Query CPU Usage
        let cpuProcess = Process()
        cpuProcess.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        cpuProcess.arguments = ["-l", "1", "-n", "0"]
        let cpuPipe = Pipe()
        cpuProcess.standardOutput = cpuPipe
        try? cpuProcess.run()
        cpuProcess.waitUntilExit()
        
        let cpuData = cpuPipe.fileHandleForReading.readDataToEndOfFile()
        if let cpuOutput = String(data: cpuData, encoding: .utf8) {
            let lines = cpuOutput.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("CPU usage:") {
                    let parts = line.components(separatedBy: ",")
                    if !parts.isEmpty {
                        let usageStr = parts[0].replacingOccurrences(of: "CPU usage:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        DispatchQueue.main.async {
                            self.cpuUsage = usageStr
                        }
                    }
                }
            }
        }
        
        // Query Free RAM
        let memProcess = Process()
        memProcess.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")
        let memPipe = Pipe()
        memProcess.standardOutput = memPipe
        try? memProcess.run()
        memProcess.waitUntilExit()
        
        let memData = memPipe.fileHandleForReading.readDataToEndOfFile()
        if let memOutput = String(data: memData, encoding: .utf8) {
            let lines = memOutput.components(separatedBy: .newlines)
            var freePages: Double = 0
            var specPages: Double = 0
            for line in lines {
                if line.contains("Pages free:") {
                    let val = Double(line.components(separatedBy: ":")[1].replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
                    freePages = val
                } else if line.contains("Pages speculative:") {
                    let val = Double(line.components(separatedBy: ":")[1].replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
                    specPages = val
                }
            }
            let pageSize: Double = 16384 // Apple Silicon 16KB pages
            let freeRAMBytes = (freePages + specPages) * pageSize
            let freeRAMGB = freeRAMBytes / (1024 * 1024 * 1024)
            
            DispatchQueue.main.async {
                self.ramUsage = String(format: "Free: %.1f GB (of 32GB)", freeRAMGB)
            }
        }
    }
}

// MARK: - Presentation Layer (ContentView)
struct ContentView: View {
    @StateObject private var workspace = WorkspaceManager()
    @State private var showLogs = false
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title and System HUD Bar
                HStack(spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Odysseus")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Hardware gauges inside header
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "cpu")
                            Text("CPU: \(workspace.cpuUsage)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.thinMaterial)
                        .cornerRadius(6)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "memorychip")
                            Text("RAM: \(workspace.ramUsage)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.thinMaterial)
                        .cornerRadius(6)
                    }
                    
                    // Server start/stop button
                    Button(action: {
                        if workspace.isRunning {
                            workspace.stopWorkspace()
                        } else {
                            workspace.startWorkspace()
                        }
                    }) {
                        Text(workspace.isRunning ? "Stop Workspace" : "Start Workspace")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(workspace.isRunning ? .red : .blue)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.primary.opacity(0.04))
                
                Divider()
                
                // Core Web Interface Panel
                if workspace.showWebView {
                    WebView(url: URL(string: "http://localhost:7070")!)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "safari.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Odysseus Workspace is Offline")
                            .font(.headline)
                        Text("Click 'Start Workspace' to launch Docker compose search containers and Ollama APIs. Once online, the dashboard chat will render here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 420)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Logs Console Drawer
                Divider()
                Button(action: {
                    withAnimation {
                        showLogs.toggle()
                    }
                }) {
                    HStack {
                        Text(showLogs ? "Hide Setup Console Logs" : "Show Setup Console Logs")
                        Image(systemName: showLogs ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                
                if showLogs {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(workspace.consoleLogs)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                                .cornerRadius(4)
                                .id("logText")
                        }
                        .frame(maxHeight: 110)
                        .onChange(of: workspace.consoleLogs) { _ in
                            proxy.scrollTo("logText", anchor: .bottom)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }
            }
        }
    }
}
